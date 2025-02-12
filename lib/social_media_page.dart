///*********************************
/// Name: social_media_page.dart
///
/// Description: Social Media page file for 
/// application
///*******************************
library;

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firenbase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

///*********************************
/// Name: SocialMediaPage
/// 
/// Description: Root stateless widget of 
/// the SocialMediaPage, builds and displays 
/// social media page view
///*********************************
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
