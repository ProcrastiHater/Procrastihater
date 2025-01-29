///*********************************
/// Name: social_media_page.dart
///
/// Description: Social Media page file for
/// application
///*******************************

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firenbase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Additional Imports
import 'package:graphic/graphic.dart';

import 'home_page.dart';

///*********************************
/// Name: SocialMediaPage
///
/// Description: Root stateless widget of
/// the SocialMediaPage, builds and displays
/// social media page view
/// Temporary residence of the daily app usage graph
///*********************************
class SocialMediaPage extends StatefulWidget {
  const SocialMediaPage({Key? key}) : super(key: key);
  @override
  State<SocialMediaPage> createState() => _SocialMediaPageState();
}

//TODO: restrict the size of the chart
class _SocialMediaPageState extends State<SocialMediaPage> {
  List<Map<String, dynamic>> chartData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ///**************************************************
  /// Name: _loadData
  ///
  /// Description: calls _fetchscreentime and converts
  /// screentime data into a list of maps to be used by
  /// the graphic plugin
  ///***************************************************
  Future<void> _loadData() async {
    try {
      //Get screentime data
      final data = await _fetchScreenTime();

      final transformedData = data.entries
          .map((entry) => {
                'App Name': entry.key,
                'Hours': entry.value['Hours'],
                'category': entry.value['category']
              })
          .toList();

      setState(() {
        chartData = transformedData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading screen time data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Daily App Usage'),
            ),
            body: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 400,
              height: 400,
              child: Chart(
                data: chartData,
                variables: {
                  'App Name': Variable(
                    accessor: (Map map) => map['App Name'] as String,
                  ),
                  'Hours': Variable(
                    accessor: (Map map) => map['Hours'] as num,
                  ),
                },
                marks: [
                  IntervalMark(
                    label: LabelEncode(
                      encoder: (tuple) => Label(tuple['Hours'].toString()),
                    ),
                    elevation: ElevationEncode(
                      value: 0,
                      updaters: {
                        'tap': {true: (_) => 5}
                      },
                    ),
                    color: ColorEncode(
                      value: const Color(0xFFFF8C00),
                      updaters: {
                        'tap': {false: (color) => color.withAlpha(100)},
                      },
                    ),
                  ),
                ],
                axes: [
                  Defaults.horizontalAxis,
                  Defaults.verticalAxis,
                ],
                selections: {'tap': PointSelection(dim: Dim.x)},
                tooltip: TooltipGuide(),
                crosshair: CrosshairGuide(),
              ),
            )));
  }
}

///**************************************************
/// Name: _fetchScreenTime
///
/// Description: Takes the data
/// from the Firestore database
/// and returns a map of maps
/// of the user's current screentime
///***************************************************
Future<Map<String, Map<String, dynamic>>> _fetchScreenTime() async {
  _updateUserRef();
  Map<String, Map<String, dynamic>> fetchedData = {};
  try {
    final CURRENT = userRef.collection("appUsageCurrent");
    final CUR_SNAPSHOT = await CURRENT.get();
    //Temp map for saving data from database
    //Loop to access all screentime data from hard coded user
    for (var doc in CUR_SNAPSHOT.docs) {
      String docName = doc.id;
      double? hours = doc['dailyHours']?.toDouble();
      String category = doc['appType'];
      if (hours != null) {
        fetchedData[docName] = {'Hours': hours, 'category': category};
      }
    }
  } catch (e) {
    print("error fetching screentime data: $e");
  }
  return fetchedData;
}

///**************************************************
/// Name: _updateUserRef
///
/// Description: Updates userRef to doc if the UID has changed
///***************************************************
void _updateUserRef() {
  //Grab current UID
  var curUid = uid;
  //Regrab UID in case it's changed
  uid = AUTH.currentUser?.uid;
  //Update user reference if UID has changed
  if (curUid != uid) {
    userRef = MAIN_COLLECTION.doc(uid);
  }
}
