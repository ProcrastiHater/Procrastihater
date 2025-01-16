import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  runApp(const SocialMediaPage());
}

class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text("Social Media Page"),
      ),
    body: const Center(
      child: Text("Friend Icons")
    )
    );
  }
}
