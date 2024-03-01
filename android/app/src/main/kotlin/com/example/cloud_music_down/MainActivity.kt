package com.example.cloud_music_down

import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity () {

    private val CHANNEL = "Kotlin"

    @RequiresApi(Build.VERSION_CODES.O)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when(call.method){
                "metadataWrite"->{
                    val arguments = call.arguments as? Map<String, String>
                    val message = arguments?.let { MetadataWrite().metadataWrite(it) }
                    result.success(message)
                }
                else->result.notImplemented()
            }
        }
    }

}
