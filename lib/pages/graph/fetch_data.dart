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
import 'package:app_screen_time/main.dart';


//Global Variables
Map<String, Map<String, Map<String, dynamic>>> historicalData = {};
DateTime currentDataset = DateTime.now().subtract(Duration(days: DateTime.now().weekday - DateTime.monday));
DateTime previousDataset = currentDataset.subtract(Duration(days: 7));
DateTime nextDataset = currentDataset.add(Duration(days: 7));
bool hasNextDataSet = false;
bool hasPreviousDataset = true;
//
//VARIABLE FOR CURRENTDATA
//

///*********************************
/// Name: _updateUserRef
/// 
/// Description: Private function for 
/// accessing reference to users' doc
///*********************************
void _updateUserRef() {
  //Grab current UID
  var curUid = uid;
  //Regrab UID in case it's changed
  uid = auth.currentUser?.uid;
  //Update user reference if UID has changed
  if(curUid != uid) {
    userRef = mainCollection.doc(uid);
  }
}

///*********************************
/// Name: fetchScreenTime
/// 
/// Description: Fetch the screentime 
/// for the current week which is  
/// stored within userAppHistory in our 
/// database. Data is fetched using a map
/// of map of maps and is returned.
///*********************************
Future<Map<String, Map<String, Map<String, dynamic>>>> fetchHistoricalScreenTime() async {
  //Update the reference to the user doc before accessing
  _updateUserRef();
  //Variable for holding week long segments of data
  Map<String, Map<String, Map<String, dynamic>>> fetchedData = {};
  //Variable for scoping into the users appUsageHistory collection
  final current = userRef.collection("appUsageHistory");
  previousDataset = currentDataset.subtract(Duration(days: 7));
  nextDataset = currentDataset.add(Duration(days: 7));
  String formattedPrevious = DateFormat('MM-dd-yyyy').format(previousDataset);
  String formattedNext = DateFormat('MM-dd-yyyy').format(nextDataset);
  DocumentSnapshot previousDoc = await current.doc(formattedPrevious).get();
  DocumentSnapshot nextDoc = await current.doc(formattedNext).get();
  if (previousDoc.exists) {
    hasPreviousDataset = true;
  } else {
    hasPreviousDataset = false;
  }
  if (nextDoc.exists) {
    hasNextDataSet = true;
  } else {
    hasNextDataSet = false;
  }
  //Variable for holding weeks begin data(Monday), formatted same way as Firebase formats
  String formattedCurrent = DateFormat('MM-dd-yyyy').format(currentDataset);
  //Try block for accessing collection in users document, try/catch because of async
  try{
    //Get a 'snapshot' of a doucment where its name is equal to the formatted string
    DocumentSnapshot doc = await current.doc(formattedCurrent).get();
    if (doc.exists) {
      //First level of maps holding the days of the week with recorded data
      Map<String, dynamic> weeklyData = doc.data() as Map<String, dynamic>;
      //Access each individual day in weekly data
      for (String day in weeklyData.keys) {
        if (day != 'totalWeeklyHours'){
          //Second level of maps holding the apps with recorded data
          Map<String, dynamic> dailyData = weeklyData[day];
          fetchedData[day] = {};
          //Access each individual app in daily data
          for (String appName in dailyData.keys) {
            if (appName != 'totalDailyHours'){
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
  catch (e){
    debugPrint("error fetching screentime data: $e");
  }
  return fetchedData;
}

