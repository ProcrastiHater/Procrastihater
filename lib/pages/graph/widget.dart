///*********************************
/// Name: widget.dart
///
/// Description: Holds all the neccesary 
/// widgets for the building of graphs
///*******************************
library;

//Dart Imports
import 'package:app_screen_time/pages/graph/graph.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

//fl_chart imports
import 'package:fl_chart/fl_chart.dart';

//Page Imports
import '/pages/graph/fetch_data.dart';
import '/pages/graph/colors.dart';
import '/pages/friend_page.dart';
import '/main.dart';

//Global Variables
List<String> availableApps = screenTimeData.keys.toList();
List<String> availableDays = weeklyData.keys.toList();
List<String> categories = [ "Accessibility", "Games", "Maps & Navigation", "Movies & Video", "Music & Audio", "News & Magazines", "Other", "Photos & Images", "Productivity", "Social & Communication"];
List<String> filters = [ "Alphabet(asc)", "Alphabet(desc)", "Hours(asc)", "Hours(desc)"];
List<String> dayOrder = [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

///********************************
/// Name: generateWeeklyChart
/// 
/// Description: Generate a chart in 
/// week long segments with stacked bar
/// charts and colors for specific apps
///*********************************
List<BarChartGroupData> generateWeeklyChart(Map<String, Map<String, Map<String, dynamic>>> data) {
  //Return a list of bars for each day contain daily data
  return [
    for (int i= 0; i < availableDays.length; i++) 
      generatedWeeklyGroupData(i, data[availableDays[i]]!)
  ]; 
}

double tallestDayBar(Map<String, Map<String, Map<String, dynamic>>> data) {
  double tallestHeight = 0;
  for (int i = 0; i < data.length; i++) {
    Map<String, Map<String, dynamic>> dayData = data[availableDays[i]]!;
    double dayHeight = 0;
    for (var appName in dayData.keys) {
      dayHeight += dayData[appName]?['hours'] ?? 0.0;
    }
    if (tallestHeight < dayHeight) {
      tallestHeight = dayHeight;
    }
  }
  if (tallestHeight - tallestHeight.floor() > .5  || tallestHeight - tallestHeight.floor() == 0){
    tallestHeight = (tallestHeight + 1).ceilToDouble();
  }
  else{
    tallestHeight = tallestHeight.ceilToDouble();
  }
  return tallestHeight;
}


///*********************************
/// Name: generatedWeeklyGroupData
/// 
/// Description: Generate a stacked bar
/// for a stacked bar chart and return it
///*********************************
BarChartGroupData generatedWeeklyGroupData(int index, Map<String, Map<String, dynamic>> dailyData) {
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
    showingTooltipIndicators: [0],
    barRods: [
      BarChartRodData(
        fromY: 0,
        toY: cumulativeHeight, 
        rodStackItems: rodStackItems, 
        width: 35, 
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.0), 
          topRight: Radius.circular(8.0)),
      ),
    ],
  );
}

///********************************
/// Name: generateDailyChart
/// 
/// Description: Generate a chart in 
/// day long segements with apps as 
/// individual bars
///*********************************
List<BarChartGroupData> generateDailyChart(Map<String, Map<String, dynamic>> data) {
  return [
    for (int i= 0; i < data.length; i++) 
      generatedDayData(i, data.keys.toList()[i], data[data.keys.toList()[i]]!)
  ]; 
}

double tallestAppBar(Map<String, Map<String, dynamic>> data) {
  double tallestHeight = 0;
  for (int i = 0; i < data.length; i++) {
    Map<String, dynamic> appData = data[data.keys.toList()[i]]!;
    if (double.parse(appData['hours'] ?? 0.0) > tallestHeight)
    {
      tallestHeight = double.parse(appData['hours'] ?? 0.0);
    }
  }
    if (tallestHeight - tallestHeight.floor() > .5  || tallestHeight - tallestHeight.floor() == 0){
    tallestHeight = (tallestHeight + 1).ceilToDouble();
  }
  else{
    tallestHeight = tallestHeight.ceilToDouble();
  }
  return tallestHeight;
}

///*********************************
/// Name: generatedDayData
/// 
/// Description: Generate a bar with 
/// individual app data 
///*********************************
BarChartGroupData generatedDayData(int index, String appName,Map<String, dynamic> appData) {
  //Return individual bars with data
  return BarChartGroupData(
    x: index,
    showingTooltipIndicators: [0],
    barRods: [
      BarChartRodData(
        fromY: 0,
        toY: double.parse(appData['hours'] ?? 0.0),
        width: 35, 
        color: appNameToColor[appName],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.0), 
          topRight: Radius.circular(8.0)),
      ),
    ],
  );
}

///*********************************
/// Name: getBarDayTouch
/// 
/// Description: Displays all the app
/// information as a tooltip when 
/// selecting a bar
///*********************************
BarTouchData getBarDayTouch(Map<String, Map<String, String>> data) {
  return BarTouchData(
    enabled: true,
    //Loads app data on touch of specific bar
    touchTooltipData: BarTouchTooltipData(
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipColor: (group) => Colors.transparent,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin: -10,
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        String totalHours = rod.toY.toStringAsFixed(2);        
        return BarTooltipItem(
          "$totalHours\n",
          const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      },
    )
  );
}

///*********************************
/// Name: getBarWeekTouch
/// 
/// Description: Display a tooltip with 
/// the total number of hours in the day
/// associated with the touched bar and
/// loads listview of daily data
///*********************************
BarTouchData getBarWeekTouch(Map<String, Map<String, Map<String, dynamic>>> data, void Function(String) onDaySelected) {
return BarTouchData(
    enabled: true,
    touchExtraThreshold: const EdgeInsets.only(top: 300),
    //Reads touch and updates the selectedDay to load list view
    touchCallback: (event, response){
      if (response != null && response.spot != null) {
        int dayIndex = response.spot!.touchedBarGroupIndex;
        String day = availableDays[dayIndex];
        onDaySelected(day);
      }
    },
    //Loads app data on touch of specific bar
    touchTooltipData: BarTouchTooltipData(
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipColor: (group) => Colors.transparent,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin: -10,
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        String totalHours = rod.toY.toStringAsFixed(2);
        return BarTooltipItem(
          "$totalHours\n",
          const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      },
    )
  );
}

///*********************************
/// Name: bottomDailyTiles
/// 
/// Description: Widget to load app
/// names of apps when daily view is selected
///*********************************
Widget bottomAppTitles(double value, TitleMeta meta) {
  const style = TextStyle(
    decoration: TextDecoration.none,
    fontSize: 10.0, 
  );
  String text = availableApps[value.toInt()];
  return SideTitleWidget(
    meta: meta,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 70),
          child: Text(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text, 
        style: style
      )
        )
      ]
    )
  );
}

///*********************************
/// Name: bottomWeeklyTiles
/// 
/// Description: Widget to load days for 
/// when weekly view is selected
///*********************************
Widget bottomDayTitles(double value, TitleMeta meta) {
  const style = TextStyle(
    decoration: TextDecoration.none,
    fontSize: 10.0, 
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
    ' ${value.toStringAsFixed(0)}',
  );
}