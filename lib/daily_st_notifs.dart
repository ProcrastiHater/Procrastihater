///*********************************
/// Name: daily_st_notifs.dart
///
/// Description: Start or stop daily screentime
/// notifications
///*********************************
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

///*********************************
/// Name: cancelDailySTNotifications
///   
/// Description: Invokes method from platform channel to 
/// stop sending the daily screen time notification
///*********************************
Future<void> cancelDailySTNotifications() async {
  try {
    await platformChannel.invokeMethod('cancelDailySTNotifications');
  } on PlatformException catch (e) {
    debugPrint("Failed to stop notifications: ${e.message}");
  }
}

///*********************************
/// Name: startDailySTNotifications
///   
/// Description: Invokes method from platform channel to 
/// start sending the daily screen time notification
///*********************************
Future<void> startDailySTNotifications() async {
  if(!hasPermission) {
    return;
  }
  try {
    await platformChannel.invokeMethod('startDailySTNotifications');
  } on PlatformException catch (e) {
    debugPrint("Failed to start notifications: ${e.message}");
  }
}