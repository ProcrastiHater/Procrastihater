///*********************************
/// Name: colors.dart
///
/// Description: Map colors to specific
/// app names for consistency
///*******************************
library;

//Dart Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//Page Imports
import '/main.dart';
import '/apps_list.dart';

//Global variables
Map<String, Color> appNameToColor = {}; 

///*********************************
/// Name: generateDistinctColors
///
/// Description: Generates a list of 
/// colors based on the amount of total
/// apps that the user has in database.
/// Uses goldenRatio constant and hue
/// to ensure distinctness
///*******************************
List<Color> generateDistinctColors(int count) {
  final List<Color> colors = [];
  const double goldenRatioConjugate = 0.618033988749895;
  double hue = 0;
  //Loop through every app user has in database
  for (int i = 0; i < count; i++) {
    //Increment hue by golden ratio and ensure in bounds
    hue = (hue + goldenRatioConjugate) % 1;
    //Use HSL with hue and fixed saturation/lightness
    final color = HSLColor.fromAHSL(1.0, hue * 360, 1.0, 0.5).toColor();
    colors.add(color);
  }
  return colors;
}

///*********************************
/// Name: initializeAppNameColorMapping
///
/// Description: Loads all apps the user
/// has stored in the database(historical 
/// and current) before mapping all apps 
/// to a distinct color provided by 
/// generateDistinctColor()
///*******************************
Future<void> initializeAppNameColorMapping() async {
    //Get distinct colors
    List<Color> distinctColors = generateDistinctColors(appNames.length);
    //Map colors to app name
    for (int i = 0; i < appNames.length; i++) {
      appNameToColor[appNames[i]] = distinctColors[i];
    }
}