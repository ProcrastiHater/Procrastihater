package com.example.app_screen_time

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import kotlin.random.Random

///*********************************************
/// Name: TestNotifWorker
///
/// Description: Helper class for sending notifications
///**********************************************
class TestNotifWorker(context: Context, workerParams: WorkerParameters) : Worker (context, workerParams){
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

    ///**********************************************
    /// Name: showNotification
    ///
    /// Description: Helper function for creating and
    /// displaying the test notification
    ///**********************************************    
    private fun showNotification(){
        var builder = NotificationCompat.Builder(getApplicationContext(), "ProcrastiNotif")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("ProcrastiHater")
            .setContentText("Hey, I'm working here!")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        //Executes notify on MainActivity
        with(NotificationManagerCompat.from(getApplicationContext())) {
            //Sends notification with random id
            notify(Random.nextInt(), builder.build())
        }
    }
}