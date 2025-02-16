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
import java.util.concurrent.TimeUnit
//Allows access to category titles
import android.content.pm.ApplicationInfo
//Notification stuff
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.content.pm.PackageManager
import android.app.NotificationChannel
//Firebase imports
// import com.google.firebase.auth.auth
// import com.google.firebase.firestore.firestore
// import com.google.firebase.firestore.toObject
// import com.google.firebase.Firebase
//Background service stuff
import androidx.work.*
import com.example.app_screen_time.TotalSTNotifWorker

class MainActivity: FlutterActivity() {
    private val CHANNEL = "kotlin.methods/screentime"
    private lateinit var channel: MethodChannel
    // private val FIRESTORE = FirebaseFirestore.getInstance()
    // private var AUTH: FirebaseAuth = Firebase.auth
    // private val MAIN_COLLECTION = FIRESTORE.collection("UID")
    // private String uid = AUTH.currentUser?.getUid()
    // private DocumentReference userRef = MAIN_COLLECTION.doc(uid)

    ///*********************************************
    /// Name: onCreate
    ///
    /// Description: Initializes activity
    ///**********************************************
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WorkManager.getInstance().cancelAllWork()
        createNotificationChannel()
        if(checkNotificationsPermission()) {
            notifWork()
        }else{
            openNotificationSettings()
        }
    }

    ///*********************************************
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

    ///*********************************************
    /// Name: writeScreenTimeData
    ///
    /// Description: Takes the data
    /// that was accessed in _getScreenTime
    /// and writes it to the Firestore database
    /// using batches for multiple writes
    ///**********************************************
    // private fun writeScreenTimeData(){
    //     updateUserRef()
    //     val userData = getScreenTimeStats()
    //     if(!userData.isEmpty()){
    //         val current = userRef.collection("appUsageCurrent")
    //         FIRESTORE.runBatch{batch->
    //             try {
    //                 val currentSnap = current.get()
    //             }catch (e: Exception) {
    //                 Log.e("MainActivity", "Error writing screen time data to Firestore: ", e)
    //                 continue
    //             }
    //         }
    //     }
    // }

    ///**************************************************
    /// Name: updateUserRef
    ///
    /// Description: Updates userRef to doc if the UID has changed
    ///***************************************************
    // private fun updateUserRef(){
    //     val curUid = uid
    //     uid = AUTH.currentUser?.getUid()
    //     if(curUid != uid) {
    //         userRef = MAIN_COLLECTION.doc(uid)
    //     }
    // }

    ///*********************************************
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

    ///*********************************************
    /// Name: openUsageAccessSettings
    /// 
    /// Description: Opens the permissions page for accessing
    /// screentime data
    ///**********************************************
    private fun openUsageAccessSettings() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun checkNotificationsPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun openNotificationSettings(){
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            101
        )
    }

    private fun createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is not in the Support Library.
        if (VERSION.SDK_INT >= VERSION_CODES.O) {
            val name = "ProcrastiNotif"
            val descriptionText = "ProcrastiHater Notifications"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel("ProcrastiNotif", name, importance)
            channel.setDescription(descriptionText)
            // Register the channel with the system.
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun notifWork() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
        val notifRequest: PeriodicWorkRequest = PeriodicWorkRequestBuilder<TotalSTNotifWorker>(
            15, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "testNotification",
            ExistingPeriodicWorkPolicy.REPLACE,
            notifRequest,
        )
    }

    ///*********************************************
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

    ///*********************************************
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