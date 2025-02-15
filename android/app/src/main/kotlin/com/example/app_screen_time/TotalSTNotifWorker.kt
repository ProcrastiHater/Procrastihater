package com.example.app_screen_time

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class TotalSTNotifWorker(context: Context, workerParams: WorkerParameters) : Worker (context, workerParams){
    override fun doWork(): Result {
        showNotification()
        Log.d("doWork", "Notification should be showing")
        return Result.success()
    }

    private fun showNotification(){
        var builder = NotificationCompat.Builder(applicationContext, "ProcrastiNotif")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Screen Time")
            .setContentText("Hey, I'm working over here!")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        with(NotificationManagerCompat.from(applicationContext)) {
            notify(213, builder.build())
        }
    }
}