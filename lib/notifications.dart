///*********************************
/// Name: notifications.dart
///
/// Description: Dart file for storing 
/// notification details
///*******************************

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

NotificationDetails totalUsage = NotificationDetails(
  android: AndroidNotificationDetails(
    'usage_notifs',
    'total_usage',
    channelDescription: 'Notifications for total usage',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker'
  )
);