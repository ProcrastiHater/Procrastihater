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


  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Study Mode")),

    );
  }
}
