///*********************************************
/// Name: study_mode_page.dart
///
/// Description: Page for entering study mode
///*********************************************
library;

import 'package:app_screen_time/main.dart';
import 'package:app_screen_time/pages/app_limits_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
class StudyModePage extends StatefulWidget {
  const StudyModePage({super.key});

  @override
  StudyModePageState createState() => StudyModePageState();
}

class StudyModePageState extends State<StudyModePage> with WidgetsBindingObserver {
  bool _isStudying = false;
  final Stopwatch _stopwatch = Stopwatch();
  int _totalPoints = 0;
 

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTotalPoints();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    _isStudying = false;
    _stopwatch.stop();
    super.dispose();
  }

///*********************************************************
/// Name: didChangeAppLifecycleState
/// 
/// Description: Monitors the app's widet to detect if it has been
/// paused or force closed. If detected it applys the point penalty
/// and resets the timer page back to its default state
///*********************************************************
 @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isStudying) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        applyPenalty(); 
        _stopwatch.stop();
        _stopwatch.reset(); 
        setState(() {
          _isStudying = false;
        });
      } 
    }
  }

///*********************************************************
/// Name: _updateTotalPoints
/// 
/// Description: Gets the total points from the user'svfirestore
/// object
///*********************************************************
Future<void> _updateTotalPoints() async {
  updateUserRef();
  int totalPoints = 0;
  try {
    final userDoc = await userRef.get();
    if (userDoc.exists &&
      (userDoc.data() as Map<String, dynamic>).containsKey("points")) {
        totalPoints = await userDoc.get("points");
    }
  } catch (e) {
    debugPrint("error obtaining points from db: $e");
  }
  setState(() {
    _totalPoints = totalPoints;
  });
}

///*********************************************************
/// Name: _startStudySession
/// 
/// Description: Sets the isStudying flag to true, begins the 
/// stopwatch, and refreshes the UI to display the new components
///*********************************************************
void _startStudySession() {
    setState(() {
    _isStudying = true;
    _stopwatch.start();  
  });

  // Refreshing the UI every second so that the stopwatch can be displayed
  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!_isStudying) {
      timer.cancel(); 
    } else {
      setState(() {}); 
    }
  });

  WakelockPlus.enable();
}

///*********************************************************
/// Name: _endSession
/// 
/// Description: Sets the isStudying flag to true, begins the 
/// stopwatch, and refreshes the UI to display the new components
///*********************************************************
 Future<void> _endSession() async {
    updateUserRef();
    int earnedPoints = _stopwatch.elapsed.inMinutes;
    try {
      final userDoc = await userRef.get();
      setState(() {
        _isStudying = false;
      });

      _stopwatch.stop();
      _stopwatch.reset();

      if (earnedPoints >= 1 && userDoc.exists) {
        if ((userDoc.data() as Map<String, dynamic>).containsKey("points")) {
          await userRef.update({
            'points': FieldValue.increment(earnedPoints),
          });
        } else {
          await userRef.set({'points': earnedPoints});
        }
      } else if (earnedPoints >= 1) {
        await userRef.set({'points': earnedPoints});
      }
    } catch (e) {
      debugPrint("error applying earned points: $e");
    }
    await _updateTotalPoints();

    WakelockPlus.disable();
  }

  ///*********************************************************
  /// Name: applyPenalty
  /// 
  /// Description: applys the point deduction to the user's 
  /// firestore object.
  ///*********************************************************
  Future<void> applyPenalty() async {
    updateUserRef();
    try {
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        if ((userDoc.data() as Map<String, dynamic>).containsKey("points")) {
          await userRef.update({
            'points': FieldValue.increment(-25),
          });
        } else {
          await userRef.set({'points': -25});
        }
      } else {
        await userRef.set({'points': -25});
      }
    } catch (e) {
      debugPrint("error applying penalty: $e");
    }
    await _updateTotalPoints();
  }

///*********************************************************
/// Name: formatTime
/// 
/// Description: converts the stop watches duration object to
/// a nicer looking string to display
///*********************************************************
String formatTime(Duration duration) {
  String hours = duration.inHours.toString().padLeft(2, '0');
  String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return "$hours:$minutes:$seconds";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Study Mode"),
        titleTextStyle: TextStyle(
          fontSize: 20
        ),
      ),
      body: Center(
        child: _isStudying
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatTime(_stopwatch.elapsed),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _endSession,
                    child: const Text("End Study Session"),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Points Earned: ${_stopwatch.elapsed.inMinutes}", 
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    "Your Total Points: $_totalPoints",
                    style: const TextStyle(fontSize: 20),
                  )
                ],
              )
            : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "While in study mode, a timer will show and you will gain 1 point for every minute you studied for."
                    " Points earned will only be saved once you exit study mode via the \"End Study Session\" button."
                    " If you minimize the app, close the app, or turn off your screen without pressing the"
                    " \"End Study Session\" button, 25 points will be deducted, and no points will be earned.",
                    style: const TextStyle(
                      fontSize: 20
                    ),
                    textAlign: TextAlign.center
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startStudySession,
                  child: const Text("Begin Study Session"),
                ),
                const SizedBox(height: 40),
                Text(
                  "Your Total Points: $_totalPoints",
                  style: const TextStyle(fontSize: 20),
                )
              ] 
            )
      ),
    );
  }
}
