package com.example.app_screen_time

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.app_screen_time.MainActivity
//Used for time calculations
import java.util.Calendar
import java.util.TimeZone
import java.util.Locale
import java.util.Date
//Screen time usage import
import android.app.usage.UsageStatsManager
//Firebase imports
import com.google.firebase.Firebase
import com.google.firebase.firestore.*
import com.google.firebase.auth.*
//Allows access to category titles
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

///*********************************************
/// Name: BGWritesWorker
///
/// Description: Helper class for doing background writes
///**********************************************
class BGWritesWorker(context: Context, workerParams: WorkerParameters) : Worker (context, workerParams){
    val context = getApplicationContext()
    ///**********************************************
    /// Name: doWork
    ///
    /// Description: Attempts to write to Firestore 
    /// when worker does its task
    ///**********************************************    
    override fun doWork(): Result {
        getScreenTimeStats()
        writeScreenTimeData()
        Log.d("doWork", "Screen time should be written")
        return Result.success()
    }


    ///**************************************************
    /// Name: writeScreenTimeData
    ///
    /// Description: Takes the data
    /// that was accessed in _getScreenTime
    /// and writes it to the Firestore database
    /// using batches for multiple writes
    ///***************************************************
    private fun writeScreenTimeData(){
        //Update ref to user's doc if UID has changed
        updateUserRef();
        if(screenTimeMap.isNotEmpty()){
            var totalDaily: Double = 0.0
            val current = userRef.collection("appUsageCurrent");
            // Create a batch to handle multiple writes
            val batch = firestore.batch()
            try {
                //Purge old data
                val currentSnap = current
                    .get()
                    .addOnSuccessListener{ result ->
                        for (doc in result.getDocuments()) {
                            batch.delete(doc.getReference())
                        }
                        Log.d("BGWritesWorker", "Clearing appUsageCurrent")
                        // Iterate through each app and its screen time
                        for (entry in screenTimeMap.entries.iterator())
                        {
                            val appName = entry.component1()
                            val screenTimeHours = (entry.component2()["hours"])!!.toDouble()
                            val category = entry.component2()["category"]
                            totalDaily += screenTimeHours
        
                            // Reference to the document with app name
                            val docRef = current.document(appName)
        
                            // Set the data with merge option to update existing documents
                            // or create new ones if they don't exist
                            batch.set(
                                docRef,
                                hashMapOf(
                                    "dailyHours" to screenTimeHours,
                                    "lastUpdated" to FieldValue.serverTimestamp(),
                                    "appType" to category,
                                ),
                                SetOptions.merge()
                            )
                        }
                        batch.set(
                            userRef,
                            hashMapOf(
                                "totalDailyHours" to Math.round(totalDaily * 100.0) / 100.0,
                                "lastUpdated" to FieldValue.serverTimestamp(),
                            ),
                            SetOptions.merge()
                        )
                        // Commit the branch
                        batch.commit()
                        Log.d("BGWritesWorker", "Committed Write")
                    }
                    .addOnFailureListener{ exception ->
                        Log.e("BGWritesWorker", "Error clearing documents.", exception)
                    }
            } catch (e: Exception) {
                Log.e("BGWritesWorker", "Error writing screen time data to Firestore: $e")
                throw e
            }
        }
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
                Log.e("MainActivity", "Error getting app info for ${stats.packageName}", e)
                continue
            }
        }
    
        return screenTimeMap
    }
}