package com.example.tripgo

import android.content.Context
import android.util.Log
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

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
 */
object TripGoServer {

    private const val TAG = "TripGoServer"
    const val CHANNEL = "com.example.tripgo/server"

    private val pythonLock = Any()

    /**
     * The module handle is cached and deliberately never closed: Chaquopy
     * invalidates *every* handle to a Python object when one of them is closed, so
     * re-fetching and closing per call is what makes a cached reference dangle.
     */
    private var module: PyObject? = null
    private var pythonStarted = false

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
        phase = "warming"
        detail = "Starting in-app server"
        try {
            val bound = synchronized(pythonLock) {
                ensurePython(app)
                phase = "warming"
                detail = "Starting in-app server"
                module()!!.callAttr("prepare").use { it.toInt() }
            }
            port = bound
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
            synchronized(pythonLock) {
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

        return try {
            synchronized(pythonLock) {
                module()?.callAttr("status")?.use { state ->
                    // PyObject is a Map<String, PyObject>, so the Python dict is read
                    // with the plain subscript operator.
                    state["phase"]?.use { value -> result["phase"] = value.toString() }
                    state["detail"]?.use { value -> result["detail"] = value.toString() }
                }
            }
            result
        } catch (t: Throwable) {
            Log.w(TAG, "Could not read the in-app server status", t)
            result
        }
    }

    private fun ensurePython(app: Context) {
        if (pythonStarted) return
        // Claim the one-shot slot before doing anything: getInstance() quietly starts
        // Python with a GenericPlatform if start() has not run yet, and start() itself
        // may only ever be called once. Losing that race means the wrong platform and
        // a dead interpreter.
        pythonStarted = true
        if (!Python.isStarted()) {
            Log.i(TAG, "Starting embedded Python interpreter")
            Python.start(AndroidPlatform(app))
        }
    }

    private fun module(): PyObject? {
        module?.let { return it }
        val resolved = Python.getInstance().getModule("tripgo_server")
        module = resolved
        return resolved
    }
}
