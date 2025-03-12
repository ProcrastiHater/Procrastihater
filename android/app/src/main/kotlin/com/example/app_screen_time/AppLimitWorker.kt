package com.example.app_screen_time

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.app_screen_time.MainActivity
import com.example.app_screen_time.screenTimeMap
import com.example.app_screen_time.AppLimitWorker
import kotlin.random.Random
//Screen time usage import
import android.app.usage.UsageStatsManager
//Firebase Imports
import com.google.firebase.*
import com.google.firebase.firestore.*
import com.google.firebase.auth.*
//Used for time calculations
import java.util.Calendar
import java.util.TimeZone
import java.util.Locale
import java.util.Date
//Allows access to category titles
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

///************************************************************
/// Name: AppLimitWorker
///
/// Description: Helper class for sending notifications about
/// app screen time limits
///*************************************************************
class AppLimitWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams){
    val context = getApplicationContext()
    var limits = mutableMapOf<String, Double>()

    ///**********************************************
    /// Name: doWork
    ///
    /// Description: Shows notification if user has
    /// hit limit for an app
    ///**********************************************    
    override fun doWork(): Result {
        prevScreenTime.putAll(screenTimeMap)
        Log.d("GetStatsAppLimit", "Prev Screen Time: $prevScreenTime");
        getAppLimits()
        Log.d("AppLimitWorker", "Notification should be showing")
        return Result.success()
    }

    ///**********************************************
    /// Name: showNotification
    ///
    /// Description: Helper function for creating and
    /// displaying the app limit notification
    ///**********************************************    
    private fun showNotification(){
        getScreenTimeStats()
        
        for(app in limits.entries.iterator())
        {
            if (screenTimeMap[app.component1()] != null)
            {
                var prevhours : Double = 0.0
                if(prevScreenTime[app.component1()] != null)
                {
                    prevhours = prevScreenTime[app.component1()]!!["hours"]!!.toDouble()
                }
                val hours = screenTimeMap[app.component1()]!!["hours"]!!.toDouble()
                Log.d("AppLimitWorker", "Limit: ${app.component2()}")
                Log.d("AppLimitWorker", "Cur Hours: $hours")
                Log.d("AppLimitWorker", "Prev Hours: $prevhours")
                if(hours >= app.component2() && prevhours < app.component2()){
                    var builder = NotificationCompat.Builder(context, "ProcrastiNotif")
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setContentTitle("You've exceeded your screen time limit for ${app.component1()}")
                        .setContentText("How's that studying going?")
                        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                    //Executes notify on MainActivity
                    with(NotificationManagerCompat.from(context)) {
                        //Sends notification with random id
                        notify(Random.nextInt(), builder.build())
                    }
                }
            }
        } 
    }

    private fun getAppLimits() : MutableMap<String, Double>{
        //Update ref to user's doc if UID has changed
        updateUserRef()
        var fetchedData = mutableMapOf<String, Double>()

        try{
            val limitsRef = userRef!!.collection("limits")
            val limitsSnap = limitsRef
                .get()
                .addOnSuccessListener{ result ->
                    for(doc in result.getDocuments()) {
                        val app = doc.getId()
                        val hourLimit = doc.getDouble("limit")
                        if(hourLimit != null){
                            fetchedData[app] = Math.round(hourLimit * 100.0) / 100.0
                        }
                    }
                    
                    limits = fetchedData
                    Log.d("AppLimitWorker", "Limits: $limits")
                    showNotification()
                }
                .addOnFailureListener{
                    Log.e("AppLimitWorker", "Error getting limits collection")
                }
        } catch(e: Exception){
            Log.e("AppLimitWorker", "Error getting limits from Firestore: $e")
        }

        Log.d("AppLimitWorker", "Fetched Data: $fetchedData")
        return fetchedData;
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
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        //Sets the time range for data to be from midnight this morning to midnight tonight
        val calendar = Calendar.getInstance()
        //calendar.setTimeZone(TimeZone.getTimeZone("PST"))
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
                val appInfo = context.packageManager.getApplicationInfo(stats.packageName, 0)
                val appName = context.packageManager.getApplicationLabel(appInfo).toString()
                //Add apps' names as keys for the outer map
                screenTimeMap[appName] = mutableMapOf<String, String>()
                //Add hours and category as key-value pairs for the inner map
                screenTimeMap[appName]!!.put("hours", "%.2f".format(stats.totalTimeInForeground / 3600000.0).toString())
                if(appInfo.category != -1) {
                    screenTimeMap[appName]!!.put("category", ApplicationInfo.getCategoryTitle(context, appInfo.category).toString())
                }else {
                    screenTimeMap[appName]!!.put("category", "Other")
                }
            } catch (e: Exception) {
                Log.e("AppLimitWorker", "Error getting app info for ${stats.packageName}", e)
                continue
            }
        }

        Log.d("AppLimitWorker", "Screen time data: $screenTimeMap")
        return screenTimeMap
    }
}