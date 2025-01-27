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
    home: Container(
      padding: EdgeInsets.all(4.0),
      child: Column(
        spacing: 4.0,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4.0),
              color: Colors.blue,
              child: GraphView(),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4.0),
              color: Colors.red,
              child: ExpandedListView(),
            ),
          ),
        ],
      ),

    )    
    );
  }
}
class GraphView extends StatefulWidget {
  const GraphView({super.key});
  @override
  State<GraphView> createState() => _MyGraphViewState();
}
class _MyGraphViewState extends State<GraphView> {
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

class ExpandedListView extends StatefulWidget {
  const ExpandedListView({super.key});
  @override
  State<ExpandedListView> createState() => _MyExpandedListViewState();
}
class _MyExpandedListViewState extends State<ExpandedListView> {
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
