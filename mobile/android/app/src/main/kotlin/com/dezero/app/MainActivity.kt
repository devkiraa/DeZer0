package com.dezero.app

import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dezero.hotspot/hotspot"
    private var wifiManager: WifiManager? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHotspot" -> {
                    val ssid = call.argument<String>("ssid") ?: "DeZer0"
                    val password = call.argument<String>("password") ?: "dev0whostpot"
                    startHotspot(ssid, password, result)
                }
                "stopHotspot" -> {
                    stopHotspot(result)
                }
                "getConnectedDevices" -> {
                    getConnectedDevices(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startHotspot(ssid: String, password: String, result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // For Android 8.0+, we need to open system settings
                // Direct hotspot control is restricted
                val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
                result.success(false) // Return false to indicate manual setup needed
            } else {
                // For older versions, we can't reliably control hotspot either
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("HOTSPOT_ERROR", "Failed to start hotspot: ${e.message}", null)
        }
    }

    private fun stopHotspot(result: MethodChannel.Result) {
        try {
            // Similar restrictions apply for stopping
            result.success(true)
        } catch (e: Exception) {
            result.error("HOTSPOT_ERROR", "Failed to stop hotspot: ${e.message}", null)
        }
    }

    private fun getConnectedDevices(result: MethodChannel.Result) {
        try {
            val devices = mutableListOf<Map<String, String>>()
            
            // Try to read ARP table to find connected devices
            try {
                val process = Runtime.getRuntime().exec("cat /proc/net/arp")
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                var line: String?
                
                // Skip header
                reader.readLine()
                
                while (reader.readLine().also { line = it } != null) {
                    val parts = line!!.split("\\s+".toRegex())
                    if (parts.size >= 6) {
                        val ip = parts[0]
                        val mac = parts[3]
                        val flags = parts[2]
                        
                        // 0x2 means the entry is valid
                        if (flags == "0x2" && mac != "00:00:00:00:00:00") {
                            // Check if it's likely an ESP32 based on MAC address
                            val isESP32 = mac.startsWith("30:ae:a4", ignoreCase = true) ||
                                         mac.startsWith("24:0a:c4", ignoreCase = true) ||
                                         mac.startsWith("a4:cf:12", ignoreCase = true) ||
                                         mac.startsWith("7c:df:a1", ignoreCase = true) ||
                                         mac.startsWith("84:cc:a8", ignoreCase = true)
                            
                            val deviceName = if (isESP32) "ESP32-DeZer0" else "Device-${ip.split(".").last()}"
                            
                            devices.add(mapOf(
                                "name" to deviceName,
                                "ip" to ip,
                                "mac" to mac
                            ))
                        }
                    }
                }
                reader.close()
            } catch (e: Exception) {
                println("Error reading ARP table: ${e.message}")
            }
            
            result.success(devices)
        } catch (e: Exception) {
            result.error("DEVICE_ERROR", "Failed to get connected devices: ${e.message}", null)
        }
    }
}
