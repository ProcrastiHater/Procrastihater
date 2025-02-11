///*********************************
/// Name: notification_service.dart
///
/// Description: Dart file for managing
/// local notifications plugin
///*******************************

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

bool _notificationsEnabled = false;

class NotificationService {
  static void initialize(){
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher")
    );

    notificationsPlugin.initialize(
      initSettings
    );

    Future<void> _isAndroidPermissionGranted() async {
      final bool granted = await notificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
        _notificationsEnabled = granted;
    }

    Future<void> _requestPermissions() async {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
        notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
        await androidImplementation?.requestNotificationsPermission();
      _notificationsEnabled = grantedNotificationPermission ?? false;
    }

    _isAndroidPermissionGranted();
    _requestPermissions();
  }
}