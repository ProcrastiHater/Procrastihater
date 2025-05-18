///********************************************************************************
/// Name: profile_settings.dart
///
/// Description: Creates a settings page where users can edit attribute's of their 
/// account like profile picture, username, or sign-out of/delete their accounts
///********************************************************************************
library;

// Dart imports
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_picture_selection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:app_screen_time/main.dart';
import 'package:app_screen_time/daily_st_notifs.dart';


final CollectionReference MAIN_COLLECTION = FirebaseFirestore.instance.collection('UID');
String? uid = FirebaseAuth.instance.currentUser?.uid;
//Reference to user's document in Firestore
DocumentReference userRef = MAIN_COLLECTION.doc(uid);

///***************************************************
/// Name: ProfileSettings
/// 
/// Description: Constructs the ProfileSetting
/// State widget
///***************************************************
class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});
  @override
    ProfileSettingsState createState() => ProfileSettingsState();

}

///***************************************************
/// Name: ProfileSettingsState
/// 
/// Description: State handling widget to display
/// profile setting and update appropriate variables
///***************************************************
class ProfileSettingsState extends State<ProfileSettings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _displayNameController;
  User? _user;
  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _displayNameController = TextEditingController(
      text: _user?.displayName ?? '',
    );
  }

///***************************************************
/// Name: _updateDisplayName
/// 
/// Description: Updates user's display name
/// when the TextField is changed
///***************************************************
  Future<void> _updateDisplayName() async {
    if (_user != null) {
      await _user!.updateDisplayName(_displayNameController.text);
            await userRef.set({
          "displayName": _displayNameController.text
        }, SetOptions(merge: true));
      await _user!.reload();
     
      setState(() {
        _user = _auth.currentUser;
      });
    }
  }

///***************************************************
/// Name: _updateProfilePicture
/// 
/// Description: Updates user's profile picture when  
/// the TextField is changed
///***************************************************
  Future<void> _updateProfilePicture() async {
    bool? updated = await Navigator.pushNamed(context, '/profilePictureSelection') as bool?;

    if (updated == true) {
      // Reload user data
      await _user!.reload(); 
      setState(() {
        _user = _auth.currentUser; 
      });
    }
  }

///***************************************************
/// Name: _signOut
/// 
/// Description: Signs user out of app and takes them
/// to login screen
///***************************************************
  Future<void> _signOut() async {
   await _auth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  ///***************************************************
  /// Name: _deleteAccount
  /// 
  /// Description: Deletes the user's account and return
  /// them to sign in screen
  ///***************************************************
  Future<void> _deleteAccount() async {
    try {
      await _auth.currentUser!.delete();
      // Go back to the previous screen
      Navigator.of(context).pop(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account. Please try again.')),
      );
    }
  }
  
  //Icon for Notification Toggles
  static const WidgetStateProperty<Icon> thumbIcon = WidgetStateProperty<Icon>.fromMap(
    <WidgetStatesConstraint, Icon>{
      WidgetState.selected: Icon(Icons.check),
      WidgetState.any: Icon(Icons.close),
    },
  );

  ///***************************************************
  @override
  Widget build(BuildContext context) {
    bool _hasNotifsPermission = hasNotifsPermission;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _auth.currentUser?.photoURL ?? 'https://picsum.photos/id/237/200/300',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _displayNameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z ._]*')),
                LengthLimitingTextInputFormatter(32)
              ],
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Choose a Name!',
                border: OutlineInputBorder()
              ),
              onSubmitted: (value) => _updateDisplayName(),
            ),
            SizedBox(height: 20),
            // Profile picture change button
            ElevatedButton(
              onPressed : _updateProfilePicture,
              child: Text('Change Profile Picture')
            ),
            SizedBox(height: 10),
            // Button to copy your UID to clipboard
            // This could be prettier
            ElevatedButton(
              onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: _user?.uid as String));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied UID Clipboard!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to copy to clipboard')),
                    );
                  }
              },
              child: const Text('Copy UID Clipboard'),
            ),
            // Button to show dialog for signing out
            ElevatedButton(
              onPressed: () => showDialog(
                context: context, 
                builder: (BuildContext alertContext) => AlertDialog(
                  title: Text("Sign Out"),
                  content: Text("Are you sure you want to sign out?"),
                  actions: [
                    ElevatedButton( //Button to actually sign out
                      onPressed: () {
                        Navigator.pop(alertContext, "Sign Out");
                        _signOut();
                      }, 
                      child: Text("Yes")
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(alertContext, "Cancel"), 
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.red),
                      )
                    )
                  ],
                )
              ),
              child: Text('Sign Out'),
            ),
            Text("Daily Screen Time Notifications"),
            //Toggle for Daily ST Notifications
            Switch(
              value: dailySTNotifsOn, 
              onChanged: (value){
                if(value == true)
                {
                  startDailySTNotifications();
                  preferences!.setBool('dailySTNotifsOn', true);
                  preferences!.reloadCache();
                }else
                {
                  cancelDailySTNotifications();
                  preferences!.setBool('dailySTNotifsOn', false);
                }
              }
            ),
            //Buttons for Total ST Notifications
            //Row(
            //  mainAxisAlignment: MainAxisAlignment.center,
            //  children: [
            //    ElevatedButton(
            //      onPressed: (){
            //        if (_hasNotifsPermission)
            //        {
            //          startDailySTNotifications();
            //        }else
            //        {
            //          ScaffoldMessenger.of(context).showSnackBar(
            //            const SnackBar(content: Text('I don\'t have permission to send notifications')),
            //          );
            //        }
            //      }, 
            //      child: Text("Turn On")
            //    ),
            //    ElevatedButton(
            //      onPressed: (){
            //        if (_hasNotifsPermission)
            //        {
            //          cancelDailySTNotifications();
            //        }else
            //        {
            //          ScaffoldMessenger.of(context).showSnackBar(
            //            const SnackBar(content: Text('Notifications aren\'t on anyways, genius')),
            //          );
            //        }
            //      }, 
            //      child: Text("Turn Off")
            //    )
            //  ],
            //),
            SizedBox(height: 10),
            // Button to delete account
            ElevatedButton(
              onPressed: () => showDialog(
                context: context, 
                builder: (BuildContext alertContext) => AlertDialog(
                  title: Text("Delete Account"),
                  content: Text("Are you sure you want to delete your account?\n\nThis action cannot be undone."),
                  actions: [
                    ElevatedButton(
                      onPressed: (){
                        Navigator.pop(alertContext, "Delete Account");
                        _deleteAccount();
                      },
                      child: Text("Yes")
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(alertContext, "Cancel"),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.red
                        ),
                      )
                    )
                  ],
                )
              ),
              child: Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            )
          ],
        )
      )
    );
  }
}
