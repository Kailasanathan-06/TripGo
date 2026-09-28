package com.example.tripgo

import android.content.Context
import android.os.SystemClock
import android.util.Log
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/**
 * Owns the Django backend that is embedded in this APK via Chaquopy.
 *
 * CPython runs inside the app process, so the API comes up with the app and goes
 * down with it. Nothing has to be spawned, supervised or torn down separately: when
 * the user leaves the app the OS reclaims the process and the loopback socket with
 * it. The only lifecycle work here is starting the interpreter once per process and
 * exposing the bind state to Dart.
 *
 * Every call into Python goes through [pythonLock]. The boot thread and the
 * MethodChannel handler run on different threads, and Chaquopy's Java API is not
 * re-entrant across them, so interleaving calls is what produces "PyObject is
 * closed" style failures. [prepare] only binds a socket and returns immediately, so
 * holding the lock never means holding it for the length of a Django import.
 *
 * [status] is the exception: it runs on the Android platform thread and must never
 * wait. Python.start() takes seconds on a cold start, and blocking the platform
 * thread there stops the MethodChannel from answering at all, which is what made
 * the splash give up with "Timed out while starting the TripGo server". It takes
 * the lock opportunistically and otherwise reports the last known state.
 *
 * Answering "warming" on every path is what turned a crash into a silent 150 second
 * loop: a failed read used to fall through and report the cached "warming" phase, so
 * a dead interpreter was indistinguishable from a slow boot. A read that throws is
 * now reported as an error with its real cause, and a boot that stays stuck in
 * "warming" past [STALL_AFTER_MS] is reported as a stall, both of which the splash
 * can show instead of spinning.
 */
object TripGoServer {

    private const val TAG = "TripGoServer"
    const val CHANNEL = "com.example.tripgo/server"

    /**
     * How long the Python side may report the same progress line before it is
     * treated as stuck.
     *
     * This is deliberately a limit on *silence*, not on total boot time. A cold
     * first launch has to extract ~28 MB of Python from the APK, which on a slow
     * phone legitimately takes a minute, and an earlier version of this check
     * compared total elapsed time instead. That reported a stall on a start that
     * was still working and would have finished.
     */
    private const val STALL_AFTER_MS = 45_000L
    private const val MAX_BOOT_TIME_MS = 180_000L

    private val pythonLock = ReentrantLock()

    /**
     * The module handle is cached and deliberately never closed: Chaquopy
     * invalidates *every* handle to a Python object when one of them is closed, so
     * re-fetching and closing per call is what makes a cached reference dangle.
     */
    private var module: PyObject? = null
    private var pythonStarted = false

    /**
     * Set once [prepare] has returned, which proves the interpreter is usable and
     * the socket is bound. Before that, a slow boot is expected; after it, staying
     * in "warming" means the warm-up itself is stuck.
     */
    @Volatile
    private var socketBoundAt: Long = 0L

    /**
     * The last progress line seen from Python, and when it was seen. The stall check
     * compares against this rather than against [socketBoundAt], so a start that keeps
     * reporting forward progress is never reported as stuck no matter how long the
     * device takes.
     */
    @Volatile
    private var lastProgress = ""

    @Volatile
    private var lastProgressAt: Long = 0L

    @Volatile
    var phase: String = "idle"
        private set

    @Volatile
    var port: Int = 0
        private set

    @Volatile
    var detail: String = ""
        private set

    /**
     * Starts Python and binds the API socket, then warms the database on a worker
     * thread. Safe to call more than once; later calls are ignored while a boot is
     * already in flight.
     */
    fun start(context: Context) {
        if (phase == "warming" || phase == "serving") return

        val app = context.applicationContext
        socketBoundAt = 0L
        lastProgress = ""
        lastProgressAt = 0L
        phase = "warming"
        detail = "Starting the TripGo server"
        try {
            val bound = pythonLock.withLock {
                ensurePython(app)
                phase = "warming"
                detail = "Starting in-app server"
                module()!!.callAttr("prepare").use { it.toInt() }
            }
            port = bound
            socketBoundAt = SystemClock.elapsedRealtime()
            Log.i(TAG, "TripGo API socket bound on 127.0.0.1:$bound")
        } catch (t: Throwable) {
            phase = "error"
            detail = t.stackTraceToString()
            Log.e(TAG, "Could not start the TripGo in-app server", t)
        }
    }

    /**
     * Closes the loopback socket. The worker thread dies with the process anyway.
     *
     * Must not run on the main thread: the Python side waits for the worker to finish
     * so the socket is really gone before anyone rebinds, and that wait can take a
     * moment. Blocking the UI thread here risks an ANR on every activity teardown.
     */
    fun stop() {
        try {
            pythonLock.withLock {
                if (pythonStarted && Python.isStarted()) {
                    module()?.callAttr("stop")?.close()
                    Log.i(TAG, "TripGo API socket closed")
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "Ignoring failure while closing the TripGo API socket", t)
        } finally {
            phase = "stopped"
            port = 0
            detail = ""
        }
    }

    fun status(): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>("phase" to phase, "port" to port, "detail" to detail)
        if (phase != "warming" && phase != "serving") return result

        // The interpreter may still be starting, or another thread may hold the lock.
        // Either way this is called from the platform thread, so answer immediately
        // with the last known state rather than stalling the channel.
        if (!pythonLock.tryLock()) {
            reportStall(result, "the Python runtime is busy and never finished starting")
            return result
        }

        return try {
            module()?.callAttr("status")?.use { state ->
                // PyObject is a Map<String, PyObject>, so the Python dict is read with
                // the plain subscript operator.
                state["phase"]?.use { value -> result["phase"] = value.toString() }
                state["detail"]?.use { value ->
                    val reported = value.toString()
                    result["detail"] = reported
                    // Any new line means the boot is still making progress.
                    if (reported != lastProgress) {
                        lastProgress = reported
                        lastProgressAt = SystemClock.elapsedRealtime()
                    }
                }
            }
            phase = result["phase"] as? String ?: phase
            detail = result["detail"] as? String ?: detail
            if (result["phase"] == "warming") {
                reportStall(result, "no progress reported by the in-app server")
            }
            result
        } catch (t: Throwable) {
            // Reporting the cached "warming" phase here is what turned a dead
            // interpreter into a silent 150 second loop on the splash, so the real
            // cause is surfaced instead of being swallowed.
            Log.e(TAG, "Could not read the in-app server status", t)
            result["phase"] = "error"
            result["detail"] = "The in-app server could not be reached: ${t.stackTraceToString()}"
            result
        } finally {
            pythonLock.unlock()
        }
    }

    /**
     * Turns a boot that has stopped reporting progress into a visible error.
     *
     * Only applies once the socket is bound, because a long `Python.start()` is a
     * normal cold start rather than a stall, and the timer is reset by every new
     * progress line so a slow device is given as long as it needs while it works.
     */
    private fun reportStall(result: MutableMap<String, Any?>, why: String) {
        if (socketBoundAt == 0L) return
        val now = SystemClock.elapsedRealtime()
        if (lastProgressAt == 0L) {
            lastProgressAt = socketBoundAt
            return
        }
        val silentFor = now - lastProgressAt
        val total = now - socketBoundAt
        val timedOut = total >= MAX_BOOT_TIME_MS
        if (!timedOut && silentFor < STALL_AFTER_MS) return
        val reason = if (timedOut) "startup exceeded ${MAX_BOOT_TIME_MS / 1000}s" else why
        Log.e(TAG, "In-app server silent for ${silentFor}ms of a ${total}ms boot ($reason)")
        result["phase"] = "error"
        result["detail"] = "The in-app server stopped responding after " +
            "${total / 1000}s. It last reported: ${result["detail"]}. ($reason)"
        phase = "error"
        detail = result["detail"] as String
    }

    private fun ensurePython(app: Context) {
        if (pythonStarted) return
        if (!Python.isStarted()) {
            Log.i(TAG, "Starting embedded Python interpreter")
            Python.start(AndroidPlatform(app))
        }
        check(Python.isStarted()) { "Chaquopy returned without starting Python" }
        pythonStarted = true
    }

    private fun module(): PyObject? {
        module?.let { return it }
        val resolved = Python.getInstance().getModule("tripgo_server")
        module = resolved
        return resolved
    }
}
