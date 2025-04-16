///*********************************
/// Name: social_media_page.dart
///
/// Description: Social Media page file for
/// application
///*******************************
library;

//smooth_page_indicator imports
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  bool showFriendsLeaderboard = false; // Toggle state
  final String currentUserId = auth.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.pushReplacementNamed(context, '/leaderBoardPageBack');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(showFriendsLeaderboard
              ? "Friends Leaderboard"
              : "Global Leaderboard"),
          automaticallyImplyLeading: false,
          actions: [
            Icon(showFriendsLeaderboard ? Icons.group : Icons.public),
            Switch(
              value: showFriendsLeaderboard,
              onChanged: (value) {
                setState(() {
                  showFriendsLeaderboard = value;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: firestore.collection('UID').doc(currentUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  List<String> friends =
                      List<String>.from(userData['friends'] ?? []);
                  return StreamBuilder<QuerySnapshot>(
                    stream: showFriendsLeaderboard
                        ? firestore.collection('UID').where(
                            FieldPath.documentId,
                            whereIn: [...friends, currentUserId]).snapshots()
                        : firestore.collection('UID').snapshots(),
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
                          'totalDailyHours':
                              (data['totalDailyHours'] ?? 0.0) as num,
                        };
                      }).toList();
                      users.sort((a, b) => (b['totalDailyHours'] as num)
                          .compareTo(a['totalDailyHours'] as num));
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
                            trailing: Text("${index + 1}"),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SmoothPageIndicator(
                  controller:
                      PageController(initialPage: 2), // Dummy controller
                  count: 3,
                  effect: WormEffect(
                    activeDotColor: Colors.indigo,
                    dotColor: Colors.indigo.shade200,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 12,
                  ),
                ),
              ),
            ),
            Container(height: 16),
          ],
        ),
      ),
    );
  }
}
