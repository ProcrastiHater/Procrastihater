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
              color: Colors.indigo,
              child: GraphView(),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4.0),
              color: Colors.teal,
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
  static const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  Map<String, Map<String, Map<String, dynamic>>> data = {};
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
Future<void> _fetchScreenTime() async {
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
      setState(() {
        data = fetchedData;
      });
    }
  } catch (e){
    print("error fetching screentime data: $e");
  }
}
  @override
  void initState() {
    _fetchScreenTime();
    super.initState();
  }
  
  BarChartGroupData generatedGroupData(int index, Map<String, Map<String, dynamic>> dailyData) {
    final List<Color> appColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.teal,
    Colors.pink,
    ];
    final appNames = dailyData.keys.toList();
    final appNameToColor = {
      for (int i = 0; i < appNames.length; i++)
        appNames[i]: appColors[i % appColors.length]
    };

  List<BarChartRodStackItem> rodStackItems = [];
  double cumulativeHeight = 0;

  for (var appName in dailyData.keys) {
    double hours = dailyData[appName]?['hours'] ?? 0.0;
    rodStackItems.add(
      BarChartRodStackItem(
        cumulativeHeight, 
        cumulativeHeight + hours, 
        appNameToColor[appName]!, 
      ),
    );
    cumulativeHeight += hours; 
  }
  
  return BarChartGroupData(
    x: index,
    barRods: [
      BarChartRodData(
        fromY: 0,
        toY: cumulativeHeight, 
        rodStackItems: rodStackItems, 
        width: 15, 
        borderRadius: BorderRadius.circular(4),
      ),
    ],
  );
}
  List<BarChartGroupData> generateWeeklyChart(Map<String, Map<String, Map<String, dynamic>>> data) {
    return [
      for (int i = 0; i < days.length; i++)
        if (data.containsKey(days[i]))
          generatedGroupData(i, data[days[i]]!)
    ]; 
  }
  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 10.0, 
      color: Colors.white
      );
    String text = days[value.toInt()].substring(0,3);
    return SideTitleWidget(
      meta: meta,
      child: Text(
        text, 
        style: style)
      );
  }
  BarTouchData getBarTouch(Map<String, Map<String, Map<String, dynamic>>> data) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.blueGrey,
        tooltipPadding: const EdgeInsets.all(8.0),
        tooltipMargin: 8.0,
        getTooltipItem: (group, groupItem, rod, rodIndex) {
          String day = days[group.x];
          Map<String, dynamic> appData = data[day]!.values.elementAt(rodIndex);
          String appName = data[day]!.keys.elementAt(rodIndex);
          double hours = appData['hours'];
          String appType = appData['appType'];
          return BarTooltipItem(
            '$appName\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: 'Type: $appType\n',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'Hours: $hours\n',
                style: const TextStyle(
                 color: Colors.white, 
                )
              )
            ]
          );
        }
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: [
          const Text(
            'Historical Data',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          AspectRatio(
            aspectRatio: 1.05,
            child:  BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: .5,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      );
                    }
                  )
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: .5,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      );
                    }
                  )
                ),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: bottomTitles,
                    reservedSize: 20,
                  ) 
                ),
              ),  
              barTouchData: getBarTouch(data),
              borderData: FlBorderData(show: true),    
              gridData: FlGridData(show: true),
              barGroups: generateWeeklyChart(data),   
              backgroundColor: Colors.blueAccent,
            )
          )
          ),
        ],
      )
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
