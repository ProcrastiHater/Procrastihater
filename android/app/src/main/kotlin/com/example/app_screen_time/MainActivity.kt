package com.example.app_screen_time

import android.Manifest
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.content.Context
//Screen time usage import
import android.app.usage.UsageStatsManager
//Permissions Settings imports
import android.provider.Settings
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Intent
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
//Used for time calculations
import java.util.Calendar
import java.util.TimeZone
import java.util.Locale
import java.util.Date
//Allows access to category titles
import android.content.pm.ApplicationInfo
//Notification imports
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.content.pm.PackageManager
import android.app.NotificationChannel
//Background service imports
import androidx.work.*
import com.example.app_screen_time.TestNotifWorker
import java.util.concurrent.TimeUnit

///*********************************************
/// Name: MainActivity
///
/// Description: Class for managing method channels
/// and doing other kotlin code
///**********************************************
class MainActivity: FlutterActivity() {
    private val CHANNEL = "kotlin.methods/screentime"
    private lateinit var channel: MethodChannel

    ///**********************************************
    /// Name: onCreate
    ///
    /// Description: Initializes activity
    ///**********************************************
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        //Purge old instances of notifications
        WorkManager.getInstance().cancelAllWork()
        if(checkNotificationsPermission()) {
            createNotificationChannel()
            startTestNotifs()
        } else {
            openNotificationSettings()
        }
    }

    ///**********************************************
    /// Name: configureFlutterEngine
    ///
    /// Description: Allows use of Method Channels
    ///**********************************************
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        channel.setMethodCallHandler { call, result ->
            try {
                Log.d("MainActivity", "Method called: ${call.method}")
                
                //Kotlin equivalent of switch statement for which method channel we wish to use
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
                    "requestScreenTimePermission" -> {
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

    ///**********************************************
    /// Name: checkUsageStatsPermission
    ///
    /// Description: Checks to see if the user has granted
    /// permission for accessing screentime data
    ///**********************************************
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

    ///**********************************************
    /// Name: openUsageAccessSettings
    /// 
    /// Description: Opens the permissions page for accessing
    /// screentime data
    ///**********************************************
    private fun openUsageAccessSettings() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    ///**********************************************
    /// Name: checkNotificationsPermission
    ///
    /// Description: Checks to see if the user has granted
    /// permission for receiving notifications
    ///**********************************************
    private fun checkNotificationsPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    ///**********************************************
    /// Name: openUsageAccessSettings
    /// 
    /// Description: Opens the permissions dialog for
    /// receiving notifications
    ///**********************************************
    private fun openNotificationSettings(){
        //Params: context, array of permissions, 
        // request code (>= 0, but otherwise can be anything)
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            123
        )
    }

    ///**********************************************
    /// Name: createNotificationChannel
    /// 
    /// Description: Creates notification channel,
    /// which is required by Android for notifications
    /// to be visible
    ///**********************************************
    private fun createNotificationChannel() {
        if (VERSION.SDK_INT >= VERSION_CODES.O) {
            val name = "ProcrastiNotif"
            val descriptionText = "ProcrastiHater Notifications"
            //Set importance of notification
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            //Create notification channel, which is required by current Android versions
            val channel = NotificationChannel("ProcrastiNotif", name, importance)
            //Set the description of the notification channel
            channel.setDescription(descriptionText)
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            //Register notification channel
            notificationManager.createNotificationChannel(channel)
        }
    }

    ///**********************************************
    /// Name: startTestNotifs
    /// 
    /// Description: Starts background task for
    /// sending test notification
    ///**********************************************
    fun startTestNotifs() {
        //Give bg work requirements for working
        // In this case, make it require internet connection
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
        //Create bg work request
        val notifRequest: PeriodicWorkRequest = PeriodicWorkRequestBuilder<TestNotifWorker>(
            15, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .build()
        //Put work into queue
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "testNotification",
            ExistingPeriodicWorkPolicy.REPLACE,
            notifRequest,
        )
    }

    ///**********************************************
    /// Name: getMidnight
    /// 
    /// Description: Returns a long of midnight for the
    /// given Calendar instance
    ///**********************************************
    private fun getMidnight(curDate: Calendar): Long {
        val today = curDate
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)
        return today.time.time
    }

    ///***********************************************
    /// Name: getScreenTimeStats
    /// 
    /// Description: Returns a Map that uses app names as keys
    /// and inner Maps as values. The inner Maps use
    /// data labels such as "hours" and "category" as keys
    /// and the values obtained for those from the screentime
    /// data as values
    ///***********************************************
    private fun getScreenTimeStats(): Map<String, Map<String, String>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
        //Sets the time range for data to be from midnight this morning to midnight tonight
        val calendar = Calendar.getInstance()
        val startTime = getMidnight(calendar)
        calendar.add(Calendar.DAY_OF_YEAR, 1)
        val endTime = getMidnight(calendar)
    
        //Grabs the usage stats using the stats manager
        val queryUsageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        //Create a map for transferring screen time to dart/flutter code
        val screenTimeMap = mutableMapOf<String, MutableMap<String, String>>()
    
        for (stats in queryUsageStats) {
            //Filter out apps with less than 0.05 hrs
            if (stats.totalTimeInForeground / 3600000.0 < 0.05) {
                continue
            }
    
            try {
                val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                //Add apps' names as keys for the outer map
                screenTimeMap[appName] = mutableMapOf<String, String>()
                //Add hours and category as key-value pairs for the inner map
                screenTimeMap[appName]!!.put("hours", "%.2f".format(stats.totalTimeInForeground / 3600000.0).toString())
                if(appInfo.category != -1) {
                    screenTimeMap[appName]!!.put("category", ApplicationInfo.getCategoryTitle(this, appInfo.category).toString())
                }else {
                    screenTimeMap[appName]!!.put("category", "Other")
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error getting app info for ${stats.packageName}", e)
                continue
            }
        }
    
        return screenTimeMap
    }
}