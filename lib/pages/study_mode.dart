///*********************************
/// Name: study_mode.dart
///
/// Description: 
///*******************************
library;

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///*********************************
/// Name: StudyModePage
/// 
/// Description:
///*********************************
class StudyModePage extends StatelessWidget {
  const StudyModePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Study Mode"),
        ),
        body: Center(child: Text("Study Mode")),
      );
  }
}