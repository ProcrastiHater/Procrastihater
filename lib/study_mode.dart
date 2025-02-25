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
  Timer? _timer;
  int _elapsedSeconds = 0;

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

void _startStudySession() {
    _elapsedSeconds = 0;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Study Mode")),
      body: Column(
        children: [
         ElevatedButton(
              onPressed: _startStudySession,
              child: const Text("Begin Productive Session"),
            ),
      Text(
              "Time Elapsed: ${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
        ]
      )
    );
  }
}
