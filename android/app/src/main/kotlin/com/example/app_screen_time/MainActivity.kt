package com.example.app_screen_time

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.app.usage.UsageStatsManager
import android.provider.Settings
import android.app.AppOpsManager
import android.content.Intent
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "kotlin.methods/screentime"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            try {
                Log.d("MainActivity", "Method called: ${call.method}")
                
                when (call.method) {
                    "getScreenTime" -> {
                        if (checkUsageStatsPermission()) {
                            val screenTimeData = getScreenTimeStats()
                            Log.d("MainActivity", "Screen time data: $screenTimeData")
                            result.success(screenTimeData)
                        } else {
                            openUsageAccessSettings()
                            result.error("PERMISSION_DENIED", "Usage access permission required", null)
                        }
                    }
                    "checkPermission" -> {
                        val hasPermission = checkUsageStatsPermission()
                        Log.d("MainActivity", "Permission check result: $hasPermission")
                        result.success(hasPermission)
                    }
                    "requestPermission" -> {
                        openUsageAccessSettings()
                        result.success(true)
                    }
                    else -> {
                        Log.e("MainActivity", "Method not implemented: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error in method call: ${e.message}", e)
                result.error("INTERNAL_ERROR", e.message, e.stackTraceToString())
            }
        }
    }

    private fun checkUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (VERSION.SDK_INT >= VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun getScreenTimeStats(): Map<String, Double> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        val startTime = calendar.timeInMillis
    
        val queryUsageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
    
        val screenTimeMap = mutableMapOf<String, Double>()
    
        for (stats in queryUsageStats) {
            if (stats.totalTimeInForeground <= 0) {
                continue
            }
    
            try {
                val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val hoursUsed = "%.2f".format(stats.totalTimeInForeground / 3600000.0).toDouble() 
                screenTimeMap[appName] = hoursUsed
                
            } catch (e: Exception) {
                Log.e("MainActivity", "Error getting app info for ${stats.packageName}", e)
                continue
            }
        }
    
        return screenTimeMap
    }
}