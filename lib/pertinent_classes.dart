import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  String pfp;
  int points;
  String username;
  List<GeoPoint>? unproductiveLocations;
  List<GeoPoint>? productiveLocations;
  List<CurrentAppUsage>? currentAppUsage;
  List<Friend>? friends;
  UserAppHistory? userAppHistory;

  User(
      {required this.uid,
      required this.pfp,
      required this.points,
      required this.username,
      required this.productiveLocations,
      required this.unproductiveLocations,
      required this.currentAppUsage,
      required this.friends,
      required this.userAppHistory});
  User.noLocationTracking(
      {required this.uid,
      required this.pfp,
      required this.points,
      required this.username,
      required this.currentAppUsage,
      required this.friends,
      required this.userAppHistory});
  User.newUser(
      {required this.uid,
      required this.pfp,
      required this.points,
      required this.username});
}

class CurrentAppUsage {
  final String appName;
  final String appType;
  int dailyHours;
  int? dailyProductiveHours;
  int? dailyUnproductiveHours;

  CurrentAppUsage(
      {required this.appName,
      required this.appType,
      required this.dailyHours,
      required this.dailyProductiveHours,
      required this.dailyUnproductiveHours});
  CurrentAppUsage.noHourTypeTracking(
      {required this.appName, required this.appType, required this.dailyHours});
}

class Friend {
  String pfp;
  String username;
  bool pokeable;
  bool poked;
  final User uid;

  Friend(
      {required this.pfp,
      required this.username,
      required this.pokeable,
      required this.poked,
      required this.uid});
}


class UserAppHistory {
  TotalUserHistory totalUserHistory;
  List<Week> weeks;

  UserAppHistory({required this.totalUserHistory, required this.weeks});
}

class TotalUserHistory {
  int totalAllTimeHours;
  int totalMonthlyHours;
  int totalProductiveHours;
  int totalUnproductiveHours;

  TotalUserHistory(
      {required this.totalAllTimeHours,
      required this.totalMonthlyHours,
      required this.totalProductiveHours,
      required this.totalUnproductiveHours});
}

class Week {
  List<Day> weekDay;
  int? totalProductiveHours;
  int? totalUnproductiveHours;
  int totalWeeklyHours;
  DateTime weekBegin;
  DateTime weekEnd;

  Week(
      {required this.weekDay,
      required this.totalProductiveHours,
      required this.totalUnproductiveHours,
      required this.totalWeeklyHours,
      required this.weekBegin,
      required this.weekEnd});
  Week.noHourTypeTracking(
      {required this.weekDay,
      required this.totalWeeklyHours,
      required this.weekBegin,
      required this.weekEnd});
}

class Day {
  int totalDailyHours;
  List<AppTrack> day;

  Day({required this.totalDailyHours, required this.day});
}

class AppTrack {
  String appName;
  String appType;
  int? unproductiveHours;
  int? productiveHours;
  int totalHours;
  DateTime lastUpdate;

  AppTrack(
      {required this.appName,
      required this.appType,
      required this.unproductiveHours,
      required this.productiveHours,
      required this.totalHours,
      required this.lastUpdate});
  AppTrack.noHourTypeTracking(
      {required this.appName,
      required this.appType,
      required this.totalHours,
      required this.lastUpdate});
}
