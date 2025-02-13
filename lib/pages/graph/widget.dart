///*********************************
/// Name: widget.dart
///
/// Description: Holds all the neccesary 
/// widgets for the building of graphs
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';

//fl_chart imports
import 'package:fl_chart/fl_chart.dart';

//Page Imports
import 'fetch_data.dart';
import '/pages/graph/colors.dart';
import '../friend_page.dart';

//Global Variables
List<String> availableDays = historicalData.keys.toList(); 

///*********************************
/// Name: generateWeeklyChart
/// 
/// Description: Generate a chart in 
/// week long segments with stacked bar
/// charts and colors for specific apps
///*********************************
List<BarChartGroupData> generateWeeklyChart(Map<String, Map<String, Map<String, dynamic>>> data) {
  //Loop through each day and make sure the proper color is assigned to proper app
  for (int i = 0; i < availableDays.length; i++) {
    mapColors(data[availableDays[i]]!);
  }
  //Return a list of bars for each day contain daily data
  return [
    for (int i = 0; i < availableDays.length; i++) 
      generatedGroupData(i, data[availableDays[i]]!)
  ]; 
}

///*********************************
/// Name: generatedGroupData
/// 
/// Description: Generate a stacked bar
/// for a stacked bar chart and return it
///*********************************
BarChartGroupData generatedGroupData(int index, Map<String, Map<String, dynamic>> dailyData) {
  //List to hold individual stack item(rod)
  List<BarChartRodStackItem> rodStackItems = [];
  double cumulativeHeight = 0;
  //Add each app to the bar with the hours and color associated with it
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
  
  //Returns the entire stacked bar
  return BarChartGroupData(
    x: index,
    barRods: [
      BarChartRodData(
        fromY: 0,
        toY: cumulativeHeight, 
        rodStackItems: rodStackItems, 
        width: 15, 
        borderRadius: BorderRadius.circular(5),
      ),
    ],
  );
}

///*********************************
/// Name: getBarTouch
/// 
/// Description: Display a tooltip with 
/// the total number of hours in the day
/// associated with the touched bar and
/// loads listview of daily data
///*********************************
BarTouchData getBarTouch(Map<String, Map<String, Map<String, dynamic>>> data, void Function(String) onDaySelected) {
  return BarTouchData(
    enabled: true,
    //Reads touch and updates the selectedDay to load list view
    touchCallback: (event, response){
      if (response != null && response.spot != null) {
        int dayIndex = response.spot!.touchedBarGroupIndex;
        String day = availableDays[dayIndex];
        onDaySelected(day);
      }
    },
    //Loads tooltip containing total hours for the day
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
///*********************************
/// Name: bottomTiles
/// 
/// Description: Widget to load bottom 
/// tiles of graph
///*********************************
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

///*********************************
/// Name: sideTitles
/// 
/// Description: Widget to load side
/// titles of graph
///*********************************
Widget sideTitles(double value, TitleMeta meta) {
  return Text(
    value.toStringAsFixed(1),
    style: const TextStyle(
      decoration: TextDecoration.none,
      fontSize: 10,
      color: Colors.black,
    ),
  );
}