///*********************************
/// Name: home_page.dart
///
/// Description: Home page file for 
/// application, currently holds
/// previous prototype
///
///*******************************

//Dart imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
final FirebaseAuth auth = FirebaseAuth.instance;
String? uid = auth.currentUser?.uid;

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
  //Firebase Instance
  final FirebaseFirestore db = FirebaseFirestore.instance;

  //Maps for reading/writing data from the database
  Map<String, double> _screenTimeData = {};
  Map<String, double> _firestoreScreenTimeData = {};
  //Permission variables for screen time usage permission
  bool _hasPermission = false;

  //Checks screen time usage permission on startup
  @override
  void initState() {
    super.initState();
    _checkPermission();
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
  /// with by storing into a Map.
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
      //State for writing raw data in formated map
      setState(() {
        _screenTimeData = Map<String, double>.from(
          result.map((key, value) => MapEntry(key as String, (value as double))),
        );
      });
    } on PlatformException catch (e) {
      print("Failed to get screen time: ${e.message}");
    }
    await _writeScreenTimeData(_screenTimeData);
  }
  ///*********************************
  /// Name: _writeScreenTimeData
  ///   
  /// Description: Takes the data 
  /// that was accesed in _getScreenTime
  /// and writes it to the Firestore database 
  /// using batches for multiple writes
  ///*********************************
  Future<void> _writeScreenTimeData(Map<String, double> data) async {
  // Regrab UID incase its changed
  uid = auth.currentUser?.uid;

  final userDB = db.collection("UID").doc(uid).collection("appUsageCurrent");
  
  // Create a batch to handle multiple writes
  final batch = db.batch();
  
  try {
    // Iterate through each app and its screen time
    for (final entry in data.entries) {
      final appName = entry.key;
      final screenTimeHours = entry.value;
      
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
    print('Successfully wrote screen time data to Firestore');
  } catch (e) {
    print('Error writing screen time data to Firestore: $e');
    rethrow;
  }
}
  ///*********************************
  /// Name: _fetchScreenTime
  ///   
  /// Description: Fetches screentime that has 
  /// been written into the Firestore database
  /// by accessing a user
  ///*********************************
  Future<void> _fetchScreenTime() async {
    try{
      // Regrab UID incase its changed
      uid = auth.currentUser?.uid;

      final snapshot = await db.collection("UID").doc(uid).collection("appUsageCurrent").get();
      //Temp map for saving data from database
      Map<String, double> fetchedData = {};
      //Loop to access all screentime data from user
      for (var doc in snapshot.docs){
        String docName = doc.id;
        double? hours = doc['dailyHours']?.toDouble();
        if (hours != null){
          fetchedData[docName] = hours;
        }
      }
      //State for setting temp data to global map
        setState(() {
         _firestoreScreenTimeData = fetchedData;
        });
    } catch (e){
     print("error fetching screentime data: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
            //Button for writing screentime data to database
            ElevatedButton(
              onPressed: _getScreenTime,
              child: const Text('Write Screentime'),
            ),
            if (!_hasPermission)
              const Text('Permission required for screen time access'),
              //Button for fetching data from database
              ElevatedButton(
                onPressed: _fetchScreenTime, 
                child: const Text('Fetch Screentime')
            ),
            //Display list of data if map of data is not empty
            if (_firestoreScreenTimeData.isNotEmpty)
              Expanded(
                //Listview for displaying a list of items
                child: ListView.builder(
                  itemCount: _firestoreScreenTimeData.length,
                  //Item is built with app name and hours displayed
                  itemBuilder: (context, index) {
                    final entry = _firestoreScreenTimeData.entries.elementAt(index);
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${entry.value} hours'),
                    );
                  },
                ),
              ),
            const SignOutButton(),
          ],
        ),
      ),
    );
  }
}
