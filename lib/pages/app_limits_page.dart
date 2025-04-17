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
  State<StatefulWidget> createState() => _AppLimitsPageState();
}

///*********************************
/// Name: _AppLimitsPageState
///
/// Description: State for AppLimitsPage,
/// holds main layout widget for page
///*********************************
class _AppLimitsPageState extends State<AppLimitsPage>{
  final List<TextEditingController> _appLimitControllers = List.generate(appNames.length, (int i) => TextEditingController());
  Map<String, int> appLimits = {};
  @override
  void initState() {
    super.initState();
    _readAppLimits().whenComplete((){
      for(int ii = 0; ii < appNames.length; ii++){
        if(appLimits.containsKey(appNames[ii]))
        {
          _appLimitControllers[ii].text = appLimits[appNames[ii]]!.toString();
        }
      }
    });
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
            //: Colors.indigo.shade100,
            title: Text(
              appNames[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: appNameToColor[appNames[index]],
              ),
            ),
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _appLimitControllers[index],
                decoration: InputDecoration(
                  labelText: 'Time limit',
                  prefixIcon: IconButton(
                    icon: Icon(
                      Icons.save
                    ),
                    onPressed: () => _updateAppLimit(appNames[index], _appLimitControllers[index].text),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _deleteAppLimit(appNames[index]), 
                    icon: Icon(
                      Icons.close,
                      color: Colors.red,
                    )
                  )
                )
              )
            )
          );
        }
      )
    );
  }

  ///*********************************
  /// Name: _readAppLimits
  ///
  /// Description: Lists app limits
  /// for page
  ///*********************************
  Future<void> _readAppLimits() async{
    updateUserRef();
    try{
      var limitRef = userRef.collection('limits');
      var limitColl = await limitRef.get();
      for(DocumentSnapshot limitDoc in limitColl.docs) {
        setState(() {
          debugPrint('Limit: ${(limitDoc['limit'] * 60).round()}');
          appLimits.addAll({limitDoc.id : (limitDoc['limit'] * 60).round()});
        });
      }
    }
    catch(e){
      debugPrint("Error Getting Limits: $e");
    }
  }

  ///*********************************
  /// Name: _updateAppLimit
  ///
  /// Description: Updates the limit
  /// for the specific app
  ///*********************************
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
      if (newLimit < 3){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limit must be greater than or equal to 3'))
        );
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

  ///*********************************
  /// Name: _deleteAppLimit
  ///
  /// Description: Deletes the limit for
  /// the given app
  ///*********************************
  Future<void> _deleteAppLimit(String appName) async {
    updateUserRef();
    try {
      var limitRef = userRef.collection('limits').doc(appName);
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
}