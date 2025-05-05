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
import 'package:app_screen_time/pages/study_mode.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/services.dart';
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
  List<Color> _limitTextColors = List.generate(appNames.length, (int i) => Colors.transparent);
  @override
  void initState() {
    super.initState();
    _readAppLimits().whenComplete((){
      for(int ii = 0; ii < appNames.length; ii++){
        if(appLimits.containsKey(appNames[ii]))
        {
          _appLimitControllers[ii].text = appLimits[appNames[ii]]!.toString();
          if(context.mounted){
            _limitTextColors[ii] = TextTheme.of(context).bodyLarge!.color!;
          }
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
          fontSize: 20,
        ),
        actions: [
          IconButton(
            onPressed: () => showDialog(
              context: context, 
              builder: (BuildContext infoContext) => AlertDialog(
                title: Text("App Limits Page Help"),
                content: Text(
                  "This page allows you to set limits for how many minutes you want to be allowed to spend on an app."
                  " When you reach the limit you set for an app, as long as you have ProcrastiHater open, you will receive"
                  " a notification. Limits you have previously set will be the default text color\n\nTo set a limit for an app:"
                  "\n\t•Scroll down the App Limits Page and locate the app\n \t•Enter a limit (in minutes) less than 24 hours"
                  ". The text for the limit will be red\n\t•Save the limit using the Save button on the left. The text for the limit"
                  " will turn green\n\n NOTE: If you have not used an app since you installed ProcrastiHater, you cannot set a limit"
                  " for it. You cannot set a limit for less than 5 minutes"
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(infoContext, "Close Help"),
                    child: Text("Close Help")
                  )
                ],
                scrollable: true,
              )
            ),
            icon: Icon(Icons.help_outline_rounded)
          )
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(4.0),
        itemCount: appNames.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              titleAlignment: ListTileTitleAlignment.center,
              contentPadding: EdgeInsets.only(bottom: 5, left: 10),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'\d')),
                    LengthLimitingTextInputFormatter(4)
                  ],
                  onChanged: (String val){
                    setState(() {
                      _limitTextColors[index] = Colors.red;
                    });
                    return;
                  },
                  style: TextStyle(
                    color: _limitTextColors[index]
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Time limit',
                    prefixIcon: IconButton(
                      icon: Icon(
                        Icons.save,
                      ),
                      onPressed: () {
                        _updateAppLimit(appNames[index], _appLimitControllers[index].text).then((updated){
                          if(updated){
                            setState(() {
                              _limitTextColors[index] = const Color.fromARGB(255, 65, 228, 70);
                            });
                          }
                        });
                      },
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => _deleteAppLimit(index), 
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                      )
                    )
                  )
                )
              )
            ),
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
  Future<bool> _updateAppLimit(String appName, String newLimitStr) async {
    updateUserRef();
    int? newLimit = int.tryParse(newLimitStr);
    if (newLimit! > 1440) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limit cannot be greater than 24 hours'))
      );
      return false;
    }
    else{
      var limitRef = userRef.collection('limits').doc(appName);
      if (newLimit < 5){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limit cannot be less than 5'))
        );
        return false;
      }
      else{
        try {
          //Set Limit in DB
          await limitRef.set(
              {'limit': ((newLimit / 60) * 100).round().toDouble() / 100},
              SetOptions(merge: true));
          return true;
        }
        catch(e){
          debugPrint("Error setting limit: $e");
          return false;
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
  Future<void> _deleteAppLimit(int index) async {
    updateUserRef();
    _appLimitControllers[index].text = "";
    try {
      var limitRef = userRef.collection('limits').doc(appNames[index]);
      var limitDoc = await limitRef.get();
      //Delete limit if it already exists
      if (limitDoc.exists) {
        await limitRef.delete();
      } else {
        //Print "Limit doesn't exist yet" or something
      }
    }
    catch(e){
      debugPrint("Error deleting limit: $e");
    }
  }
}