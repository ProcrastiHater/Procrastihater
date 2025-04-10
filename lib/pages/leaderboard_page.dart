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
          title: Text("ProcrastiStats"),
        actions: [
          // Creating little user icon you can press to view account info
          IconButton(
            icon: CircleAvatar(
              backgroundImage: NetworkImage(
                // Use user's pfp as icon image if there is no pfp use this link as a default
                auth.currentUser?.photoURL ?? 'https://picsum.photos/id/237/200/300',
              ),
            ),
            onPressed: () async {
              await Navigator.pushNamed(context, "/profileSettings");
              // Reload the user in case anything changed
              await auth.currentUser?.reload();
              // Reload UI in case things changed
              setState(() {});
            },
          )
        ],
        bottom: AppBar(
          title: Text(showFriendsLeaderboard ? "Friends Leaderboard" : "Global Leaderboard"),
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
        ),
        drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 80,
              child:  DrawerHeader(
              decoration: BoxDecoration(
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset("assets/logo.jpg"),
                  ),
                  Text("ProcrastiTools",),
              ],
              )
              ),
            ),
              ListTile(
              trailing: Icon(Icons.calendar_today),
              title: Text("Calendar"),
              onTap:() {
                Navigator.pushNamed(context, '/calendarPage');
              },
            ),
           // const Divider(),
             ListTile(
              trailing: Icon(Icons.school),
              title: Text("Study Mode"),
              onTap: () {
                Navigator.pushNamed(context, '/studyModePage');
              },
            ),
            //const Divider(),
            ListTile(
              trailing: Icon(Icons.alarm),
              title: Text("App Limits"),
              onTap: () {
                Navigator.pushNamed(context, '/appLimitsPage');
              },
            )
          ],
        ),
      ),
        body: FutureBuilder<DocumentSnapshot>(
          future: firestore.collection('UID').doc(currentUserId).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            List<String> friends = List<String>.from(userData['friends'] ?? []);

            return StreamBuilder<QuerySnapshot>(
              stream: showFriendsLeaderboard
                  ? firestore.collection('UID').where(FieldPath.documentId, whereIn: [...friends, currentUserId]).snapshots()
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
                        //style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Text("${index+1}"),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
