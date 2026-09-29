package com.example.tripgo

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * Plain Flutter host activity.
 *
 * The embedded Python/Django server has been removed. The app now connects to
 * an external Django API server over HTTP/HTTPS. No MethodChannel or Chaquopy
 * setup is needed here.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
