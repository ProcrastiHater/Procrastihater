///*********************************
/// Name: calendar.dart
///
/// Description: 
///*******************************
library;

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///*********************************
/// Name: CalendarPage
/// 
/// Description:
///*********************************
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Calendar"),
        ),
        body: Center(child: Text("Calendar")),
      );
  }
}