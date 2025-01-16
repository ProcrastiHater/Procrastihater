import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  runApp(const HistoricalDataPage());
}

class HistoricalDataPage extends StatelessWidget {
  const HistoricalDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text("Historical Data Page"),
      ),
    body: const Center(
      child: Text("Historical Data Graph")
    )
    );
  }
}
