///*********************************
/// Name: main.dart
///
/// Description: Entry point for main app,
/// initializes firebase, handles authentication
/// and sets up main structure of app
///*******************************
library;

//Dart Imports
import 'dart:async';
import 'dart:io';
import 'package:app_screen_time/notification_service.dart';
import 'package:app_screen_time/notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//Page Imports
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/friend_page.dart';
import 'profile/login_screen.dart';

//Global Variables 
//Native Kotlin method channel
const screenTimeChannel = MethodChannel('kotlin.methods/screentime');
//Maps for reading/writing data from the database
Map<String, Map<String, String>> _screenTimeData = {};
//Permission variables for screen time usage permission
bool _hasPermission = false;

//Firestore Connection Variables
final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;
final CollectionReference mainCollection = firestore.collection('UID');
String? uid = auth.currentUser?.uid;
//Reference to user's document in Firestore
DocumentReference userRef = mainCollection.doc(uid);


///*********************************
/// Name: main
/// 
/// Description: Initializes Firebase,
/// 
/// launches the main app
///*********************************
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Firebase initialization
  await Firebase.initializeApp();
  //launch the main app
  _currentToHistorical().whenComplete(() {
    _checkPermission().whenComplete((){
      _getScreenTime().whenComplete((){
        _writeScreenTimeData();
          });
        }
      );
    }
  );
  
  runApp(const LoginScreen());
}

///*********************************
/// Name: MyApp
/// 
/// Description: Root stateless widget of 
/// the app, builds and displays main page view
///*********************************
class ProcrastiHater extends StatelessWidget {
  const ProcrastiHater({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyPageView()
    );
  } 
}

///*********************************
/// Name: MyPageView
/// 
/// Description: Stateful widget that 
/// manages the PageView for app navigation
///*********************************
class MyPageView extends StatefulWidget {
  const MyPageView({super.key});
  @override
  State<MyPageView> createState() => _MyPageViewState();
}
///*********************************
/// Name: MyPageViewState
/// 
/// Description: Manages state for MyPageView, 
/// sets up PageView controller, tracks current
/// page, and handles navigation
///*********************************
class _MyPageViewState extends State<MyPageView> {
  //Controller for page navigation
  late PageController _pageController;
  
  //Tracks current index
  int currentPage = 0;

  //Initialize page controller and set initial page
  @override
  void initState() {
    _pageController = PageController(initialPage: 1);
    currentPage = 1;
    //NotificationService.initialize();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //PageView widget for navigation
      body: PageView(
        controller: _pageController,
        //Update current page index on page change
        onPageChanged: (index) {
        setState(() {
          currentPage = index; 
        });
        },
        //Pages to display
        children: const [
          SocialMediaPage(),
          HomePage(),
          HistoricalDataPage(),
        ],
      )
      
    );
  }
}

///**************************************************
/// Name: _updateUserRef
///
/// Description: Updates userRef to doc if the UID has changed
///***************************************************
void updateUserRef() {
  //Grab current UID
  
  var curUid = uid;
  //Regrab UID in case it's changed
  uid = auth.currentUser?.uid;
  //Update user reference if UID has changed
  if(curUid != uid){
    userRef = mainCollection.doc(uid);
  }
}

///*******************************************************
/// Name: _currentToHistorical
///
/// Description: Moves data from the current collection to
/// history in Firestore
///********************************************************
Future<void> _currentToHistorical() async {
  updateUserRef();

  //Temp map for saving current data from database
  Map<String, Map<String, dynamic>> fetchedData = {};

  DateTime currentTime = DateTime.now();
  DateTime dateUpdated;
  bool needToMoveData = false;
  //Grab data from current
  try{
    final current = userRef.collection('appUsageCurrent');
    final curSnapshot = await current.get();
    //Loop to access all current screentime data from user
    for (var doc in curSnapshot.docs){
      String docName = doc.id;
      double? hours = doc['dailyHours']?.toDouble();
      Timestamp timestamp = doc['lastUpdated'];
      dateUpdated = timestamp.toDate();
      String category = doc['appType'];
      if (hours != null){
        fetchedData[docName] = {'dailyHours': hours, 'lastUpdated': timestamp, 'appType': category};
      }
      //Check if any data needs to be written to history
      if (dateUpdated.day != currentTime.day
        || dateUpdated.month != currentTime.month
        || dateUpdated.year != currentTime.year) {
        needToMoveData = true;
      }
    }
  } catch (e){
    debugPrint("error fetching screentime data: $e");
  }

  //If any data needs to be written to history
  if(needToMoveData) {
    //Create batch
    var batch = firestore.batch();
    double totalDaily = 0.0;
    double totalWeekly = 0.0;
    DocumentSnapshot<Map<String, dynamic>>? histSnapshot;
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
        || dateUpdated.year != currentTime.year) {
          //Gets the number of the day of the week for the last update day
          int dayOfWeekNum = dateUpdated.weekday;
          //Gets the name of the day of the week for last update day
          String dayOfWeekStr = DateFormat('EEEE').format(dateUpdated);
          //Gets the start of that week
          String startOfWeek = DateFormat('MM-dd-yyyy').format(dateUpdated.subtract(Duration(days: dayOfWeekNum-1)));
          var historical = userRef.collection('appUsageHistory').doc(startOfWeek);
          histSnapshot ??= await historical.get();
          if(totalWeekly == 0 && histSnapshot.data() != null && histSnapshot.data()!.containsKey('totalWeeklyHours')) {
            totalWeekly = histSnapshot['totalWeeklyHours'];
          }
          totalDaily += screenTimeHours;
          totalWeekly += screenTimeHours;
          // Move data to historical
          batch.set(
            historical,
            {
              dayOfWeekStr: {
                appMap.key: {
                  'hours': screenTimeHours,
                  'lastUpdated': dateUpdated,
                  'appType': category
                },
                'totalDailyHours': (totalDaily * 100).round() / 100
              },
              'totalWeeklyHours': (totalWeekly * 100).round() / 100
            },
            SetOptions(merge: true),
          );
        }
      }
    
      //Commit the batch
      await batch.commit();
        
      debugPrint('Successfully wrote screen time data to History');
    } catch (e) {
      debugPrint('Error writing screen time data to Firestore: $e');
      rethrow;
    }
  }
  else{
    debugPrint('No data needed to be written to history');
  }
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
    //setState(() {
      _hasPermission = hasPermission;
   // });
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
    //setState(() {
      _screenTimeData = Map<String, Map<String, String>>.from(
        result.map((key, value) => MapEntry(key as String, Map<String, String>.from(value))),
      );
    //});
    debugPrint('Got screen time!');
  } on PlatformException catch (e) {
    debugPrint("Failed to get screen time: ${e.message}");
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
Future<void> _writeScreenTimeData() async {
  //Update ref to user's doc if UID has changed
  updateUserRef();
  if(_screenTimeData.isNotEmpty){
    double totalDaily = 0.0;
    final current = userRef.collection('appUsageCurrent');
    // Create a batch to handle multiple writes
    final batch = firestore.batch();
    try {
      // Iterate through each app and its screen time
      for (final entry in _screenTimeData.entries) {
        final appName = entry.key;
        final screenTimeHours = double.parse(entry.value['hours']!);
        final category = entry.value['category'];
        totalDaily += screenTimeHours;
        
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
      //Put user's daily hours in their doc
      batch.set(
        userRef,
        {
          'totalDailyHours': (totalDaily * 100).round() / 100,
          'lastUpdated': FieldValue.serverTimestamp()
        },
        SetOptions(merge:true),
      );
      // Commit the batch
      await batch.commit();
      debugPrint('Successfully wrote screentime data');
    } catch (e) {
      debugPrint('Error writing screen time data to Firestore: $e');
      rethrow;
    }
  }
}