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
import 'package:flutter/services.dart';

//Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Page imports
import '/main.dart';

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
  bool _isInitialized = false;
  bool _isExiting = false;
  final String currentUserId = auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _initializeUserPoints();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _initializeUserPoints() async {
    final userRef = firestore.collection('UID').doc(currentUserId);
    final doc = await userRef.get();

    if (!doc.exists || doc.data() == null) {
      await userRef.set({'points': 0}, SetOptions(merge: true));
    } else {
      final data = doc.data() as Map<String, dynamic>;
      final points = data['points'] ?? 0;
      await userRef.set({'points': points}, SetOptions(merge: true));
    }
  }

  ///*********************************
  /// Name: _showExitConfirmationDialog
  ///
  /// Description: Creates the exit app dialog
  ///*********************************
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: _isExiting
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Exiting app...'),
                    ],
                  )
                : const Text('Are you sure you want to exit the app?'),
            actions: _isExiting
                ? null // Hide buttons while exiting
                : <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isExiting = true;
                        });

                        await Future.delayed(const Duration(milliseconds: 500));

                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: const Text('Yes'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final bool shouldPop = await _showExitConfirmationDialog(context);

            if (shouldPop && context.mounted) {
              SystemNavigator.pop();
            }
          },
          child: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ));
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final bool shouldPop = await _showExitConfirmationDialog(context);

        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            Navigator.pushReplacementNamed(context, '/leaderBoardPageBack');
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text("ProcrastiBoards"),
            actions: [
              // Creating little user icon you can press to view account info
              IconButton(
                icon: CircleAvatar(
                  backgroundImage: NetworkImage(
                    // Use user's pfp as icon image if there is no pfp use this link as a default
                    auth.currentUser?.photoURL ??
                        'https://picsum.photos/id/237/200/300',
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
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                SizedBox(
                  height: 80,
                  child: DrawerHeader(
                      decoration: BoxDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.asset("assets/logo.jpg"),
                          ),
                          Text(
                            "ProcrastiTools",
                          ),
                        ],
                      )),
                ),
                ListTile(
                  trailing: Icon(Icons.calendar_today),
                  title: Text("Calendar"),
                  onTap: () {
                    Navigator.pushNamed(context, '/calendarPage');
                  },
                ),
                ListTile(
                  trailing: Icon(Icons.school),
                  title: Text("Study Mode"),
                  onTap: () {
                    Navigator.pushNamed(context, '/studyModePage');
                  },
                ),
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
          body: Column(
            children: [
              FutureBuilder<QuerySnapshot>(
                future: firestore
                    .collection('UID')
                    .orderBy('points')
                    .limit(3)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                        "There are not 3 users in the database, this is bad!");
                  }

                  var losers = snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return {
                      'displayName': data['displayName'] ?? 'Unknown',
                      'pfp':
                          data['pfp'] ?? 'https://picsum.photos/id/443/367/267',
                      'points': (data['points'] ?? 0) as num,
                    };
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Text(
                          'Global Loserboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (losers.length > 1)
                              buildLoserColumn(losers[1], 25,
                                  '🥈'), // 2nd lowest, left, smaller pfp
                            if (losers.length > 0)
                              buildLoserColumn(losers[0], 30,
                                  '🥇'), // lowest, middle, bigger pfp
                            if (losers.length > 2)
                              buildLoserColumn(losers[2], 20,
                                  '🥉'), // 3rd lowest, right, smaller pfp
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showFriendsLeaderboard
                          ? "Friends Leaderboard"
                          : "Global Leaderboard",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          showFriendsLeaderboard ? Icons.group : Icons.public,
                        ),
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
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: firestore.collection('UID').doc(currentUserId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData ||
                        userSnapshot.data?.data() == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var userData =
                        userSnapshot.data?.data() as Map<String, dynamic>? ??
                            {};

                    List<String> friends =
                        List<String>.from(userData['friends'] ?? []);
                    if (showFriendsLeaderboard && friends.isEmpty) {
                      return const Text("You have no friends! :(");
                    }
                    return StreamBuilder<QuerySnapshot>(
                      stream: showFriendsLeaderboard
                          ? firestore.collection('UID').where(
                              FieldPath.documentId,
                              whereIn: [...friends, currentUserId]).snapshots()
                          : firestore.collection('UID').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var users = snapshot.data!.docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return {
                            'uid': doc.id,
                            'displayName': data['displayName'] ?? 'Unknown',
                            'pfp': data['pfp'] ??
                                'https://picsum.photos/id/443/367/267',
                            'points': (data['points'] ?? 0) as num,
                          };
                        }).toList();

                        users.sort((a, b) =>
                            (b['points'] as num).compareTo(a['points'] as num));

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var user = users[index];
                            return TweenAnimationBuilder(
                              tween: Tween<Offset>(
                                  begin: Offset(0, 0.1), end: Offset.zero),
                              duration:
                                  Duration(milliseconds: 300 + index * 100),
                              builder: (context, offset, child) {
                                return Transform.translate(
                                  offset: offset * 100,
                                  child: Opacity(
                                    opacity: 1.0 - offset.dy,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(user['pfp']),
                                      ),
                                      title: Text(user['displayName']),
                                      subtitle: Text(
                                        'Points: ${(user['points'] as num).toStringAsFixed(0)}',
                                      ),
                                      trailing: Text("${index + 1}"),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SmoothPageIndicator(
                    controller:
                        PageController(initialPage: 2), // Dummy controller
                    count: 3,
                    effect: WormEffect(
                      paintStyle: PaintingStyle.stroke,
                      activeDotColor: beige,
                      dotColor: lightBeige,
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
      ),
    );
  }
}

Widget buildLoserColumn(
    Map<String, dynamic> user, double radius, String medal) {
  return Column(
    children: [
      CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user['pfp']),
      ),
      SizedBox(height: 8),
      Text(
        '$medal ${user['displayName']}',
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(height: 4),
      Text(
        '${user['points']} pts',
        style: TextStyle(fontSize: 14),
      ),
    ],
  );
}
