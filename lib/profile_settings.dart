import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_picture_selection.dart';

class ProfileSettings extends StatefulWidget {
  @override
  _ProfileSettingsState createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _displayNameController;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _displayNameController = TextEditingController(
      text: _user?.displayName ?? 'No Name',
    );
  }

  Future<void> _updateDisplayName() async {
    if (_user != null) {
      await _user!.updateDisplayName(_displayNameController.text);
      await _user!.reload();
      setState(() {
        _user = _auth.currentUser;
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePictureSelectionScreen(),
      ),
    );

    if (updated == true) {
      await _user!.reload(); // Reload user data
      setState(() {
        _user = _auth.currentUser; // Update state with new photoURL
      });
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
            SizedBox(height: 20),
            // Profile picture change button
            ElevatedButton(
              onPressed :_updateProfilePicture,
              child: Text('Change Profile Picture')
            )
          ],
        )
      )
    );
  }
}