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

  Future<void> _updateDisplayName() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(_displayNameController.text);
      await _auth.currentUser!.reload();
      setState(() {}); // Refresh the UI
    }
  }


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _auth.currentUser?.photoURL ?? 'https://picsum.photos/id/237/200/300',
              ),
            ),
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder()
              ),
              onSubmitted: (value) => _updateDisplayName(),
            ),
          ],
        )
      )
    );
  }
}