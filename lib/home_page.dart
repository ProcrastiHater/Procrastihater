///*********************************
/// Name: home_page.dart
///
/// Description: Home page file for 
/// application, currently holds
/// current app usage
///
///*******************************

//Dart imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Firestore Connection Constants
final FirebaseFirestore FIRESTORE = FirebaseFirestore.instance;
final CollectionReference MAIN_COLLECTION = FIRESTORE.collection('UID');
final DocumentReference USER_REF = MAIN_COLLECTION.doc('123');

///*********************************
/// Name: HomePage
/// 
/// Description: Root stateless widget of 
/// the HomePage, builds and displays home page view
///*********************************
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
    home: MyHomePage(title: 'Home Page'),
    );
  }
}

///*********************************
/// Name: MyHomePage
/// 
/// Description: Stateful widget that 
/// manages the Firebase reading and writting
///*********************************
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

///*********************************
/// Name: MyHomePageState
/// 
/// Description: Manages state for MyHomePage, 
/// accesses screentime of phone through method
/// channels, checks and requests neccesary 
/// permissions, reads/write from firebase
///*********************************
class _MyHomePageState extends State<MyHomePage> {
  //Native Kotlin method channel
  static const screenTimeChannel = MethodChannel('kotlin.methods/screentime');
  //Maps for reading/writing data from the database
  Map<String, Map<String, String>> _screenTimeData = {};
  Map<String, Map<String, dynamic>> _firestoreScreenTimeData = {};
  //Permission variables for screen time usage permission
  bool _hasPermission = false;

  //Checks screen time usage permission on startup, starts timer for auto writing
  //Moves data from current to historical
  @override
  void initState(){
    super.initState();
    _checkPermission();
    _currentToHistorical();
  }

  //Cancels the timer
  @override
  void dispose() async {
    print("**********Disposing...***************");
    super.dispose();
  }

  ///*********************************
  /// Name: _checkPermission
  ///   
  /// Description: Invokes method from screentime channel 
  /// to check for screetime usage permissions
  ///*********************************
  Future<void> _checkPermission() async {
    try {
      final bool hasPermission = await screenTimeChannel.invokeMethod('checkPermission');
      setState(() {
        _hasPermission = hasPermission;
      });
    } on PlatformException catch (e) {
      print("Failed to check permission: ${e.message}");
    }
  }

  ///*********************************
  /// Name: _requestPermission
  ///   
  /// Description: Invokes method from screentime channel to 
  /// send a request for screentime usage permissions
  ///*********************************
  Future<void> _requestPermission() async {
    try {
      await screenTimeChannel.invokeMethod('requestPermission');
      await _checkPermission();
    } on PlatformException catch (e) {
      print("Failed to request permission: ${e.message}");
    }
  }
  
  ///*********************************
  /// Name: _getScreenTime
  ///   
  /// Description: Accesses screentime data
  /// by storing into a Map.
  ///*********************************
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
      print('Got screen time!');
    } on PlatformException catch (e) {
      print("Failed to get screen time: ${e.message}");
    }
  }

  ///*********************************
  /// Name: _fetchScreenTime
  ///   
  /// Description: Fetches screentime that has 
  /// been written into the Firestore database
  /// by accessing a hardcoded user
  ///*********************************
  // Future<void> _fetchScreenTime() async {
  //   try{
  //     //Hard coded user for accessing data
  //     final snapshot = await USER_REF.collection("appUsageCurrent").get();
  //     //Temp map for saving data from database
  //     Map<String, Map<String, dynamic>> fetchedData = {};
  //     //Loop to access all screentime data from hard coded user
  //     for (var doc in snapshot.docs){
  //       String docName = doc.id;
  //       double? hours = doc['dailyHours']?.toDouble();
  //       if (hours != null){
  //         fetchedData[docName]={'hours' : hours};
  //       }
  //     }
  //     //State for setting temp data to global map
  //       setState(() {
  //        _firestoreScreenTimeData = fetchedData;
  //       });
  //   } catch (e){
  //    print("error fetching screentime data: $e");
  //   }
  // }

  ///*******************************************************
  /// Name: _currentToHistorical
  ///
  /// Description: Moves data from the current collection to
  /// history in Firestore
  ///********************************************************
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

    //Create batch
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
    
      //Commit the batch
      await batch.commit();
      print('Successfully wrote screen time data to History');

      //Create batch for clearing current data
      batch = FIRESTORE.batch();

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
  }
  
  ///**************************************************
  /// Name: _writeScreenTimeData
  ///
  /// Description: Takes the data 
  /// that was accessed in _getScreenTime
  /// and writes it to the Firestore database 
  /// using batches for multiple writes
  ///***************************************************
  Future<void> _writeScreenTimeData() async
  {
    if(_screenTimeData.isNotEmpty){
      final userDB = USER_REF.collection('appUsageCurrent');
    
      // Create a batch to handle multiple writes
      final batch = FIRESTORE.batch();
      
      try {
        // Iterate through each app and its screen time
        for (final entry in _screenTimeData.entries) {
          final appName = entry.key;
          final screenTimeHours = double.parse(entry.value['hours']!);
          
          // Reference to the document with app name
          final docRef = userDB.doc(appName);
          
          // Set the data with merge option to update existing documents
          // or create new ones if they don't exist
          batch.set(
            docRef,
            {
              'dailyHours': screenTimeHours,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        // Commit the batch
        await batch.commit();
        print('Successfully wrote screentime data');
      } catch (e) {
        print('Error writing screen time data to Firestore: $e');
        rethrow;
      }
    }
  }

  ///**************************************************
  /// Name: _exit
  ///
  /// Description: Calls _writeScreenTimeData before
  /// exiting the app
  ///***************************************************
  void _exit() async
  {
    await _writeScreenTimeData();
    SystemNavigator.pop();
  }  

  ///**************************************************
  /// Name: _showBackDialog
  ///
  /// Description: Allows the user to confirm that they
  /// want to exit the app
  ///***************************************************
  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Leave'),
              onPressed: () {
                _exit();
              },
            ),
          ],
        );
      },
    );
  }

  ///********************************************************
  @override
  Widget build(BuildContext context) {
    //Prevents request permission from being called dozens of times
    if(!_hasPermission)
    {
      return Material(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _requestPermission,
                child: Text('Give Permissions')
              ),
              ElevatedButton(
                onPressed: SystemNavigator.pop, 
                child: Text('Exit')
              )
            ],
          ),
        ),
      );
    }
    if (_screenTimeData.isEmpty){
      _getScreenTime();
    }
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //If screentime was grabbed, print it
            if (_screenTimeData.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _screenTimeData.length,
                  itemBuilder: (context, index) {
                    final entry = _screenTimeData.entries.elementAt(index);
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${entry.value['hours']} hours'),
                      trailing: Text('${entry.value['category']}')
                    );
                  },
                ),
              ),
              //Ensure proper exit on back button pressed or exit button pressed.
              PopScope<Object?>
              (
                canPop: true,
                onPopInvokedWithResult: (bool didPop, Object? result) async {
                  if (didPop) {
                    return;
                  }
                  final bool shouldPop = await _showBackDialog() ?? false;
                  if (context.mounted && shouldPop) {
                    _exit();
                  }
                },
                child: ElevatedButton(
                  onPressed: _showBackDialog, 
                  child: Text('Exit')
                ),
              )
          ],
        ),
      ),
    );
  }
}