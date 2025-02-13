///*********************************
/// Name: colors.dart
///
/// Description: Map colors to specific
/// app names for consistency
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';

//Global variables
Map<String, Color> appNameToColor = {}; 

///*********************************
/// Name: mapColors
/// 
/// Description: Takes the apps passed in through
/// dailyData and maps it to a list of 20 
/// distinct colors
///*********************************
void mapColors(Map<String, Map<String, dynamic>> dailyData) {
  final List<Color> appColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
      Colors.cyan,
      Colors.indigo,
      Colors.lime,
      Colors.teal,
      Colors.amber,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.blueGrey,
      Colors.black,
    ];
    //Creates a list of app names from dailyData map
    final appNames = dailyData.keys.toList();
    //Maps colors to app names in the order of the list and map
    for (int i = 0; i < appNames.length; i++) {
      appNameToColor[appNames[i]] = appColors[i % appColors.length];
    } 
}