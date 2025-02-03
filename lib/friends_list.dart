///*********************************
/// Name: friends_list.dart
///
/// Description: Social Media page file for 
/// application
///*******************************

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
class FriendsList extends StatelessWidget {
  const FriendsList({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text("Friends List"),
      ),
    body: const Center(
      child: Text("Friend Icons")
    )
    );
  }
}
