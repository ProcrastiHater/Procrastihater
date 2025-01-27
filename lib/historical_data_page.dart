///*********************************
/// Name: historical_data_page.dart
///
/// Description: Historical Data page file for 
/// application
///*******************************

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//fl_chart imports
import 'package:fl_chart/fl_chart.dart';

//Page imports
import 'home_page.dart';


///*********************************
/// Name: HistoricalDataPage
/// 
/// Description: Root stateless widget of 
/// the HistoricalDataPage, builds and displays 
/// historical data page view
///*********************************
class HistoricalDataPage extends StatelessWidget {
  const HistoricalDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    home: Container(
      padding: EdgeInsets.all(4.0),
      child: Column(
        spacing: 4.0,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4.0),
              color: Colors.blue,
              child: GraphView(),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4.0),
              color: Colors.red,
              //child: ExpandedListView(),
            ),
          ),
        ],
      ),

    )    
    );
  }
}
class GraphView extends StatefulWidget {
  const GraphView({super.key});
  @override
  State<GraphView> createState() => _MyGraphViewState();
}
class _MyGraphViewState extends State<GraphView> {
  void _updateUserRef()
  {
    //Grab current UID
    var curUid = uid;
    //Regrab UID in case it's changed
    uid = AUTH.currentUser?.uid;
    //Update user reference if UID has changed
    if(curUid != uid)
    {
      userRef = MAIN_COLLECTION.doc(uid);
    }
  }
Future<Map<String, Map<String, Map<String, dynamic>>>> _fetchScreenTime() async {
  _updateUserRef();
  final CURRENT = userRef.collection("appUsageHistory");
  DateTime lastMonday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - DateTime.monday + 7));
  String fortmattedLastMonday = DateFormat('MM-dd-yyyy').format(lastMonday);
  try{
    DocumentSnapshot doc = await CURRENT.doc(fortmattedLastMonday).get();
    if (doc.exists) {
      Map<String, dynamic> weeklyData = doc.data() as Map<String, dynamic>;
      Map<String, Map<String, Map<String, dynamic>>> fetchedData = {};
      for (String day in weeklyData.keys) {
        Map<String, dynamic> dailyData = weeklyData[day];
        fetchedData[day] = {};
        for (String appName in dailyData.keys) {
          Map<String, dynamic> appData = dailyData[appName];
          fetchedData[day]![appName] = {
            'hours': appData['hours'].toDouble(),
            'appType': appData['appType'],
            'lastUpdated': appData['lastUpdated']
          };
        }
      }
      return fetchedData;
    }
    return {};
  } catch (e){
    print("error fetching screentime data: $e");
    return {};
  }
}
  @override
  void initState() {
    _fetchScreenTime();
    super.initState();
  }
  
  //BarChartGroupData(int index, int mapSize, Map<String, Map<String, String>> screentimeData)
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

    );
  }
}

class ExpandedListView extends StatefulWidget {
  const ExpandedListView({super.key});
  @override
  State<ExpandedListView> createState() => _MyExpandedListViewState();
}
class _MyExpandedListViewState extends State<ExpandedListView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
