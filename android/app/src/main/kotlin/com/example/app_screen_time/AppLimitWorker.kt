package com.example.app_screen_time

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.app_screen_time.MainActivity
//Firebase Imports
import com.google.firebase.*
import com.google.firebase.firestore.*
import com.google.firebase.auth.*

///************************************************************
/// Name: AppLimitWorker
///
/// Description: Helper class for sending notifications about
/// app screen time limits
///*************************************************************
class AppLimitWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams){
    val context = getApplicationContext()

    ///**********************************************
    /// Name: doWork
    ///
    /// Description: Shows notification if user has
    /// hit limit for an app
    ///**********************************************    
    override fun doWork(): Result {
        showNotification()
        Log.d("doWork", "Notification should be showing")
        return Result.success()
    }
}