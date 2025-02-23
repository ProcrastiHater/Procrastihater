///*********************************
/// Name: social_media_page.dart
///
/// Description: Social Media page file for 
/// application
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';

///*********************************
/// Name: SocialMediaPage
/// 
/// Description: Root stateless widget of 
/// the SocialMediaPage, builds and displays 
/// social media page view
///*********************************
class LeaderBoardPage extends StatelessWidget {
  const LeaderBoardPage({super.key});
  @override
  Widget build(BuildContext context) {
    //Wait for a gesture
    return GestureDetector(
      //The user swipes horizontally
      onHorizontalDragEnd: (details) {
        //The user swipes from left to right
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          //Load back animation for page
          Navigator.pushReplacementNamed(context, '/leaderBoardPageBack');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("ProcrastiLeaderboards"),
        ),
        body: const Center(
          child: Text("Friend Icons")
        )
      )
    );
  }
}
