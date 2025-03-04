///*********************************
/// Name: app_limits_page.dart
///
/// Description: Shows a list of all
/// of the user's apps, allowing them
/// to set limits for each one
///*********************************
library;

import 'dart:ffi';

import 'package:app_screen_time/apps_list.dart';
import 'package:app_screen_time/main.dart';
import 'package:app_screen_time/pages/graph/colors.dart';
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
  final List<TextEditingController> _appLimitControllers = List.generate(appNames.length, (int i) => TextEditingController());
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
              tileColor: Colors.indigo.shade100,
              //leading: Text('App Icon?'),
              title: Text(
                appNames[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: appNameToColor[appNames[index]],
                ),
              ),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: _appLimitControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Time limit',
                  )
                )
              )
          );
        }
      )
    );
  }
}

//Future<void> _updateAppLimit(String appName, int newLimit)
//{
  //updateUserRef();
  //if(newLimit == 0){

  //}
//}