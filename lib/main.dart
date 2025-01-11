import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_core/core.dart';

void main() {
  return runApp(ChartApp());
}

class ChartApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    _tooltipBehavior = TooltipBehavior(enable: true);
    super.initState();
  }

 @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Center(
                child: Container(
                    child: SfCartesianChart(
                        // Enables the legend
                        legend: Legend(isVisible: true), 
                        // Initialize category axis
                        primaryXAxis: CategoryAxis(),
                        series: <CartesianSeries>[
                            // Initialize line series
                            LineSeries<ChartData, String>(
                                dataSource: [
                                    // Bind data source
                                    ChartData('Jan', 35),
                                    ChartData('Feb', 28),
                                    ChartData('Mar', 34),
                                    ChartData('Apr', 32),
                                    ChartData('May', 40)
                                ],
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) => data.y,
                            )
                        ]
                    )
                )      
            )
        );
    }

}

class ChartData {
        ChartData(this.x, this.y);
        final String x;
        final double? y;
}


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:device_apps/device_apps.dart';
// import 'charts.dart';



// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//     await Firebase.initializeApp();
//   try {
//     await FirebaseAuth.instance.signInAnonymously();
//     print("Signed in anonymously");
//   } catch (e) {
//     print('Error signing in anonymously: $e');
//   }
//   //SyncfusionLicense.registerLicense("YOUR LICENSE KEY"); 
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'User Data Grabber!',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Screentime Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   static const screenTimeChannel = MethodChannel('kotlin.methods/screentime');
//   final FirebaseFirestore db = FirebaseFirestore.instance;

//   Map<String, double> _screenTimeData = {};
//   Map<String, double> _firestoreScreenTimeData = {};
//   bool _hasPermission = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkPermission();
//   }

//   Future<void> _checkPermission() async {
//     try {
//       final bool hasPermission = await screenTimeChannel.invokeMethod('checkPermission');
//       setState(() {
//         _hasPermission = hasPermission;
//       });
//     } on PlatformException catch (e) {
//       print("Failed to check permission: ${e.message}");
//     }
//   }

//   Future<void> _requestPermission() async {
//     try {
//       await screenTimeChannel.invokeMethod('requestPermission');
//       await _checkPermission();
//     } on PlatformException catch (e) {
//       print("Failed to request permission: ${e.message}");
//     }
//   }

//   Future<void> _getScreenTime() async {
//     if (!_hasPermission) {
//       await _requestPermission();
//       return;
//     }

//     try {
//       final Map<dynamic, dynamic> result = await screenTimeChannel.invokeMethod('getScreenTime');
//       setState(() {
//         _screenTimeData = Map<String, double>.from(
//           result.map((key, value) => MapEntry(key as String, (value as double))),
//         );
//       });
//     } on PlatformException catch (e) {
//       print("Failed to get screen time: ${e.message}");
//     }
//     await _writeScreenTimeData(_screenTimeData);
//   }

//  Future<void> _writeScreenTimeData(Map<String, double> data) async {
//   final userDB = db.collection("UID").doc("123").collection("appUsageCurrent");
  
//   // Create a batch to handle multiple writes
//   final batch = db.batch();
  
//   try {
//     // Iterate through each app and its screen time
//     for (final entry in data.entries) {
//       final appName = entry.key;
//       final screenTimeHours = entry.value;
      
//       // Reference to the document with app name
//       final docRef = userDB.doc(appName);
      
//       // Set the data with merge option to update existing documents
//       // or create new ones if they don't exist
//       batch.set(
//         docRef,
//         {
//           'dailyHours': screenTimeHours,
//           'lastUpdated': FieldValue.serverTimestamp(),
//         },
//         SetOptions(merge: true),
//       );
//     }
    
//     // Commit the batch
//     await batch.commit();
//     print('Successfully wrote screen time data to Firestore');
//   } catch (e) {
//     print('Error writing screen time data to Firestore: $e');
//     rethrow;
//   }
// }

// Future<void> _fetchScreenTime() async {
//   try{
//     final snapshot = await db.collection("UID").doc("123").collection("appUsageCurrent").get();
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: _getScreenTime,
//               child: const Text('Write Screentime'),
//             ),
//             if (!_hasPermission)
//               const Text('Permission required for screen time access'),
//               ElevatedButton(
//                 onPressed: _fetchScreenTime, 
//                 child: const Text('Fetch Screentime')
//             ),
//             if (_firestoreScreenTimeData.isNotEmpty)
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: _firestoreScreenTimeData.length,
//                   itemBuilder: (context, index) {
//                     final entry = _firestoreScreenTimeData.entries.elementAt(index);
//                     return ListTile(
//                       title: Text(entry.key),
//                       subtitle: Text('${entry.value} hours'),
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }