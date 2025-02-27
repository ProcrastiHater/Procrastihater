///*********************************
/// Name: graph.dart
///
/// Description: File for holding 
/// graph classes for easy switching
/// between different graphs
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
import '/main.dart';
import '/profile/profile_settings.dart';
import '/pages/graph/fetch_data.dart';
import '/pages/graph/widget.dart';
import '/pages/graph/colors.dart';

///*********************************
/// Name: WeeklyGraphView
/// 
/// Description: Stateful widget for
/// weekly state
///*********************************
class WeeklyGraphView extends StatefulWidget {
  final Function(String) onBarSelected;
  const WeeklyGraphView({super.key, required this.onBarSelected});

  @override
  State<WeeklyGraphView> createState() => _WeeklyGraphViewState();
}

///*********************************
/// Name: _WeeklyGraphViewState
/// 
/// Description: State for WeeklyGraphView,
/// holds layout and state management for 
/// weekly graph
///*********************************
class _WeeklyGraphViewState extends State<WeeklyGraphView> {
  String currentWeek = DateFormat('MM-dd-yyyy').format(currentDataset);
  bool isLoading = false;
  //Fetch data from the database and intialize to global variable
  Future<void> _initializeData() async {
    final weeksToView = await getAvailableWeeks();
    availableWeekKeys = weeksToView;
    formattedCurrent = availableWeekKeys.last;
    currentWeek = formattedCurrent;
    currentDataset = DateFormat('MM-dd-yyyy').parse(currentWeek);
    final result = await fetchWeeklyScreenTime();
    setState(() {
      weeklyData = result;
      availableDays = weeklyData.keys.toList();
    });
  }

  //Wrapper for loading bar touch, 
  BarTouchData loadTouch(Map<String, Map<String, Map<String, dynamic>>> data) {
    return getBarWeekTouch(data, widget.onBarSelected);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    //Display loading screen if data is not present
    if (weeklyData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          //Graph Title
          Text("Weekly Graph", style: TextStyle(fontSize: 18),),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                //Title Widgets
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      maxIncluded: false,
                      showTitles: true,
                      interval: 1,
                      reservedSize: 25,
                      getTitlesWidget: sideTitles,
                    )
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      maxIncluded: false,
                      showTitles: true,
                      interval: 1,
                      reservedSize: 25,
                      getTitlesWidget: sideTitles,
                    )
                  ),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: bottomDayTitles,
                      reservedSize: 20,
                    )
                  ),
                ),
                //Style Widgets
                backgroundColor: Colors.white,
                borderData: FlBorderData(show: true),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  show: true,
                ),
                //Functionality Widgets
                barTouchData: loadTouch(weeklyData),
                barGroups: generateWeeklyChart(weeklyData),
              )
            )
          ),
          Row(
            //Equal spacing between children
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //Previous arrow button
              IconButton(
                onPressed: availableWeekKeys.isNotEmpty && availableWeekKeys.indexOf(currentWeek) > 0 && !isLoading
                  ? () async {
                  setState(() {
                    isLoading = true;
                });
                  int currentIndex = availableWeekKeys.indexOf(currentWeek);
                  currentWeek = availableWeekKeys[currentIndex - 1];
                  currentDataset = DateFormat('MM-dd-yyyy').parse(currentWeek);
                  weeklyData = await fetchWeeklyScreenTime();
                  availableDays = weeklyData.keys.toList();
                  setState(() {
                    isLoading = false;
                  });
                } : null,
                icon: Icon(Icons.arrow_back),
              ),
              Text(currentWeek),
              //Next arrow button
              IconButton(
                onPressed: availableWeekKeys.isNotEmpty && availableWeekKeys.indexOf(currentWeek) < availableWeekKeys.length - 1 && !isLoading
                  ? () async {
                  setState(() {
                    isLoading = true;
                  });
                  int currentIndex = availableWeekKeys.indexOf(currentWeek);
                  currentWeek = availableWeekKeys[currentIndex + 1];
                  currentDataset = DateFormat('MM-dd-yyyy').parse(currentWeek);
                  weeklyData = await fetchWeeklyScreenTime();
                  availableDays = weeklyData.keys.toList();
                  setState(() {
                    isLoading = false;
                  });
                } : null,
                icon: Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      )
    );
  }
}

///*********************************
/// Name: DailyGraphView
/// 
/// Description: Stateful widget for
/// daily state
///*********************************
class DailyGraphView extends StatefulWidget {
  final Function(String) onBarSelected;
  const DailyGraphView({super.key, required this.onBarSelected});

  @override
  State<DailyGraphView> createState() => _DailyGraphViewState();
}

///*********************************
/// Name: _DailyGraphViewState
/// 
/// Description: State for DailyGraphView,
/// holds layout and state management for 
/// daily graph
///*********************************
class _DailyGraphViewState extends State<DailyGraphView> {

  @override
  //Initialize colors making sure all apps are mapped to a color before displaying
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      availableApps = screenTimeData.keys.toList();
    });
  }

  //Wrapper for loading bar touch, 
  BarTouchData loadTouch(Map<String, Map<String, String>> data) {
    return getBarDayTouch(data, widget.onBarSelected);
  }

  @override
  Widget build(BuildContext context) {
    //Display loading screen if data is not present
    if (screenTimeData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          //Title for graph
          Text("Daily Graph", style: TextStyle(fontSize: 18),),
          Expanded(
            //Widget to allow scrolling of graph if it overflows the screen
            child: SingleChildScrollView(
              //Allow tooltips to display above graph
              //clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                //Sets a minimum size for graph
                constraints: BoxConstraints(minWidth: 390),
                child: SizedBox(
                  //Dynamically size graph based on amount of apps
                  width: 100 + availableApps.length * 70,
                  child: BarChart(
                    BarChartData(
                      groupsSpace: 60,
                      alignment: BarChartAlignment.center,
                      //Title Widgets
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            maxIncluded: false,
                            showTitles: true,
                            interval: 1,
                            reservedSize: 25,
                            getTitlesWidget: sideTitles,
                          )
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            maxIncluded: false,
                            showTitles: true,
                            interval: 1,
                            reservedSize: 25,
                            getTitlesWidget: sideTitles,
                          )
                        ),
                        topTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: bottomAppTitles,
                            reservedSize: 60,
                          )
                        ),
                      ),
                      //Style Widgets
                      backgroundColor: Colors.white,
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        show: true,
                      ),
                      //Functionality Widgets
                      barTouchData: loadTouch(screenTimeData),
                      barGroups: generateDailyChart(screenTimeData),
                    )
                  )
                ),
              )
            ),
          ),
        ],
      )
    );
  }
}