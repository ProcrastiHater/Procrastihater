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
      child: Container(padding: const EdgeInsets.all(0.0), child: MyHomePage())
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
  int graphIndex = 0;
  void updateSelectedBar(String bar) {
    setState(() {
      selectedBar = bar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
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
      body: Column(
        children: [ 
          Expanded(
            //Container holding graph in top portion of screen
            child: Scaffold(
              body: [
                //Daily Graph
                Container(
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.indigo.shade50,
                  child: DailyGraphView(onBarSelected: updateSelectedBar),
                ),
                //Weekly Graph
                 Container(
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.indigo.shade50,
                  child: WeeklyGraphView(onBarSelected: updateSelectedBar),
                ),
                //Monthly Graph
                 Container(
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.indigo.shade50,
                  child: Center(child: Text("Monthly Graph Display"),)
                  //MonthlyGraphView(onBarSelected: updateSelectedBar),
                ),
              ][graphIndex],
              bottomNavigationBar: SizedBox(
                height: 50,
                child: NavigationBar(
                  selectedIndex: graphIndex,
                  backgroundColor: Colors.indigo.shade50,
                  onDestinationSelected: (int index) {
                    setState(() {
                      selectedBar == "null";
                      graphIndex = index;
                    });
                  },
                  destinations: const <Widget>[
                    NavigationDestination(
                      icon: Icon(Icons.calendar_today_rounded), 
                      label: 'Daily'
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_view_week_rounded), 
                      label: 'Weekly'
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_rounded), 
                      label: 'Monthly'
                    ),
                  ],  
                ), 
              )         
            )
          ),
          const SizedBox(height: 4.0),
          Expanded(
            //Container holding list view in bottom portion of screen
            child: Container(
              padding: const EdgeInsets.all(4.0),
              color: Colors.indigo.shade100,
              child: ExpandedListView(selectedBar: selectedBar, appColors: appNameToColor, graphIndex: graphIndex),
            ),
          ),
        ],
      ),
    );
  }
}
