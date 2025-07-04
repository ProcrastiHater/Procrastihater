///*********************************
/// Name: fetch_historical.dart
///
/// Description: Map colors to specific
/// app names for consistency
///*******************************
library;

//Dart Imports
import 'package:app_screen_time/pages/graph/widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//Firebase Imports
import 'package:cloud_firestore/cloud_firestore.dart';

//Page Imports
import 'package:app_screen_time/main.dart';

//Global Variables
Map<String, Map<String, Map<String, dynamic>>> weeklyData = {};
//Monthly data variable placeholder

//Variables for multi-week view
List<String> availableWeekKeys = [];
DateTime currentDataset = DateTime.now();
String formattedCurrent = DateFormat('MM-dd-yyyy').format(currentDataset);

///*********************************
/// Name: getAvailableWeeks
///
/// Description: Function to convert a
/// querysnapshot of collection appUsageHistory
/// into a list
///*********************************
///
Future<void> getAvailableWeeks() async {
  //Update the reference to the user doc before accessing
  updateUserRef();
  //Variable for scoping into the users appUsageHistory collection
  final current = userRef.collection("appUsageHistory");
  try {
    //Get all documents from the collection
    QuerySnapshot querySnapshot = await current.get();
    if (querySnapshot.docs.isNotEmpty) {
      //Extract the document IDs
      List<String> availableWeeks =
          querySnapshot.docs.map((doc) => doc.id).toList();

      // Sort the week keys by date
      final DateFormat formatter = DateFormat('MM-dd-yyyy');
      availableWeeks
          .sort((a, b) => formatter.parse(a).compareTo(formatter.parse(b)));
      availableWeekKeys = availableWeeks;
    }
    currentDataset = DateFormat('MM-dd-yyyy').parse(availableWeekKeys.last);
  } catch (e) {
    debugPrint("error fetching screentime data: $e");
  }
}

///*********************************
/// Name: fetchWeeklyScreenTime
///
/// Description: Fetch the screentime
/// for the current week which is
/// stored within userAppHistory in our
/// database. Data is fetched using a map
/// of map of maps and is returned.
///*********************************
Future<void> fetchWeeklyScreenTime() async {
  //Update the reference to the user doc before accessing
  updateUserRef();
  //Variable for scoping into the users appUsageHistory collection
  final current = userRef.collection("appUsageHistory");

  //Format the current dataset's date to match the document ID format
  formattedCurrent = DateFormat('MM-dd-yyyy').format(currentDataset);

  //Variable for holding week long segments of data
  Map<String, Map<String, Map<String, dynamic>>> fetchedData = {};
  //Try block for accessing collection in users document, try/catch because of async
  try {
    //Get a 'snapshot' of a doucment where its name is equal to the formatted string
    DocumentSnapshot doc = await current.doc(formattedCurrent).get();
    if (doc.exists) {
      //First level of maps holding the days of the week with recorded data
      Map<String, dynamic> weeklyData = doc.data() as Map<String, dynamic>;
      //Access each individual day in weekly data
      for (String day in weeklyData.keys) {
        if (day != 'totalWeeklyHours') {
          //Second level of maps holding the apps with recorded data
          Map<String, dynamic> dailyData = weeklyData[day];
          fetchedData[day] = {};
          //Access each individual app in daily data
          for (String appName in dailyData.keys) {
            if (appName != 'totalDailyHours') {
              //Last level of maps holding recorded data for each app
              Map<String, dynamic> appData = dailyData[appName];
              //Write the data to our Map of Map of Maps for use in historical graph display
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
  }
  //Catch block if accessing user document fails
  catch (e) {
    debugPrint("error fetching screentime data: $e");
  }
  weeklyData = fetchedData;
  weeklyData = Map.fromEntries(
    weeklyData.entries.toList()
      ..sort(
          (a, b) => dayOrder.indexOf(a.key).compareTo(dayOrder.indexOf(b.key))),
  );
}

///*********************************
/// Name: fetchTotalDayScreentime
///
/// Description: Return the total number
/// of hours the user has been on their phone
/// for the given day
///*********************************
Future<double> fetchTotalDayScreentime() async {
  //Try block for accessing field in users doc
  try {
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      double dailyScreenTime = await userDoc.get("totalDailyHours") ?? 0.0;
      return dailyScreenTime;
    }
  } catch (e) {
    debugPrint("error fetching daily screentime data: $e");
  }
  return 0;
}

///*********************************
/// Name: fetchPoints
///
/// Description: Return the users
/// point total
///*********************************
Future<int> fetchPoints() async {
  //Try block for accessing field in users doc
  try {
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      int points = await userDoc.get("points") ?? 0.0;
      return points;
    }
  } catch (e) {
    debugPrint("error fetching screentime data: $e");
  }
  return 0;
}
