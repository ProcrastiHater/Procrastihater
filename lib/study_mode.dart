import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class StudyModePage extends StatefulWidget {
  const StudyModePage({super.key});

  @override
  StudyModePageState createState() => StudyModePageState();
}

class StudyModePageState extends State<StudyModePage> {
 bool _isStudying = false;
 Stopwatch _stopwatch = Stopwatch();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

void _startStudySession() {
    setState(() {
    _isStudying = true;
    _stopwatch.start();  // Start the stopwatch
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

String _formatTime(Duration duration) {
  String hours = duration.inHours.toString().padLeft(2, '0');
  String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return "$hours:$minutes:$seconds";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Study Mode")),
      body: Center(
        child: _isStudying
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_stopwatch.elapsed),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: ()=>{},
                    child: const Text("End Study Session"),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _startStudySession,
                child: const Text("Begin Study Session"),
              ),
      ),
    );
  }
}