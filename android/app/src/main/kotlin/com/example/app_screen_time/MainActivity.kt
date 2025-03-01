package com.example.app_screen_time

import kotlin.Double
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
import java.time.LocalDate
import java.text.SimpleDateFormat
import java.time.temporal.TemporalAdjusters
import java.time.format.DateTimeFormatter
import java.time.ZoneId
import java.time.DayOfWeek
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
import com.example.app_screen_time.TotalSTWorker
import com.example.app_screen_time.BGWritesWorker
import java.util.concurrent.TimeUnit
import kotlin.random.Random
//Firebase imports
import com.google.firebase.*
import com.google.firebase.firestore.*
import com.google.firebase.auth.*
import com.google.android.gms.tasks.Task

public var screenTimeMap = mutableMapOf<String, MutableMap<String, String>>();

lateinit var firestore: FirebaseFirestore
lateinit var auth: FirebaseAuth
lateinit var mainCollection: CollectionReference
lateinit var uid: String
lateinit var userRef: DocumentReference

///*********************************************
/// Name: MainActivity
///
/// Description: Class for managing method channels
/// and doing other kotlin code
///**********************************************
class MainActivity: FlutterActivity() {
    private val CHANNEL = "kotlin.methods/procrastihater"
    private lateinit var channel: MethodChannel

    ///**********************************************
    /// Name: onCreate
    ///
    /// Description: Initializes activity
    ///**********************************************
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        firestore = Firebase.firestore
        auth = Firebase.auth
        mainCollection = firestore.collection("UID")
        uid = auth.currentUser!!.getUid()
        userRef = mainCollection.document(uid)

        //Purge old instances of notifications
        WorkManager.getInstance().cancelAllWork()
        //WorkManager.getInstance().cancelUniqueWork("totalSTNotification")
        createNotificationChannel()
        if(!checkNotificationsPermission())
        {
            openNotificationSettings()
        }
        //startBGWrites()
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
                            updateUserRef()
                            Log.d("MainActivity", "Screen time data: $screenTimeData")
                            result.success(screenTimeData)
                        } else {
                            openUsageAccessSettings()
                            result.error("PERMISSION_DENIED", "Usage access permission required", null)
                        }
                    }
                    "checkScreenTimePermission" -> {
                        val hasPermission = checkUsageStatsPermission()
                        Log.d("MainActivity", "Usage Stats Permission check result: $hasPermission")
                        result.success(hasPermission)
                    }
                    "requestScreenTimePermission" -> {
                        openUsageAccessSettings()
                        result.success(true)
                    }
                    "checkNotificationsPermission" -> {
                        val hasPermission = checkNotificationsPermission()
                        Log.d("Main Activity", "Notifications Permission check result: $hasPermission")
                        result.success(hasPermission)
                    }
                    "requestNotificationsPermission" -> {
                        openNotificationSettings()
                        result.success(true)
                    }
                    "startTestNotifications" -> {
                        startTestNotifs()
                        result.success(true)
                    }
                    "startTotalSTNotifications" -> {
                        startTotalSTNotifs()
                        Log.d("MainActivity", "Started Screen Time Notifications")
                        result.success(true)
                    }
                    "cancelTotalSTNotifications" -> {
                        WorkManager.getInstance(this).cancelUniqueWork("totalSTNotification")
                        Log.d("MainActivity", "Canceled Screen Time Notifications")
                        result.success(true)
                    }
                    "curToHist" ->{
                        currentToHistorical()
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
        return checkSelfPermission(
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
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            Random.nextInt(0, 20000)
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
        // val constraints = Constraints.Builder()
        //     .setRequiredNetworkType(NetworkType.CONNECTED)
        //     .build()
        //Create bg work request
        val notifRequest: PeriodicWorkRequest = PeriodicWorkRequestBuilder<TestNotifWorker>(
            15, TimeUnit.MINUTES
        )
            .build()
        //Put work into queue
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "testNotification",
            ExistingPeriodicWorkPolicy.REPLACE,
            notifRequest,
        )
    }

    ///**********************************************
    /// Name: startTotalSTNotifs
    /// 
    /// Description: Starts background task for
    /// sending totalSTNotifications
    ///**********************************************
    fun startTotalSTNotifs() {
        //Create bg work request
        val notifRequest: PeriodicWorkRequest = PeriodicWorkRequestBuilder<TotalSTWorker>(
            15, TimeUnit.MINUTES
        )
            .build()
        //Put work into queue
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "totalSTNotification",
            ExistingPeriodicWorkPolicy.REPLACE,
            notifRequest,
        )
    }

    ///**********************************************
    /// Name: startBGWrites
    /// 
    /// Description: Starts background task for
    /// writing to DB
    ///**********************************************
    fun startBGWrites() {
        // Give bg work requirements for working
        // In this case, make it require internet connection
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        //Create bg work request
        val notifRequest: PeriodicWorkRequest = PeriodicWorkRequestBuilder<BGWritesWorker>(
            60, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setInitialDelay(3, TimeUnit.MINUTES)
            .build()

        //Put work into queue
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "BackgroundWrites",
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

///**************************************************
/// Name: updateUserRef
///
/// Description: Updates userRef to doc if the UID has changed
///***************************************************
fun updateUserRef(){
    var curUid = uid
    uid = auth.currentUser!!.getUid()
    if(curUid != uid){
        userRef = mainCollection.document(uid);
        Log.d("Kotlin", "UID updated");
    }else{
        Log.d("Kotlin", "UID did not change");
    }
}

///*******************************************************
/// Name: currentToHistorical
///
/// Description: Moves data from the current collection to
/// history in Firestore
///********************************************************
private fun currentToHistorical() {
    updateUserRef()

    var fetchedData = mutableMapOf<String, MutableMap<String, Any>>()

    val currentTime = Timestamp
        .now()
        .toDate()
        .toInstant()
        .atZone(ZoneId.of("PST"))
        .toLocalDate()
    var needToMoveData : Boolean = false
    //Grab data from current
    try{
        val current = userRef.collection("appUsageCurrent");
        val currentSnap = current
            .get()
            .addOnSuccessListener{ result ->
                //Loop to access all current screentime data from user
                for(doc in result.getDocuments())
                {
                    val docName : String = doc.getId()
                    val hours : Double? = doc.getDouble("dailyHours")
                    val timestamp : Timestamp? = doc.getTimestamp("lastUpdated")
                    val category : String? = doc.getString("appType")
                    fetchedData[docName] = mutableMapOf<String, Any>()
                    if(hours != null && timestamp != null && category != null){
                        fetchedData[docName]!!.put("dailyHours", hours)
                        fetchedData[docName]!!.put("lastUpdated", timestamp)
                        fetchedData[docName]!!.put("appType", category)
                    }
                    val dateUpdated = timestamp!!
                        .toDate()
                        .toInstant()
                        .atZone(ZoneId.of("PST"))
                        .toLocalDate()
                    //Check if any data needs to be written to history
                    if (dateUpdated.dayOfMonth != currentTime.dayOfMonth
                        || dateUpdated.monthValue != currentTime.monthValue
                        || dateUpdated.year != currentTime.year) {
                        needToMoveData = true;
                    }
                }
                //If any data needs to be written to history
                if(needToMoveData) {
                    //Create batch
                    val batch = firestore.batch()
                    var totalDaily : Double = 0.0
                    var totalWeekly : Double = 0.0
                    var histTask : Task<DocumentSnapshot>? = null
                    var histSnapshot : DocumentSnapshot? = null
                    val sdf = SimpleDateFormat("EEEE") //SimpleDateFormat
                    val dtf = DateTimeFormatter.ofPattern("MM-dd-yyyy") //DateTimeFormatter
                    try{
                        //Iterate through each app and its screen time
                        for(appMap in fetchedData.entries.iterator()) {
                            val screenTimeHours: Double = appMap.component2()["dailyHours"] as Double
                            val timestamp: Timestamp = appMap.component2()["lastUpdated"] as Timestamp
                            val category: String = appMap.component2()["appType"] as String
                            val dateUpdated = timestamp!!
                                .toDate()
                                .toInstant()
                                .atZone(ZoneId.of("PST"))
                                .toLocalDate()
                            if (dateUpdated.dayOfMonth != currentTime.dayOfMonth
                                || dateUpdated.monthValue != currentTime.monthValue
                                || dateUpdated.year != currentTime.year ) {
                                //Get name of the day of the week for the last update day
                                val timestmp = timestamp.toDate()
                                val dayOfWeekStr = sdf.format(timestmp)
                                //Get LocalDate for that Monday
                                val startOfWeek = dateUpdated.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                                //Get str of date for that Monday
                                val startOfWeekStr = startOfWeek.format(dtf)
                                val historical = userRef.collection("appUsageHistory").document(startOfWeekStr)
                                if(histTask == null) {
                                    histTask = historical
                                        .get()
                                        .addOnSuccessListener{ result2 ->
                                            if(totalWeekly == 0.0 && result2.contains("totalWeeklyHours"))
                                            {
                                                val weekly = result2.getDouble("totalWeeklyHours")
                                                if(weekly != null)
                                                {
                                                    totalWeekly += weekly
                                                }
                                            }
                                            histSnapshot = result2
                                        }
                                        .addOnFailureListener{
                                            Log.e("BGWritesWorker", "Error getting week in history")
                                        }
                                }
                                totalDaily += screenTimeHours
                                totalWeekly += screenTimeHours
                                batch.set(
                                    historical,
                                    hashMapOf(
                                        dayOfWeekStr to hashMapOf(
                                            appMap.component1() to hashMapOf(
                                                "hours" to screenTimeHours,
                                                "lastUpdated" to timestamp,
                                                "appType" to category
                                            ),
                                            "totalDailyHours" to Math.round(totalDaily * 100.0) / 100.0
                                        ),
                                        "totalWeeklyHours" to Math.round(totalWeekly * 100.0) / 100.0
                                    ),
                                    SetOptions.merge()
                                )
                            }
                        }

                        while (!histTask!!.isSuccessful())
                        {
                            TimeUnit.MILLISECONDS.sleep(500)
                        }
                        if(histTask!!.isSuccessful())
                        {
                            TimeUnit.MILLISECONDS.sleep(500)
                            batch.commit()
                            Log.e("BGWritesWorker", "Successfully wrote screen time data to history")
                        }
                    } catch (e: Exception){
                        Log.e("BGWritesWorker", "Error writing screen time data to Firestore: $e")
                        throw e
                    }
                }
                else{
                    Log.d("BGWritesWorker", "No data needed to be written to history")
                }

            }
    } catch (e: Exception) {
        Log.e("BGWritesWorker", "Error fetching screen time data from Firestore: $e")
    }
}