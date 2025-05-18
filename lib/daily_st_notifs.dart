///*********************************
/// Name: daily_st_notifs.dart
///
/// Description: Start or stop daily screentime
/// notifications
///*********************************
library;

///*********************************
/// Name: cancelTotalSTNotifications
///   
/// Description: Invokes method from platform channel to 
/// stop sending the total screen time notification
///*********************************
Future<void> cancelTotalSTNotifications() async {
  try {
    await platformChannel.invokeMethod('cancelTotalSTNotifications');
  } on PlatformException catch (e) {
    debugPrint("Failed to stop notifications: ${e.message}");
  }
}

///*********************************
/// Name: _startTotalSTNotifications
///   
/// Description: Invokes method from platform channel to 
/// start sending the total screen time notification
///*********************************
Future<void> startTotalSTNotifications() async {
  if(!hasPermission) {
    return;
  }
  try {
    await platformChannel.invokeMethod('startTotalSTNotifications');
  } on PlatformException catch (e) {
    debugPrint("Failed to start notifications: ${e.message}");
  }
}