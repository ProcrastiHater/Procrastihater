// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

final FirebaseFirestore FIRESTORE = FirebaseFirestore.instance;
final CollectionReference MAIN_COLLECTION = FIRESTORE.collection('UID');
final DocumentReference USER_REF = MAIN_COLLECTION.doc('123');

/*****************************************************
* Name: UsageSyncPage
*
* Description: Page to test account-to-database synchronization
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

  Map<String, Map<String, String>> _screenTimeData = {};
  Map<String, Map<String, dynamic>> _firestoreScreenTimeData = {};
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    //_currentToHistorical();
  }

  /*********************************************************
  * Name: _checkPermission
  *
  * Description: Calls the kotlin method for seeing
  *              if the user has granted permission for accessing
  *              screentime data
  *
  **********************************************************/
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

  /*********************************************************
  * Name: _requestPermission
  *
  * Description: Calls the kotlin method for requesting permission
  *              to access the user's screentime data
  *
  **********************************************************/
  Future<void> _requestPermission() async {
    try {
      await screenTimeChannel.invokeMethod('requestPermission');
      await _checkPermission();
    } on PlatformException catch (e) {
      print("Failed to request permission: ${e.message}");
    }
  }

  /*********************************************************
  * Name: _getScreenTime
  *
  * Description: Calls the kotlin method for getting screentime
  *              data and puts the result in a Map for later use
  *
  **********************************************************/
  Future<void> _getScreenTime() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    try {
      final Map<dynamic, dynamic> result = await screenTimeChannel.invokeMethod('getScreenTime');
      setState(() {
        _screenTimeData = Map<String, Map<String, String>>.from(
          result.map((key, value) => MapEntry(key as String, Map<String, String>.from(value))),
        );
      });
    } on PlatformException catch (e) {
      print("Failed to get screen time: ${e.message}");
    }
  }

  // /*********************************************************
  // * Name: _fetchScreenTime
  // *
  // * Description: Gets the screentime data from the database and
  // *              puts it in a Map for later use
  // *
  // **********************************************************/
  // Future<void> _fetchScreenTime() async {
  //   try{
  //     final snapshot = await USER_REF.collection('appUsageCurrent').get();
  //     Map<String, double> fetchedData = {};
  //     for (var doc in snapshot.docs){
  //       String docName = doc.id;
  //       double? hours = doc['dailyHours']?.toDouble();
  //       if (hours != null){
  //         fetchedData[docName] = hours;
  //       }
  //     }
  //       setState(() {
  //         _firestoreScreenTimeData = fetchedData;
  //       });
  //   } catch (e){
  //     print("error fetching screentime data: $e");
  //   }
  // }

  /*********************************************************
  * Name: _currentToHistorical
  *
  * Description: Moves data from appUsageCurrent to
  *              appUsageHistory
  *
  **********************************************************/
  Future<void> _currentToHistorical() async {
    //Grab data from current
    Map<String, Map<String, dynamic>> fetchedData = {};
    try{
      final CURRENT = USER_REF.collection('appUsageCurrent');
      final CUR_SNAPSHOT = await CURRENT.get();
      for (var doc in CUR_SNAPSHOT.docs){
        String docName = doc.id;
        double? hours = doc['dailyHours']?.toDouble();
        Timestamp timestamp = doc['lastUpdated'];
        if (hours != null){
          fetchedData[docName] = {'dailyHours': hours, 'lastUpdated': timestamp};
        }
      }
    } catch (e){
      print("error fetching screentime data: $e");
    }

    var batch = FIRESTORE.batch();

    try {
      // Iterate through each app and its screen time
      for (var entry in fetchedData.entries) {
        var appName = entry.key;
        var screenTimeHours = entry.value['dailyHours'];
        Timestamp timestamp = entry.value['lastUpdated'];
        // Reference to the document with app name
        DateTime dateUpdated = timestamp.toDate();
        DateTime currentTime = DateTime.now();
        //Check if date has changed since database was updated
        if(dateUpdated.day != currentTime.day
         || dateUpdated.month != currentTime.month
         || dateUpdated.year != currentTime.year){
          //Gets the number of the day of the week for the last update day
          int dayOfWeekNum = dateUpdated.weekday;
          //Gets the name of the day of the week for last update day
          String dayOfWeekStr = DateFormat('EEEE').format(dateUpdated);
          //Gets the start of that week
          String startOfWeek = DateFormat('MM-dd-yyyy').format(dateUpdated.subtract(Duration(days: dayOfWeekNum-1)));
          var historical = USER_REF.collection('appUsageHistory').doc(startOfWeek);

          // Move data to historical
          batch.set(
            historical,
            {
              dayOfWeekStr: {
                appName: {
                  'dailyHours': screenTimeHours,
                  'lastUpdated': dateUpdated,
                }
              }
            },
            SetOptions(merge: true),
          );
        }
      }
      await batch.commit();
      print('Successfully wrote screen time data to History');

      batch = FIRESTORE.batch();
      // Commit the batch
      final CUR_SNAPSHOT = await USER_REF.collection('appUsageCurrent').get();
      //Clear current app usage
      for(var doc in CUR_SNAPSHOT.docs)
      {
        await doc.reference.delete();
      }
      await batch.commit();
    } catch (e) {
      print('Error writing screen time data to Firestore: $e');
      rethrow;
    }
    setState(() {
      _firestoreScreenTimeData = fetchedData;
    });
  }

  /****************************************************/
  @override
  Widget build(BuildContext context) {
    if (_firestoreScreenTimeData.isEmpty){
      _currentToHistorical();
      //_getScreenTime();
    }
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // if (_screenTimeData.isNotEmpty)
            //   Expanded(
            //     child: ListView.builder(
            //       itemCount: _screenTimeData.length,
            //       itemBuilder: (context, index) {
            //         final entry = _screenTimeData.entries.elementAt(index);
            //         return ListTile(
            //           title: Text(entry.key),
            //           subtitle: Text('${entry.value['hours']} hours'),
            //           trailing: Text('${entry.value['category']}')
            //         );
            //       },
            //     ),
            //   ),
            if (_firestoreScreenTimeData.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _firestoreScreenTimeData.length,
                  itemBuilder: (context, index) {
                    final entry = _firestoreScreenTimeData.entries.elementAt(index);
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${entry.value['lastUpdated'].toString()}'),
                      trailing: Text('${entry.value['dailyHours']} hours')
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