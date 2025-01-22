///*********************************
/// Name: historical_data_page.dart
///
/// Description: Historical Data page file for 
/// application
///
///*******************************

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//fl_chart imports
import 'package:fl_chart/fl_chart.dart';


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
    home: Scaffold(
      appBar: AppBar(title: const Text("Historical Data Page")),
      body: MyHistoricalDataPage(),
      ),      
    );
  }
}
class MyHistoricalDataPage extends StatefulWidget {
  const MyHistoricalDataPage({super.key});
  @override
  State<MyHistoricalDataPage> createState() => _MyHistoricalDataPageState();
}
class _MyHistoricalDataPageState extends State<MyHistoricalDataPage> {
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