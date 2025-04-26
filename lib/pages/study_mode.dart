import 'package:app_screen_time/pages/app_limits_page.dart';
import 'package:app_screen_time/profile/profile_picture_selection.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final user = auth.currentUser;
  final userDoc = await userRef.get();
  int totalPoints = 0;
  if(user != null){
    totalPoints = await userDoc.get("points");
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
  }

///*********************************************************
/// Name: _endSession
/// 
/// Description: Sets the isStudying flag to true, begins the 
/// stopwatch, and refreshes the UI to display the new components
///*********************************************************
 Future<void> _endSession() async {
    final user = auth.currentUser;
    int earnedPoints = _stopwatch.elapsed.inMinutes;

    setState(() {
      _isStudying = false;
    });

    _stopwatch.stop();
   _stopwatch.reset();

    if (earnedPoints >= 1 && user != null) {
      await firestore.collection('UID').doc(user.uid).update({
        'points': FieldValue.increment(earnedPoints),
      });
    }
    await _updateTotalPoints();
  }

  ///*********************************************************
  /// Name: applyPenalty
  /// 
  /// Description: applys the point deduction to the user's 
  /// firestore object.
  ///*********************************************************
  Future<void> applyPenalty() async {
    final user = auth.currentUser;
    if (user != null) {
      await firestore.collection('UID').doc(user.uid).update({
        'points': FieldValue.increment(-20),
      });
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
                    "While in study mode, a timer will show and you will gain points for every minute you studied for"
                    " once you exit study mode. However, if you leave the app without"
                    " exiting study mode, a large amount of points will be deducted instead.",
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
