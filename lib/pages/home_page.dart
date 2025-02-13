///*********************************
/// Name: home_page.dart
///
/// Description: Home page file for 
/// application, currently holds
/// current app usage
///*******************************
library;

//Dart imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../profile/profile_settings.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//Page Imports
import 'package:app_screen_time/main.dart';

///*********************************
/// Name: HomePage
/// 
/// Description: Root stateless widget of 
/// the HomePage, builds and displays home page view
///*********************************
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
    home: Scaffold(

    ),//MyHomePage(title: 'ProcrastiStats'),
    );
  }
}

///*********************************
/// Name: MyHomePage
///   
/// Description: Stateful widget that 
/// manages the Firebase reading and writting
///*********************************
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

///*********************************
/// Name: MyHomePageState
/// 
/// Description: Manages state for MyHomePage, 
/// accesses screentime of phone through method
/// channels, checks and requests neccesary 
/// permissions, reads/write from firebase
///*********************************
class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose() async {
    debugPrint("**********Disposing...***************");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Creating little user icon you can press to view account info
          IconButton(
            icon: CircleAvatar(
                 backgroundImage: NetworkImage(
                // Use user's pfp as icon image if there is no pfp use this link as a default
                AUTH.currentUser?.photoURL ?? 'https://picsum.photos/id/237/200/300',
                    ),
            ),
            onPressed: () async {
             await Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => ProfileSettings(),
                ),
              );
              // Reload the user in case anything changed
              await AUTH.currentUser?.reload();
              // Reload UI in case things changed
              setState(() {});

            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
          ],
        ),
      ),
    );
  }
}