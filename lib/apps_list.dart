///*********************************
/// Name: apps_list.dart
///
/// Description: Create a list of all
/// the user's unique apps
///*********************************
library;

import 'package:app_screen_time/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

List<String> appNames = List.empty();

Future<void> generateAppsList() async{
  updateUserRef();
  //Attempt to connect to database
  try {
    final currentHistory = userRef.collection('appUsageHistory');
    //Take a snapshot of all docs in appUsageHistory
    QuerySnapshot historySnapshot = await currentHistory.get();

    //Set for holding app names (prevents duplicate app names)
    Set<String> allAppNames = {};

    //Loop through each doc in appUsageHistory
    for (var doc in historySnapshot.docs) {
      //Extract weekly data from each doc
      Map<String, dynamic> weeklyData = doc.data() as Map<String, dynamic>;
      //Loop through weekly data
      weeklyData.forEach((dayKey, dailyValue){
        //Skip totalWeeklyHours member
        if (dayKey != 'totalWeeklyHours') {
          //Extract daily data from each weekly data
          Map<String, dynamic> dailyData = dailyValue as Map<String, dynamic>;
          //Loop through daily data
          dailyData.forEach((appName, appData){
            //Skip totalDailyHours member
            if (appName != 'totalDailyHours') {
              //Add app names to set
              allAppNames.add(appName);
            }
          }
          );
        }
      }
      );
    }

    //Loop through each app in grabbed phone data
    screenTimeData.forEach((key, value){
      allAppNames.add(key);
    });
    //Sorts unordered set and stores in global list
    appNames = allAppNames.toList()..sort();
  } catch (e) {
    debugPrint("Error generating list of apps: $e");
  }
}