///*********************************
/// Name: colors.dart
///
/// Description: Map colors to specific
/// app names for consistency
///*******************************

//Dart Imports
import 'package:flutter/material.dart';

//Global variables
Map<String, Color> appNameToColor = {}; 
const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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
    final appNames = dailyData.keys.toList();
    for (int i = 0; i < appNames.length; i++) {
      appNameToColor[appNames[i]] = appColors[i % appColors.length];
    } 
}