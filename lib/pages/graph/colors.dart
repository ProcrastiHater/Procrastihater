///*********************************
/// Name: colors.dart
///
/// Description: Map colors to specific
/// app names for consistency
///*******************************
library;

//Dart Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//Page Imports
import 'package:app_screen_time/main.dart';

//Global variables
Map<String, Color> appNameToColor = {}; 

///*********************************
/// Name: generateDistinctColors
///
/// Description: Generates a list of 
/// colors based on the amount of total
/// apps that the user has in database.
/// Uses goldenRatio constant and hue
/// to ensure distinctness
///*******************************
List<Color> generateDistinctColors(int count) {
  final List<Color> colors = [];
  const double goldenRatioConjugate = 0.618033988749895;
  double hue = 0;
  //Loop through every app user has in database
  for (int i = 0; i < count; i++) {
    //Increment hue by golden ratio and ensure in bounds
    hue = (hue + goldenRatioConjugate) % 1;
    //Use HSL with hue and fixed saturation/lightness
    final color = HSLColor.fromAHSL(1.0, hue * 360, 1.0, 0.5).toColor();
    colors.add(color);
  }
  return colors;
}

///*********************************
/// Name: initializeAppNameColorMapping
///
/// Description: Loads all apps the user
/// has stored in the database(historical 
/// and current) before mapping all apps 
/// to a distinct color provided by 
/// generateDistinctColor()
///*******************************
Future<void> initializeAppNameColorMapping() async {
  updateUserRef();
  //Attempt to connect to database
  try {
    final currentHistory = userRef.collection('appUsageHistory');
    //Take a snapshot of all docs in appUsageHistory
    QuerySnapshot historySnapshot = await currentHistory.get();
    //Set for holding app Names

    final currentAppUsage = userRef.collection('appUsageCurrent');
    QuerySnapshot currentSnapshot = await currentAppUsage.get();

    Set<String> allAppNames = {};
    
    //Loop through each doc in appUsageHistory
    for (var doc in historySnapshot.docs) {
      //Extract weekly data from each doc
      Map<String, dynamic> weeklyData = doc.data() as Map<String, dynamic>;
      //Loop through weekly data
      weeklyData.forEach((dayKey, dailyValue) {
        //Skip totalWeeklyHours memeber
        if (dayKey != 'totalWeeklyHours') {
          //Extract daily data from each weekly data
          Map<String, dynamic> dailyData = dailyValue as Map<String, dynamic>;
          //Loop through dail data
          dailyData.forEach((appName, appData) {
            //Skip totalDailyHours memeber
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
    //Loop through each doc in appUsageHistory
    for (var doc in currentSnapshot.docs) {
      //Add app names to set
      allAppNames.add(doc.id);
    }
    //Sorts unordered set before assigning colors to names, ensuring consistency across whole app
    List<String> sortedAppNames = allAppNames.toList()..sort();
    //Get distinct colors
    List<Color> distinctColors = generateDistinctColors(sortedAppNames.length);
    //Map colors to app name
    for (int i = 0; i < sortedAppNames.length; i++) {
      appNameToColor[sortedAppNames[i]] = distinctColors[i];
    }
  } catch (e) {
    debugPrint("Error in initalizeAppNamesColorMapping: $e");
  }
}