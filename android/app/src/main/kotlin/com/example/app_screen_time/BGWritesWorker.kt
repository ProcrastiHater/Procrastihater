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
import java.time.LocalDate
import java.text.SimpleDateFormat
import java.time.temporal.TemporalAdjusters
import java.time.format.DateTimeFormatter
import java.time.Instant
import java.time.ZoneId
import java.time.DayOfWeek
//Screen time usage import
import android.app.usage.UsageStatsManager
//Firebase imports
import com.google.firebase.*
import com.google.firebase.firestore.*
import com.google.firebase.auth.*
import com.google.android.gms.tasks.Task
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
        currentToHistorical()
        getScreenTimeStats()
        writeScreenTimeData()
        Log.d("BGWritesWorker", "Screen time should be written")
        return Result.success()
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
            val current = userRef!!.collection("appUsageCurrent");
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
                        var pointChange : Long = 0
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
                                    val historical = userRef!!.collection("appUsageHistory").document(startOfWeekStr)
                                    if(histTask == null) {
                                        histTask = historical
                                            .get()
                                            .addOnSuccessListener{ result2 ->
                                                if(result2.contains("totalWeeklyHours"))
                                                {
                                                    val weekly = result2.getDouble("totalWeeklyHours")
                                                    if(weekly != null)
                                                    {
                                                        totalWeekly += weekly
                                                        batch.set(
                                                            historical,
                                                            hashMapOf(
                                                                "totalWeeklyHours" to Math.round(totalWeekly * 100.0) / 100.0
                                                            ),
                                                            SetOptions.merge()
                                                        )
                                                    }
                                                }
                                                batch.commit()
                                                Log.d("BGWritesWorker", "Successfully wrote screen time data to history")
                                                histSnapshot = result2
                                            }
                                            .addOnFailureListener{
                                                Log.e("BGWritesWorker", "Error getting week in history")
                                            }
                                    }
                                    totalDaily += screenTimeHours
                                    totalWeekly += screenTimeHours
                                    if(category == "Productivity"){
                                        pointChange += (screenTimeHours*3).toInt()
                                    }
                                    if(category == "Social & Communication"){
                                        pointChange -= (screenTimeHours*3).toInt()
                                    }
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

                                    if (totalDaily >= 12) {
                                        pointChange += -20
                                    } else if (totalDaily >= 8) {
                                        pointChange += -10
                                    } else if (totalDaily >= 6) {
                                        pointChange += 10
                                    } else if (totalDaily >= 4) {
                                        pointChange += 20
                                    } else if (totalDaily >= 2) {
                                        pointChange += 30
                                    } else if (totalDaily >= 1) {
                                        pointChange += 40
                                    } else {
                                        pointChange += 50
                                    }

                                    batch.update(
                                        userRef!!,
                                        "points",
                                        FieldValue.increment(pointChange)
                                    ) 
                                }
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
        updateUserRef()
        if(screenTimeMap.isNotEmpty()){
            var totalDaily: Double = 0.0
            val current = userRef!!.collection("appUsageCurrent");
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
                            userRef!!,
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
                Log.e("BGWritesWorker", "Error getting app info for ${stats.packageName}", e)
                continue
            }
        }

        Log.d("BGWritesWorker", "Screen time data: $screenTimeMap")
        return screenTimeMap
    }
}