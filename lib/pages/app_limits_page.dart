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
//OG blue: 18,51,86
//Good blues: 60,65,86 (gr1)
//            32,58,86 (gr2)
//            10,27,46 (darker OG)
//            28,31,41 (darker gr1)
//            20,36,54 (darker gr2)
Color bg = Color.fromARGB(255, 20, 36, 54);
//OG beige-ish: 252,231,193
Color fg = Color.fromARGB(255, 252, 231, 193);

String font = "sans-serif";

TextStyle style = TextStyle(
  color: fg,
  fontFamily: font
);

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
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 20,
          color: fg
        ),
        backgroundColor: bg,
        foregroundColor: fg,
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: appNames.length,
        itemBuilder: (context, index) {
          return ListTile(
            titleAlignment: ListTileTitleAlignment.center,
            contentPadding: EdgeInsets.only(bottom: 5, left: 10, right: 10),
            tileColor: bg,
            title: Text(
              appNames[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: font,
                color: appNameToColor[appNames[index]],
              ),
            ),
            trailing: SizedBox(
              width: 200,
              child: TextField(
                controller: _appLimitControllers[index],
                style: style,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Time limit',
                  labelStyle: style,
                  prefixIcon: IconButton(
                    icon: Icon(
                      Icons.save_rounded,
                      color: fg,
                    ),
                    onPressed: () => _updateAppLimit(appNames[index], _appLimitControllers[index].text),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _deleteAppLimit(appNames[index]), 
                    icon: Icon(
                      Icons.close_rounded,
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