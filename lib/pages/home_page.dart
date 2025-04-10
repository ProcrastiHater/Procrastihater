///*********************************
/// Name: home_page.dart
///
/// Description: Home page file for
/// application, currently holds
/// current app usage
///*******************************
library;

//Dart imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//fl_chart imports
import 'package:fl_chart/fl_chart.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//Page Imports
import '/pages/graph/graph.dart';

import '/main.dart';
import '/pages/graph/list_view.dart';
import '/profile/profile_settings.dart';
import '/pages/graph/fetch_data.dart';
import '/pages/graph/widget.dart';
import '/pages/graph/colors.dart';


///*********************************
/// Name: HomePage
///
/// Description: Root stateless widget of
/// the HomePage, builds and displays home page view
///*********************************
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    //Wait for a gesture
    return GestureDetector(
      //The user swipes horizontally
      onHorizontalDragEnd: (details) {
        //The user swipes from right to left
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          //Load animation for leaderboard page
          Navigator.pushReplacementNamed(context, '/leaderBoardPage');
        }
        //The user swipes from left to right
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          //Load animation for friends page
          Navigator.pushReplacementNamed(context, '/friendsPage');
        }
      },
      child: Container(padding: const EdgeInsets.all(4.0), child: MyHomePage())
    );
  }
}

///*********************************
/// Name: MyHomePage
///
/// Description: Stateful widget for
/// root stateless widget
///*********************************
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

///*********************************
/// Name: _MyHomePageState
///
/// Description: State for MyHomePage,
/// holds main layout widget for page
///*********************************
class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  //State management for loading list view
  String selectedBar = "null";
  Map<String, Map<String, String>> dayData = screenTimeData;
  Map<String, Map<String, Map<String, dynamic>>> weekData = weeklyData;
  int graphIndex = 0;
  void updateSelectedBar(String bar) {
    setState(() {
      selectedBar = bar;
    });
  }
  void updateFilteredDayData(Map<String, Map<String, String>> data) {
    setState(() {
      dayData = data;
    });
  }
  void updateFilteredWeekData(Map<String, Map<String, Map<String, dynamic>>> data) {
    setState(() {
      weekData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    //Screensize
    double? screenWidth = MediaQuery.of(context).size.width;
    double? screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text("ProcrastiStats"),
        actions: [
          // Creating little user icon you can press to view account info
          IconButton(
            icon: CircleAvatar(
              backgroundImage: NetworkImage(
                // Use user's pfp as icon image if there is no pfp use this link as a default
                auth.currentUser?.photoURL ?? 'https://picsum.photos/id/237/200/300',
              ),
            ),
            onPressed: () async {
              await Navigator.pushNamed(context, "/profileSettings");
              // Reload the user in case anything changed
              await auth.currentUser?.reload();
              // Reload UI in case things changed
              setState(() {});
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.all(4.0),
          children: <Widget>[
            SizedBox(
              height: screenHeight * .15,
              child: DrawerHeader(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ProcrastiTools",),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.asset("assets/logo.jpg"),
                    ),
                  ],
                )
              ),
            ),
            ListTile(
              trailing: Icon(Icons.calendar_today),
              title: Text("Calendar"),
              onTap:() {
                Navigator.pushNamed(context, '/calendarPage');
              },
            ),
            const Divider(),
            ListTile(
              trailing: Icon(Icons.school),
              title: Text("Study Mode"),
              onTap: () {
                Navigator.pushNamed(context, '/studyModePage');
              },
            ),
            const Divider(),
            ListTile(
              trailing: Icon(Icons.alarm),
              title: Text("App Limits"),
              onTap: () {
                Navigator.pushNamed(context, '/appLimitsPage');
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [ 
          Expanded(
            flex: 6,
            //Container holding graph in top portion of screen
            child: Scaffold(
              body: [
                //Daily Graph
                Container(
                  padding: const EdgeInsets.all(4.0),
                  child: DailyGraphView(onFilteredData: updateFilteredDayData, onBarSelected: updateSelectedBar),
                ),
                //Weekly Graph
                Container(
                  padding: const EdgeInsets.all(4.0),
                  child: WeeklyGraphView(onFilteredData: updateFilteredWeekData, onBarSelected: updateSelectedBar),
                ),
              ][graphIndex],
              bottomNavigationBar: Container(
                height: 72,
                child: Column(
                  children: [
                    Container(color: beige, height: 2,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Card(
                          color: graphIndex == 0? beige : null,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.calendar_today_rounded,
                              color: graphIndex == 0? lightBlue : null,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedBar = "null";
                                graphIndex = 0;
                              }); 
                            },
                          ), 
                        ),
                        Card(
                          color: graphIndex == 1? beige : null,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.calendar_view_week_rounded,
                              color: graphIndex == 1? lightBlue : null,
                            ),
                            onPressed: () {
                              setState(() {
                               selectedBar = "null";
                                graphIndex = 1;
                              }); 
                            },
                          ), 
                        ),
                      ],
                    ),
                    Container(color: beige, height: 2,),
                  ],
                ),
              ),
            )         
          ),
          const SizedBox(height: 4.0),
          Expanded(
            flex: 4,
            //Container holding list view in bottom portion of screen
            child: Container(
              padding: const EdgeInsets.all(4.0),
              child: ExpandedListView(dayFilteredData: dayData, weekFilteredData: weekData, selectedBar: selectedBar, appColors: appNameToColor, graphIndex: graphIndex),
            ),
          ),
        ],
      ),
    );
  }
}
