///*********************************
/// Name: app_limits_page.dart
///
/// Description: Shows a list of all
/// of the user's apps, allowing them
/// to set limits for each one
///*********************************
library;

import 'package:app_screen_time/apps_list.dart';
import 'package:app_screen_time/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

///*********************************
/// Name: AppLimitsPage
/// 
/// Description: Root stateful widget of 
/// the AppLimitsPage, builds and displays 
/// app limits page view
///*********************************
class AppLimitsPage extends StatefulWidget{
  const AppLimitsPage({super.key});

  @override
  State<StatefulWidget> createState() => AppLimitsPageState();
}

class AppLimitsPageState extends State<AppLimitsPage>{
  final TextEditingController _appLimitController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Screen Time Limits"),
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: appNames.length,
        itemBuilder: (context, index){
          return ListTile(
              leading: Text('App Icon?'),
              title: Text(appNames[index]),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: _appLimitController,
                  decoration: InputDecoration(labelText: 'Time limit')
                )
              )
          );
        }
      )
    );
  }
}