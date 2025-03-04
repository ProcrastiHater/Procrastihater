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
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: EdgeInsets.only(bottom: 5, left: 10, right: 10),
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
              width: 150,
              child: TextField(
                controller: _appLimitControllers[index],
                decoration: InputDecoration(
                  labelText: 'Time limit',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.save
                    ),
                    onPressed: () => _updateAppLimit(appNames[index], _appLimitControllers[index].text),
                  )
                )
              )
            )
          );
        }
      )
    );
  }

  Future<void> _updateAppLimit(String appName, String newLimitStr) async {
    updateUserRef();
    int? newLimit = int.tryParse(newLimitStr);
    if (newLimit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entered limit is not a number'))
      );
    }
    else{
      var limitRef = userRef.collection('limits').doc(appName);
      if (newLimit < 0){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limit must be greater than or equal to 0'))
        );
      }
      else if (newLimit == 0){
        try {
          var limitDoc = await limitRef.get();
          //Delete limit if it already exists
          if (limitDoc.exists) {
            limitRef.delete();
          } else {
            //Print "Limit doesn't exist yet" or something
          }
        }
        catch(e){
          debugPrint("Error deleting limit: $e");
        }
      }
      else{
        try {
          //Set Limit in DB
          await limitRef.set(
              {'limit': ((newLimit / 60) * 100).round().toDouble() / 100},
              SetOptions(merge: true));
        }
        catch(e){
          debugPrint("Error setting limit: $e");
        }
      }
    }
  }
}