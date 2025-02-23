///*********************************
/// Name: historical_data_page.dart
///
/// Description: Historical Data page file for 
/// application
///*******************************
library;

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firenbase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

///*********************************
/// Name: HistoricalDataPage
/// 
/// Description: Root stateless widget of 
/// the HistoricalDataPage, builds and displays 
/// historical data page view
///*********************************
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});
  @override
  Widget build(BuildContext context) {
    //Wait for a gesture
    return GestureDetector(
      //The user swipes horizontally
      onHorizontalDragEnd: (details) {
        //The user swipes from right to left
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          //Load back animation for page
          Navigator.pushReplacementNamed(context, '/friendsPageBack');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("ProcrastiFriends"),
        ),
        body: FriendsList(),
      ),
    );
  }
}

///********************************************************
/// Name: FriendsList
/// 
/// Description: Root stateless widget of 
/// the FriendsList, builds and displays 
/// social media page view
///********************************************************
class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList>{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
  }

///*********************************************************
/// Name: _addFriend
/// 
/// Description: Takes in a entered UID and searches
/// the db for that user. If found adds to the friend list
///*********************************************************
  void _addFriend(String friendUID) async {
  
  if(friendUID == _auth.currentUser?.uid as String)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot add self as friend'))
    );
    return; // Not AI code just bad code. Would be better to throw error in here but *shrug* it works
  }
 
  CollectionReference uidCollection = _firestore.collection('UID');

  DocumentSnapshot friendDocRef = await uidCollection.doc(friendUID).get();

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

///*********************************************************
/// Name: _deleteFriend
/// 
/// Description: When the small X near a friend's card in the 
/// friends list is pressed it removes that friend from the
/// user's friends list
///*********************************************************
  void _deleteFriend(String friendUID) async {
    DocumentReference userDocRef = _firestore.collection('UID').doc(_auth.currentUser?.uid);

    await userDocRef.update({
      'friends': FieldValue.arrayRemove([friendUID])
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend removed!'))
    );
  }  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        double totalDailyHours = friendData['totalDailyHours'] ?? 0.0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(photoUrl),
                          ),
                          title: Text(displayName),
                          subtitle: Text(
                            'Daily Hours: ${totalDailyHours.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey), 
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => _deleteFriend(friendUID), 
                          ),
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
