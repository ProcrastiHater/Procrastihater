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
/// Description: Stateful widget that
/// manages the Firebase reading and writting
///*********************************
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

///*********************************
/// Name: MyHomePageState
///
/// Description: Manages state for MyHomePage,
/// accesses screentime of phone through method
/// channels, checks and requests neccesary
/// permissions, reads/write from firebase
///*********************************
class _MyHomePageState extends State<MyHomePage> {
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
                auth.currentUser?.photoURL ??
                    'https://picsum.photos/id/237/200/300',
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
            child: Container(
              padding: const EdgeInsets.all(4.0),
              color: Colors.indigo.shade50,
              child: GraphView(onDaySelected: updateSelectedDay),
            ),
          ),
          const SizedBox(height: 4.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4.0),
              color: Colors.indigo.shade100,
              child: ExpandedListView(
                  selectedDay: selectedDay, appColors: appNameToColor),
            ),
          ),
        ],
      ),
    );
  }
}

class GraphView extends StatefulWidget {
  final Function(String) onDaySelected;
  const GraphView({super.key, required this.onDaySelected});

  @override
  State<GraphView> createState() => _MyGraphViewState();
}

class _MyGraphViewState extends State<GraphView> {
  String currentWeek = DateFormat('MM-dd-yyyy').format(currentDataset);
  Future<void> _initializeData() async {
    final result = await fetchHistoricalScreenTime();
    setState(() {
      historicalData = result;
    });
  }

  BarTouchData loadTouch(Map<String, Map<String, Map<String, dynamic>>> data) {
    return getBarTouch(data, widget.onDaySelected);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    if (historicalData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Expanded(
              child: AspectRatio(
                  aspectRatio: 1.25,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.center,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                        maxIncluded: false,
                        showTitles: true,
                        interval: 1,
                        reservedSize: 15,
                        getTitlesWidget: sideTitles,
                      )),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                        maxIncluded: false,
                        showTitles: true,
                        interval: 1,
                        reservedSize: 15,
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
                    barTouchData: loadTouch(historicalData),
                    borderData: FlBorderData(show: true),
                    gridData: FlGridData(show: true),
                    barGroups: generateWeeklyChart(historicalData),
                    backgroundColor: Colors.white,
                  ))),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: hasPreviousDataset
                      ? () async {
                          currentDataset =
                              currentDataset.subtract(Duration(days: 7));
                          historicalData = await fetchHistoricalScreenTime();
                          availableDays = historicalData.keys.toList();
                          currentWeek =
                              DateFormat('MM-dd-yyyy').format(currentDataset);
                          setState(() {});
                        }
                      : null,
                  icon: Icon(Icons.arrow_back),
                ),
                Text(currentWeek),
                IconButton(
                  onPressed: hasNextDataSet
                      ? () async {
                          currentDataset =
                              currentDataset.add(Duration(days: 7));
                          historicalData = await fetchHistoricalScreenTime();
                          availableDays = historicalData.keys.toList();
                          currentWeek =
                              DateFormat('MM-dd-yyyy').format(currentDataset);
                          setState(() {});
                        }
                      : null,
                  icon: Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ));
  }
}

class ExpandedListView extends StatefulWidget {
  final String selectedDay;
  final Map<String, Color> appColors;
  const ExpandedListView(
      {super.key, required this.selectedDay, required this.appColors});
  @override
  State<ExpandedListView> createState() => _MyExpandedListViewState();
}

class _MyExpandedListViewState extends State<ExpandedListView> {
  @override
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
              )));
    }

    final dayData = historicalData[widget.selectedDay]!;

    return ListView.builder(
      itemCount: dayData.length,
      itemBuilder: (context, index) {
        final entry = dayData.entries.elementAt(index);
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
