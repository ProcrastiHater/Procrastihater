import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettings extends StatefulWidget{
  @override
  _ProfileSettingsState createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings>{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: _auth.currentUser?.displayName ?? 'No Name',
    );
}

@override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}