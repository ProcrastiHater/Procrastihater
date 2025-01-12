// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseFirestore FIRESTORE = FirebaseFirestore.instance;
final CollectionReference MAIN_COLLECTION = FIRESTORE.collection('UID');
final DocumentReference USER_REF = MAIN_COLLECTION.doc('123');

/*****************************************************
* Name: UsageSyncPage
* 
* Description: Page to test account-to-db synchronization
*
* Members: Inherited from StatelessWidget
*
* Methods: Inherited from StatelessWidget
******************************************************/
class UsageSyncPage extends StatelessWidget {
  const UsageSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      appBar: AppBar
      (
        title: const Text('Today\'s App Usage'),
      ),
      body: const AppUsageSync()
    );
  }
}

class AppUsageSync extends StatefulWidget {
  const AppUsageSync({super.key});

  @override
  State<AppUsageSync> createState() => _AppUsageSyncState();
}

class _AppUsageSyncState extends State<AppUsageSync> {
  static const screenTimeChannel = MethodChannel('kotlin.methods/screentime');
  
  Map<String, double> _screenTimeData = {};
  Map<String, double> _firestoreScreenTimeData = {};
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final bool HAS_PERMISSION = await screenTimeChannel.invokeMethod('checkPermission');
      setState(() {
        _hasPermission = HAS_PERMISSION;
      });
    } on PlatformException catch (e) {
      print("Failed to check permission: ${e.message}");
    }
  }

  Future<void> _requestPermission() async {
    try {
      await screenTimeChannel.invokeMethod('requestPermission');
      await _checkPermission();
    } on PlatformException catch (e) {
      print("Failed to request permission: ${e.message}");
    }
  }

  Future<void> _getScreenTime() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    try {
      final Map<dynamic, dynamic> result = await screenTimeChannel.invokeMethod('getScreenTime');
      setState(() {
        _screenTimeData = Map<String, double>.from(
          result.map((key, value) => MapEntry(key as String, (value as double))),
        );
      });
    } on PlatformException catch (e) {
      print("Failed to get screen time: ${e.message}");
    }
  }

  Future<Map<String,double>> _grabScreenTime() async{
    if(!_hasPermission){
      await _requestPermission();
    }

    try {
      final Map<dynamic, dynamic> result = await screenTimeChannel.invokeMethod('getScreenTime');
      setState(() {
        _screenTimeData = Map<String, double>.from(
          result.map((key, value) => MapEntry(key as String, (value as double))),
        );
      });
    } on PlatformException catch (e) {
      print("Failed to get screen time: ${e.message}");
    }
    return _screenTimeData;
  }

  Future<void> _fetchScreenTime() async {
    try{
      final snapshot = await USER_REF.collection("appUsageCurrent").get();
      Map<String, double> fetchedData = {};
      for (var doc in snapshot.docs){
        String docName = doc.id;
        double? hours = doc['dailyHours']?.toDouble();
        if (hours != null){
          fetchedData[docName] = hours;
        }
      }
        setState(() {
          _firestoreScreenTimeData = fetchedData;
        });
    } catch (e){
      print("error fetching screentime data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    _getScreenTime();
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_screenTimeData.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _screenTimeData.length,
                  itemBuilder: (context, index) {
                    final entry = _screenTimeData.entries.elementAt(index);
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${entry.value} hours'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}