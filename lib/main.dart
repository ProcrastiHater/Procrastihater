import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:device_apps/device_apps.dart';
import 'app.dart';
final FirebaseAuth auth = FirebaseAuth.instance;
final uid = auth.currentUser?.uid;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  runApp(const MyAppDart());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Data Grabber!',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Screentime Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const screenTimeChannel = MethodChannel('kotlin.methods/screentime');
  final FirebaseFirestore db = FirebaseFirestore.instance;

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
      final bool hasPermission = await screenTimeChannel.invokeMethod('checkPermission');
      setState(() {
        _hasPermission = hasPermission;
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
    await _writeScreenTimeData(_screenTimeData);
  }

 Future<void> _writeScreenTimeData(Map<String, double> data) async {
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

Future<void> _fetchScreenTime() async {
  try{
    final snapshot = await db.collection("UID").doc(uid).collection("appUsageCurrent").get();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),

        actions: [
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
        automaticallyImplyLeading: false,


      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SignOutButton(),
            ElevatedButton(
              onPressed: _getScreenTime,
              child: const Text('Write Screentime'),
            ),
            if (!_hasPermission)
              const Text('Permission required for screen time access'),
              ElevatedButton(
                onPressed: _fetchScreenTime, 
                child: const Text('Fetch Screentime')
            ),
            if (_firestoreScreenTimeData.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _firestoreScreenTimeData.length,
                  itemBuilder: (context, index) {
                    final entry = _firestoreScreenTimeData.entries.elementAt(index);
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