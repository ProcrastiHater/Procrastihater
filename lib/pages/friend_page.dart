///*********************************
/// Name: historical_data_page.dart
///
/// Description: Historical Data page file for 
/// application
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
      title: const Text("ProcrastiFriends"),
      ),
    body: const Center(
      child: Text("Friend List")
    )
    );
  }
}
