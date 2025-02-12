///*********************************
/// Name: fetchHistorical.dart
///
/// Description: Map colors to specific
/// app names for consistency
///*******************************

//Dart Imports
import 'package:flutter/material.dart';

//fl_chart imports
import 'package:fl_chart/fl_chart.dart';

//Page Imports
import '/pages/graph/fetchHistorical.dart';
import '/pages/graph/colors.dart';
import '/pages/historical_data_page.dart';


//Global Variables
List<String> availableDays = data.keys.toList(); 


List<BarChartGroupData> generateWeeklyChart(Map<String, Map<String, Map<String, dynamic>>> data) {
  for (int i = 0; i < availableDays.length; i++) {
    mapColors(data[availableDays[i]]!);
  }
  return [
    for (int i = 0; i < availableDays.length; i++) 
      generatedGroupData(i, data[availableDays[i]]!)
  ]; 
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

BarTouchData getBarTouch(Map<String, Map<String, Map<String, dynamic>>> data, void Function(String) onDaySelected) {
    return BarTouchData(
      enabled: true,
      touchCallback: (event, response){
        if (response != null && response.spot != null) {
          int dayIndex = response.spot!.touchedBarGroupIndex;
          String day = availableDays[dayIndex];
          onDaySelected(day);
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