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
import 'package:app_screen_time/main.dart';
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
    return Container(padding: const EdgeInsets.all(4.0), child: MyHomePage());
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
  //State management for loading list view
  String selectedDay = "null";
  void updateSelectedDay(String day) {
    setState(() {
      selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettings(),
                ),
              );
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
            child: Container(
              padding: const EdgeInsets.all(4.0),
              color: Colors.indigo.shade50,
              child: GraphView(onDaySelected: updateSelectedDay),
            ),
          ),
          const SizedBox(height: 4.0),
          Expanded(
            //Container holding list view in bottom portion of screen
            child: Container(
              padding: const EdgeInsets.all(4.0),
              color: Colors.indigo.shade100,
              child: ExpandedListView(selectedDay: selectedDay, appColors: appNameToColor),
            ),
          ),
        ],
      ),
    );
  }
}

///*********************************
/// Name: GraphView
/// 
/// Description: Root stateful widget
/// for GraphView
///*********************************
class GraphView extends StatefulWidget {
  final Function(String) onDaySelected;
  const GraphView({super.key, required this.onDaySelected});

  @override
  State<GraphView> createState() => _GraphViewState();
}

///*********************************
/// Name: _MyGraphViewState
/// 
/// Description: State for GraphView,
/// builds graph and displays the current
/// week of data with ability to see
/// previous weeks
///*********************************
class _GraphViewState extends State<GraphView> {
  String currentWeek = DateFormat('MM-dd-yyyy').format(currentDataset);
  bool isLoading = false;
  //Fetch data from the database and intialize to global variable
  Future<void> _initializeData() async {
    //currentDataset = DateTime.now().subtract(Duration(days: DateTime.now().weekday - DateTime.monday));
    final weeksToView = await getAvailableWeeks();
    final result = await fetchHistoricalScreenTime();
    setState(() {
      availableWeekKeys = weeksToView;
      historicalData = result;
    });
  }

  //Wrapper for loading bar touch, 
  BarTouchData loadTouch(Map<String, Map<String, Map<String, dynamic>>> data) {
    return getBarTouch(data, widget.onDaySelected);
  }

  @override
  void initState() {
    super.initState();
    initializeAppNameColorMapping();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    //Display loading screen if data is not present
    if (historicalData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Expanded(
              child: AspectRatio(
                  aspectRatio: 1.25,
                  //Bar chart 
                  child: BarChart(BarChartData(
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
                      )),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                        maxIncluded: false,
                        showTitles: true,
                        interval: 1,
                        reservedSize: 25,
                        getTitlesWidget: sideTitles,
                      )),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 20,
                      )),
                    ),
                      //Style Widgets
                      backgroundColor: Colors.white,
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(
                      drawVerticalLine: false,
                      show: true,
                    ),
                    //Functionality Widgets
                    barTouchData: loadTouch(historicalData),
                    barGroups: generateWeeklyChart(historicalData),
                  ))),
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
                          historicalData = await fetchHistoricalScreenTime();
                          availableDays = historicalData.keys.toList();
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
                          historicalData = await fetchHistoricalScreenTime();
                          availableDays = historicalData.keys.toList();
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
/// Name: ExpandedListView
/// 
/// Description: Root stateful widget
/// for ExpandedListView
///*********************************
class ExpandedListView extends StatefulWidget {
  final String selectedDay;
  final Map<String, Color> appColors;
  const ExpandedListView(
      {super.key, required this.selectedDay, required this.appColors});
  @override
  State<ExpandedListView> createState() => _ExpandedListViewState();
}

///*********************************
/// Name: _MyExpandedListViewState
/// 
/// Description: Root stateful widget
/// for ExpandedListView
///*********************************
class _ExpandedListViewState extends State<ExpandedListView> {
  @override
  //Load text as placeholder while waiting for bar touch
  Widget build(BuildContext context) {
    if (widget.selectedDay == "null") {
      return Center(
        child: Text("Select a day to view",
            style: const TextStyle(
              decoration: TextDecoration.none,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            )),
      );
    }

    //Load loading screen if data is empty
    if (!historicalData.containsKey(widget.selectedDay)) {
      if (historicalData.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }  
      return Center(
          child: Text("No data available for ${widget.selectedDay}",
              style: const TextStyle(
                decoration: TextDecoration.none,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )
           )
        );
      }

    //List view built of daily data from bar touch
    final dayData = historicalData[widget.selectedDay]!;
    final reversedEntries = dayData.entries.toList().reversed.toList();
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: dayData.length,
      itemBuilder: (context, index) {
        final entry = reversedEntries.elementAt(index);
        final appName = entry.key;
        final appHours = entry.value['hours'];
        final appType = entry.value['appType'];
        return ListTile(
          title: Text(
            appName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.appColors[appName],
            ),
          ),
          subtitle: Text('$appHours hours'),
          trailing: Text(appType),
        );
      },
    );
  }
}
