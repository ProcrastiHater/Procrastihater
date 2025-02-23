///*********************************
/// Name: social_media_page.dart
///
/// Description: Social Media page file for 
/// application
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';

//Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;

///*********************************
/// Name: Leaderboard_Page
/// 
/// Description: Root stateless widget of 
/// the Leaderboard_Page, builds and displays 
/// the global leaderboard by default
///*********************************
class LeaderBoardPage extends StatelessWidget {
  const LeaderBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //The user swipes horizontally
      onHorizontalDragEnd: (details) {
        //The user swipes from right to left
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          //Load back animation for page
          Navigator.pushReplacementNamed(context, '/leaderBoardPageBack');
        }
      },
    child: Scaffold(
      appBar: AppBar(
        title: const Text("Global Leaderboard"),
        automaticallyImplyLeading: false
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('UID').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'uid': doc.id,
              'displayName': data['displayName'] ?? 'Unknown',
              'pfp': data['pfp'] ?? 'https://picsum.photos/200/200',
              'totalDailyHours': (data['totalDailyHours'] ?? 0.0) as num,
            };
          }).toList();

          users.sort((a, b) => (b['totalDailyHours'] as num).compareTo(a['totalDailyHours'] as num));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['pfp']),
                ),
                title: Text(user['displayName']),
                subtitle: Text(
                  'Daily Hours: ${(user['totalDailyHours'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
     ),
    );
  }
}
