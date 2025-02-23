package com.example.app_screen_time

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.app_screen_time.MainActivity
import kotlin.random.Random
//Used for time calculations
import java.util.Calendar
import java.util.TimeZone
import java.util.Locale
import java.util.Date
//Screen time usage import
import android.app.usage.UsageStatsManager
//Allows access to category titles
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

///*********************************************
/// Name: TotalSTWorker
///
/// Description: Helper class for sending
/// total screentime notifications
///**********************************************
class TotalSTWorker(context: Context, workerParams: WorkerParameters) : Worker (context, workerParams){
    val context = getApplicationContext()

    ///**********************************************
    /// Name: doWork
    ///
    /// Description: Shows notification when worker
    /// does its task
    ///**********************************************    
    override fun doWork(): Result {
        showNotification()
        Log.d("doWork", "Notification should be showing")
        return Result.success()
    }

    ///***********************************************
    /// Name: getTotalDaily
    /// 
    /// Description: Returns the total daily hours for
    /// the day
    ///***********************************************
    fun getTotalDaily() : Double{
        var totalDaily = 0.0
        for(app in screenTimeMap.entries.iterator())
        {
            val appHours: Double = (app.component2()["hours"])!!.toDouble()
            totalDaily += appHours
        }
        return Math.round(totalDaily * 100.0) / 100.0
    }

    ///**********************************************
    /// Name: showNotification
    ///
    /// Description: Helper function for creating and
    /// displaying the test notification
    ///**********************************************    
    private fun showNotification(){
        getScreenTimeStats()
        val totalDaily = getTotalDaily()
        var notifText = "You have used your phone for $totalDaily hours today."
        if(totalDaily <= 3){
            notifText += " 3 or less"
        }
        else if (totalDaily <= 6){
            notifText += " 6 or less"
        }
        else if (totalDaily <= 9){
            notifText += " 9 or less"
        }
        else{
            notifText += " More than 9"
        }
        var builder = NotificationCompat.Builder(context, "ProcrastiNotif")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("ProcrastiHater")
            .setContentText(notifText)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        //Executes notify on MainActivity
        with(NotificationManagerCompat.from(context)) {
            //Sends notification with random id
            notify(Random.nextInt(), builder.build())
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