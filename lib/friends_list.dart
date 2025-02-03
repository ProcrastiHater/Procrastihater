///*********************************
/// Name: friends_list.dart
///
/// Description: Social Media page file for 
/// application
///*******************************

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firenbase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

///*********************************
/// Name: FriendsList
/// 
/// Description: Root stateless widget of 
/// the FriendsList, builds and displays 
/// social media page view
///*********************************
class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  _FriendsListState createState() => _FriendsListState();

}

class _FriendsListState extends State<FriendsList>{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<String> _friendsList = [];


  @override
  void initState() {
    super.initState();
  }

  // TODO ADD CHECK FOR IF FRIEND HAS ALREADY BEEN ADDED
  // TODO FIGURE OUT WHY FRIEND DOC ISN'T BEING VALIDATED
  void _addFriend(String friendUID) async {
  DocumentSnapshot friendDocRef = await _firestore.collection('UID').doc(friendUID).get();
  print('FriendUID: ${friendUID}');
  print('Friend Document Exists: ${friendDocRef.exists}');
  print('Friend Document as string?: ${friendDocRef.data()}');

    if (friendDocRef.exists) {
         DocumentReference userDocRef = _firestore.collection('UID').doc(_auth.currentUser?.uid);
         // Adding friend UID to friends field in UID document
         await userDocRef.set({
          'friends': FieldValue.arrayUnion([friendUID])
         }, SetOptions(merge: true));
        
         
        await userDocRef.collection('friends').doc(friendUID).set({
            'UID': friendUID
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Friend added!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends List"),
      ),
      body: Column(
      children: [
        
        Padding(
          padding: const EdgeInsets.all(8),
          child:TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Enter Friend UID',
              suffixIcon: IconButton(
              icon: const Icon(Icons.search),
               onPressed: () => _addFriend(_searchController.text),
              ),
            ),
          )
        )

       ],
      )
    );
  }
}
