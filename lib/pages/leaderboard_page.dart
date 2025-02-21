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
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.pushNamed(context, '/leaderBoardPageBack');
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
