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
import java.util.TimeZone
import java.util.Locale
import java.util.Date
import android.content.pm.ApplicationInfo

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

    /*********************************************
    * Name: getMidnight
    * 
    * Description: Returns a long of midnight for the
    *              given Calendar instance
    **********************************************/
    private fun getMidnight(curDate: Calendar): Long {
        val today = curDate
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)
        return today.time.time
    }

    private fun getScreenTimeStats(): Map<String, Map<String, String>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
        //Bridget: Changed data range to go from midnight today to midnight tonight
        val calendar = Calendar.getInstance()
        val startTime = getMidnight(calendar)
        calendar.add(Calendar.DAY_OF_YEAR, 1)
        val endTime = getMidnight(calendar)
    
        val queryUsageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
    
        val screenTimeMap = mutableMapOf<String, MutableMap<String, String>>()
    
        for (stats in queryUsageStats) {
            if (stats.totalTimeInForeground <= 0) {
                continue
            }
    
            try {
                val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                screenTimeMap[appName] = mutableMapOf<String, String>()
                screenTimeMap[appName]!!.put("hours", "%.2f".format(stats.totalTimeInForeground / 3600000.0).toString())
                screenTimeMap[appName]!!.put("category", ApplicationInfo.getCategoryTitle(this, appInfo.category).toString())
                
            } catch (e: Exception) {
                Log.e("MainActivity", "Error getting app info for ${stats.packageName}", e)
                continue
            }
        }
    
        return screenTimeMap
    }
}