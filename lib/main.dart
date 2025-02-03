///*********************************
/// Name: main.dart
///
/// Description: Entry point for main app,
/// initializes firebase, handles authentication
/// and sets up main structure of app
///*******************************

//Dart Imports
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//Page Imports
import 'home_page.dart';
import 'friends_list.dart';
import 'historical_data_page.dart';
import 'login_screen.dart';


///*********************************
/// Name: main
/// 
/// Description: Initializes Firebase,
/// 
/// launches the main app
///*********************************
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Firebase initialization
  await Firebase.initializeApp();
  //launch the main app
  runApp(const LoginScreen());
}

///*********************************
/// Name: MyApp
/// 
/// Description: Root stateless widget of 
/// the app, builds and displays main page view
///*********************************
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyPageView(),
    );
  } 
}

///*********************************
/// Name: MyPageView
/// 
/// Description: Stateful widget that 
/// manages the PageView for app navigation
///*********************************
class MyPageView extends StatefulWidget {
  const MyPageView({super.key});
  @override
  State<MyPageView> createState() => _MyPageViewState();
}
///*********************************
/// Name: MyPageViewState
/// 
/// Description: Manages state for MyPageView, 
/// sets up PageView controller, tracks current
/// page, and handles navigation
///*********************************
class _MyPageViewState extends State<MyPageView> {
  //Controller for page navigation
  late PageController _pageController;
  
  //Tracks current index
  int _currentPage = 0;

  //Initialize page controller and set initial page
  @override
  void initState() {
    _pageController = PageController(initialPage: 1);
    _currentPage = 1;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //PageView widget for navigation
      body: PageView(
        controller: _pageController,
        //Update current page index on page change
        onPageChanged: (index) {
        setState(() {
          _currentPage = index; 
        });
        },
        //Pages to display
        children: const [
          FriendsList(),
          HomePage(),
          HistoricalDataPage(),
        ],
      )
      
    );
  }
}
