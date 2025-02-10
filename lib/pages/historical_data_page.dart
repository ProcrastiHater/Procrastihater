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
import '/pages/home_page.dart';
import '/pages/graph/colors.dart';
import '/pages/graph/fetchHistorical.dart';

//Global variables
const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
Map<String, Map<String, Map<String, dynamic>>> data = {};

///*********************************
/// Name: HistoricalDataPage
/// 
/// Description: Root stateless widget of 
/// the HistoricalDataPage, builds and displays 
/// historical data page view
///*********************************
class HistoricalDataPage extends StatefulWidget {
  const HistoricalDataPage({super.key});
  
  @override
  State<HistoricalDataPage> createState() => _HistoricalDataPageState();
}
class _HistoricalDataPageState extends State<HistoricalDataPage> {
  String selectedDay = "null";

  void updateSelectedDay(String day) {
    setState(() {
      selectedDay = day;
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4.0),
                color: Colors.indigo.shade50,
                child: GraphView(onDaySelected: updateSelectedDay),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4.0),
                color: Colors.indigo.shade100,
                child: ExpandedListView(selectedDay: selectedDay, appColors: appNameToColor),
              ),
            ),
          ],
        ),
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
  List<String> availableDays = data.keys.toList(); 

  Future<void> _initializeData() async {
    final result = await fetchScreenTime();
    setState(() {
      data = result;
    });
  }

  @override
  void initState() {
    _initializeData();
    super.initState();
  }
  
  BarChartGroupData generatedGroupData(int index, Map<String, Map<String, dynamic>> dailyData) {
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
    for (int i = 0; i < availableDays.length; i++) {
      mapColors(data[availableDays[i]]!);
    }
    return [
      for (int i = 0; i < availableDays.length; i++) 
        generatedGroupData(i, data[availableDays[i]]!)
    ]; 
  }
  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      decoration: TextDecoration.none,
      fontSize: 10.0, 
      color: Colors.black,
      );
    String text = availableDays[value.toInt()].substring(0,3);
    return SideTitleWidget(
      meta: meta,
      child: Text(
        text, 
        style: style
      )
    );
  }
  BarTouchData getBarTouch(Map<String, Map<String, Map<String, dynamic>>> data) {
    return BarTouchData(
      enabled: true,
      touchCallback: (event, response){
        if (response != null && response.spot != null) {
          int dayIndex = response.spot!.touchedBarGroupIndex;
          String day = availableDays[dayIndex];
          widget.onDaySelected(day);
        }
      },
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.blueGrey,
        tooltipPadding: const EdgeInsets.all(8.0),
        tooltipMargin: 8.0,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          double totalHours = rod.toY;
          return BarTooltipItem(
            'Total Hours\n',
            const TextStyle(
              decoration: TextDecoration.none,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            children: [
              TextSpan(
              text: '${totalHours.toStringAsFixed(1)} hrs',
              style: const TextStyle(
                decoration: TextDecoration.none,
                color: Colors.white
                ),
            ),
          ],
        );
      },
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
              decoration: TextDecoration.none,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
                          decoration: TextDecoration.none,
                          fontSize: 10,
                          color: Colors.black,
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
                          decoration: TextDecoration.none,
                          fontSize: 10,
                          color: Colors.black,
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
              backgroundColor: Colors.white,
            )
          )
          ),
        ],
      )
    );
  }
}

class ExpandedListView extends StatefulWidget {
  final String selectedDay;
  final Map<String, Color> appColors;
  const ExpandedListView({super.key, required this.selectedDay, required this.appColors});
  @override
  State<ExpandedListView> createState() => _MyExpandedListViewState();
}

class _MyExpandedListViewState extends State<ExpandedListView> {
 @override
  Widget build(BuildContext context) {
    if (widget.selectedDay == "null") {
      return Center(
        child: Text(
          "Select a day to view",
          style: const TextStyle(
            decoration: TextDecoration.none,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          )
        ),
      );
    }

    if (!data.containsKey(widget.selectedDay)) {
      return Center(
        child: Text(
          "No data available for ${widget.selectedDay}",
          style: const TextStyle(
              decoration: TextDecoration.none,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            )
          )
        );
    }

    final dayData = data[widget.selectedDay]!;

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
