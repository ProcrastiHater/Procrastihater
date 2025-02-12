///*********************************
/// Name: fetch_historical.dart
///
/// Description: Map colors to specific
/// app names for consistency
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//Firebase Imports
import 'package:cloud_firestore/cloud_firestore.dart';

//Page Imports
import '/pages/home_page.dart';


//Global Variables
Map<String, Map<String, Map<String, dynamic>>> data = {};

void _updateUserRef() {
  //Grab current UID
  var curUid = uid;
  //Regrab UID in case it's changed
  uid = AUTH.currentUser?.uid;
  //Update user reference if UID has changed
  if(curUid != uid) {
    userRef = MAIN_COLLECTION.doc(uid);
  }
}
Future<Map<String, Map<String, Map<String, dynamic>>>> fetchScreenTime() async {
  _updateUserRef();
  Map<String, Map<String, Map<String, dynamic>>> fetchedData = {};
  final current = userRef.collection("appUsageHistory");
  DateTime lastMonday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - DateTime.monday));
  String fortmattedLastMonday = DateFormat('MM-dd-yyyy').format(lastMonday);
  try{
    DocumentSnapshot doc = await current.doc(fortmattedLastMonday).get();
    if (doc.exists) {
      Map<String, dynamic> weeklyData = doc.data() as Map<String, dynamic>;
      for (String day in weeklyData.keys) {
        if (day != 'totalWeeklyHours'){
          Map<String, dynamic> dailyData = weeklyData[day];
          fetchedData[day] = {};
          for (String appName in dailyData.keys) {
            if (appName != 'totalDailyHours'){
              Map<String, dynamic> appData = dailyData[appName];
              fetchedData[day]![appName] = {
                'hours': appData['hours'].toDouble(),
                'appType': appData['appType'],
                'lastUpdated': appData['lastUpdated']
              };
            }
          }
        }
      }
    }
  } catch (e){
    debugPrint("error fetching screentime data: $e");
  }
  return fetchedData;
}

