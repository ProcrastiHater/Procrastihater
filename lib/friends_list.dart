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

  
  void _addFriend(String friendUID) async {
  CollectionReference uidCollection = _firestore.collection('UID');

  DocumentSnapshot friendDocRef = await uidCollection.doc(friendUID).get();
    print(friendDocRef.exists);

  if (friendDocRef.exists) { // This will be true even if the document has no fields
    DocumentReference userDocRef = _firestore.collection('UID').doc(_auth.currentUser?.uid);

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
        ),
         Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('UID').doc(_auth.currentUser?.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                List<dynamic> friends = (snapshot.data?.data() as Map<String, dynamic>)['friends'] ?? [];

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    String friendUID = friends[index];

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('UID').doc(friendUID).get(),
                      builder: (context, friendSnapshot) {
                        if (!friendSnapshot.hasData) return const SizedBox.shrink(); // Show nothing if no data

                        var friendData = friendSnapshot.data!.data() as Map<String, dynamic>;
                        String displayName = friendData['displayName'] ?? 'Unknown';
                        String photoUrl = friendData['pfp'] ?? 'https://picsum.photos/200/200';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(photoUrl),
                          ),
                          title: Text(displayName),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
       ],
      )
    );
  }
}
