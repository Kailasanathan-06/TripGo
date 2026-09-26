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
 */
object TripGoServer {

    private const val TAG = "TripGoServer"
    const val CHANNEL = "com.example.tripgo/server"

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
        try {
            if (!Python.isStarted()) {
                Log.i(TAG, "Starting embedded Python interpreter")
                Python.start(AndroidPlatform(app))
            }
            phase = "warming"
            detail = "Starting in-app server"
            port = withModule { it.callAttr("prepare").use { bound -> bound.toInt() } }
            Log.i(TAG, "TripGo API socket bound on 127.0.0.1:$port")
        } catch (t: Throwable) {
            phase = "error"
            detail = t.stackTraceToString()
            Log.e(TAG, "Could not start the TripGo in-app server", t)
        }
    }

    /** Closes the loopback socket. The worker thread dies with the process anyway. */
    fun stop() {
        try {
            if (Python.isStarted()) {
                withModule { it.callAttr("stop").close() }
                Log.i(TAG, "TripGo API socket closed")
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
            withModule { module ->
                module.callAttr("status").use { state ->
                    // PyObject is a Map<String, PyObject>, so the Python dict is
                    // read with the plain subscript operator.
                    state["phase"]?.toString()?.let { result["phase"] = it }
                    state["detail"]?.toString()?.let { result["detail"] = it }
                }
            }
            result
        } catch (t: Throwable) {
            Log.w(TAG, "Could not read the in-app server status", t)
            result
        }
    }

    private inline fun <T> withModule(block: (PyObject) -> T): T =
        Python.getInstance().getModule("tripgo_server").use(block)
}
