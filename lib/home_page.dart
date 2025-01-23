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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//Firestore Connection Variables
final FirebaseAuth AUTH = FirebaseAuth.instance;
final FirebaseFirestore FIRESTORE = FirebaseFirestore.instance;
final CollectionReference MAIN_COLLECTION = FIRESTORE.collection('UID');
String? uid = AUTH.currentUser?.uid;
//Reference to user's document in Firestore
DocumentReference userRef = MAIN_COLLECTION.doc(uid);

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
  //Permission variables for screen time usage permission
  bool _hasPermission = false;

  ///*******************************
  ///Checks screen time usage permission on startup
  @override
  void initState(){
    super.initState();
    _checkPermission();
    //Moves data from current to historical
    _currentToHistorical();
  }

  ///*******************************
  @override
  void dispose() async {
    debugPrint("**********Disposing...***************");
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
      debugPrint("Failed to check permission: ${e.message}");
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
      debugPrint("Failed to request permission: ${e.message}");
    }
  }
  
  ///*********************************
  /// Name: _getScreenTime
  ///   
  /// Description: Accesses screentime data
  /// by storing into a Map.
  ///*********************************
  Future<void> _getScreenTime() async {
    //Checks if user has permission, if not it requests the permissions
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    try {
      //Raw data from screentime channel 
      final Map<dynamic, dynamic> result = await screenTimeChannel.invokeMethod('getScreenTime');
      //State for writing raw data in formatted map
      setState(() {
        _screenTimeData = Map<String, Map<String, String>>.from(
          result.map((key, value) => MapEntry(key as String, Map<String, String>.from(value))),
        );
      });
      debugPrint('Got screen time!');
    } on PlatformException catch (e) {
      debugPrint("Failed to get screen time: ${e.message}");
    }
  }

  ///*******************************************************
  /// Name: _currentToHistorical
  ///
  /// Description: Moves data from the current collection to
  /// history in Firestore
  ///********************************************************
  Future<void> _currentToHistorical() async {
    _updateUserRef();

    //Temp map for saving current data from database
    Map<String, Map<String, dynamic>> fetchedData = {};

    //Grab data from current
    try{
      final CURRENT = userRef.collection('appUsageCurrent');
      final CUR_SNAPSHOT = await CURRENT.get();
      //Loop to access all current screentime data from user
      for (var doc in CUR_SNAPSHOT.docs){
        String docName = doc.id;
        double? hours = doc['dailyHours']?.toDouble();
        Timestamp timestamp = doc['lastUpdated'];
        String category = doc['appType'];
        if (hours != null){
          fetchedData[docName] = {'dailyHours': hours, 'lastUpdated': timestamp, 'appType': category};
        }
      }
    } catch (e){
      debugPrint("error fetching screentime data: $e");
    }

    //Create batch
    var batch = FIRESTORE.batch();

    try {
      // Iterate through each app and its screen time
      for (var appMap in fetchedData.entries) {
        double screenTimeHours = appMap.value['dailyHours'];
        Timestamp timestamp = appMap.value['lastUpdated'];
        String category = appMap.value['appType'];
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
          var historical = userRef.collection('appUsageHistory').doc(startOfWeek);

          // Move data to historical
          batch.set(
            historical,
            {
              dayOfWeekStr: {
                appMap.key: {
                  'hours': screenTimeHours,
                  'lastUpdated': dateUpdated,
                  'appType': category
                }
              }
            },
            SetOptions(merge: true),
          );
        }
      }
    
      //Commit the batch
      await batch.commit();
      debugPrint('Successfully wrote screen time data to History');

      //Create batch for clearing current data
      batch = FIRESTORE.batch();

      final CUR_SNAPSHOT = await userRef.collection('appUsageCurrent').get();
      
      //Clear current app usage
      for(var doc in CUR_SNAPSHOT.docs)
      {
        await doc.reference.delete();
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error writing screen time data to Firestore: $e');
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
    //Update ref to user's doc if UID has changed
    _updateUserRef();

    if(_screenTimeData.isNotEmpty){
      final current = userRef.collection('appUsageCurrent');
    
      // Create a batch to handle multiple writes
      final batch = FIRESTORE.batch();
      
      try {
        // Iterate through each app and its screen time
        for (final entry in _screenTimeData.entries) {
          final appName = entry.key;
          final screenTimeHours = double.parse(entry.value['hours']!);
          final category = entry.value['category'];
          
          // Reference to the document with app name
          final docRef = current.doc(appName);
          
          // Set the data with merge option to update existing documents
          // or create new ones if they don't exist
          batch.set(
            docRef,
            {
              'dailyHours': screenTimeHours,
              'lastUpdated': FieldValue.serverTimestamp(),
              'appType': category
            },
            SetOptions(merge: true),
          );
        }
        // Commit the batch
        await batch.commit();
        debugPrint('Successfully wrote screentime data');
      } catch (e) {
        debugPrint('Error writing screen time data to Firestore: $e');
        rethrow;
      }
    }
  }
 
  ///**************************************************
  /// Name: _signOut
  ///
  /// Description: Calls _writeScreenTimeData before
  /// signing user out of the app
  ///***************************************************
  void _signOut() async
  {
    await _writeScreenTimeData();
    AUTH.signOut();
  }

  ///**************************************************
  /// Name: _updateUserRef
  ///
  /// Description: Updates userRef to doc if the UID has changed
  ///***************************************************
  void _updateUserRef()
  {
    //Grab current UID
    var curUid = uid;
    //Regrab UID in case it's changed
    uid = AUTH.currentUser?.uid;
    //Update user reference if UID has changed
    if(curUid != uid)
    {
      userRef = MAIN_COLLECTION.doc(uid);
    }
  }

  ///********************************************************
  @override
  Widget build(BuildContext context) {
    //Prevents request permission from being called dozens of times
    if(!_hasPermission)
    {
      return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Creating little user icon you can press to view account info
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      })
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _requestPermission,
                child: Text('Give Permissions')
              ),
              ElevatedButton.icon(
                label: Text("Sign Out"),
                onPressed: _signOut,
                icon: Icon(
                  Icons.logout,
                  size: 24,
                ),
              )
            ],
          ),
        ),
      );
    }
    //Only grab screen time if the map for it is empty
    if (_screenTimeData.isEmpty){
      _getScreenTime();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Creating little user icon you can press to view account info
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      })
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Center(
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
              //Custom sign-out button
              ElevatedButton.icon(
                label: Text("Sign Out"),
                onPressed: _signOut,
                icon: Icon(
                  Icons.logout,
                  size: 24,
                ),
              )
          ],
        ),
      ),
    );
  }
}