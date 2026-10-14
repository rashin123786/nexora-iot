package com.example.nexora_iot

import android.content.Context
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.nexora.iot/device"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryManager =
                        getSystemService(Context.BATTERY_SERVICE)
                                as BatteryManager

                    val level = batteryManager.getIntProperty(
                        BatteryManager.BATTERY_PROPERTY_CAPACITY
                    )

                    if (level >= 0) {
                        result.success(level)
                    } else {
                        result.error(
                            "UNAVAILABLE",
                            "Battery level unavailable",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}