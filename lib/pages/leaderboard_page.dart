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
class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text("ProcrastiLeaderboards"),
      ),
    body: const Center(
      child: Text("Friend Icons")
    )
    );
  }
}
