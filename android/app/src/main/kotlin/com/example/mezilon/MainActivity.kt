package com.example.mezilon

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.matzilon.mezilon/sms_compose",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "composeSms" -> {
                    val number = call.argument<String>("number")
                    val body = call.argument<String>("body")

                    if (number.isNullOrBlank() || body == null) {
                        result.success(false)
                    } else {
                        val smsIntent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.fromParts("smsto", number, null)
                            putExtra("sms_body", body)
                        }

                        if (smsIntent.resolveActivity(packageManager) == null) {
                            result.success(false)
                        } else {
                            try {
                                startActivity(smsIntent)
                                result.success(true)
                            } catch (_: ActivityNotFoundException) {
                                result.success(false)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
