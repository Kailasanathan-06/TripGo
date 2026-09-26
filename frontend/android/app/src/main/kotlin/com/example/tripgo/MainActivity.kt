package com.example.tripgo

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Boot the in-app API on a worker thread so neither Python start-up nor the
        // first-run database migration can stall the launch of the Flutter UI. Dart
        // polls the channel below until the server reports "serving".
        thread(name = "tripgo-boot", isDaemon = true) {
            TripGoServer.start(applicationContext)
        }
    }

    override fun onDestroy() {
        // Off the main thread on purpose: closing the socket waits for the worker
        // thread, and doing that on the UI thread risks an ANR on every teardown.
        thread(name = "tripgo-stop", isDaemon = true) {
            TripGoServer.stop()
        }
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TripGoServer.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(TripGoServer.status())
                    else -> result.notImplemented()
                }
            }
    }
}
