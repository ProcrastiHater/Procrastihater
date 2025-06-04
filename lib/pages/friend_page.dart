///*********************************
/// Name: historical_data_page.dart
///
/// Description: Historical Data page file for
/// application
///*******************************
library;

//smooth_page_indicator imports
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firenbase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Page imports
import '/main.dart';

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
            title: Text("ProcrastiFriends"),
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
                  // setState(() {});
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
          body: FriendsList(),
        ),
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

class _FriendsListState extends State<FriendsList>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteFriend(String friendUID) async {
    DocumentReference userDocRef =
        _firestore.collection('UID').doc(_auth.currentUser?.uid);

    await userDocRef.update({
      'friends': FieldValue.arrayRemove([friendUID])
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Friend removed!')));
  }

  void _pokeFriend(String friendUID) async {
    DocumentReference friendDocRef =
        _firestore.collection('UID').doc(friendUID);

    await friendDocRef.collection('pokes').doc(_auth.currentUser?.uid).set({
      'from': _auth.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Poked your friend!')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            Navigator.pushReplacementNamed(context, '/friendsPageBack');
          }
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: TabBar(
              tabs: const [
                Tab(
                    icon: Icon(Icons.person_add_alt_1_sharp),
                    text: 'Add Friends'),
                Tab(icon: Icon(Icons.waving_hand), text: 'Pokes'),
                Tab(
                    icon: Icon(Icons.person_pin_rounded),
                    text: 'Friend Requests'),
              ],
              onTap: (index) {
                if (index == 1) {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => const PokeNotificationsPage(),
                  );
                } else if (index == 0) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: ShowAddFriendsSheet(),
                    ),
                  );
                } else if (index == 2) {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => FriendRequestsSheet(),
                  );
                }
              },
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('UID').doc(uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data?.data() == null) {
                      return const Center(child: Text("No Friends Yet"));
                    }

                    Map<String, dynamic>? data =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    List<dynamic> friends =
                        data?['friends'] is List ? data!['friends'] : [];

                    if (friends.isEmpty) {
                      return const Center(child: Text("No Friends Yet"));
                    }

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        String friendUID = friends[index];

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              _firestore.collection('UID').doc(friendUID).get(),
                          builder: (context, friendSnapshot) {
                            if (!friendSnapshot.hasData ||
                                !friendSnapshot.data!.exists ||
                                friendSnapshot.data?.data() == null) {
                              return const SizedBox.shrink();
                            }

                            var friendData = friendSnapshot.data!.data()
                                as Map<String, dynamic>;
                            String displayName =
                                friendData['displayName'] ?? 'Unknown';
                            String photoUrl = friendData['pfp'] ??
                                'https://picsum.photos/id/443/367/267';
                            double totalDailyHours =
                                friendData['totalDailyHours'] ?? 0.0;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(photoUrl),
                                ),
                                title: Text(
                                  displayName,
                                ),
                                subtitle: Text(
                                  'Daily Hours: ${totalDailyHours.toStringAsFixed(2)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.waving_hand,
                                          color: Colors.blue),
                                      onPressed: () => _pokeFriend(friendUID),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () => showDialog(
                                            context: context,
                                            builder:
                                                (BuildContext alertContext) =>
                                                    AlertDialog(
                                                      title:
                                                          Text("Delete Friend"),
                                                      content: Text(
                                                          "Are you sure you want to delete $displayName from your friends?"),
                                                      actions: [
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  alertContext,
                                                                  "Delete Friend");
                                                              _deleteFriend(
                                                                  friendUID);
                                                            },
                                                            child: Text("Yes")),
                                                        ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    alertContext,
                                                                    "Cancel"),
                                                            child: Text(
                                                                "Cancel",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red)))
                                                      ],
                                                    ))),
                                  ],
                                ),
                              ),
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
                        PageController(initialPage: 0), // Dummy controller
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

///*********************************************************
/// Name: PokeNotificationsPage
///
/// Description: Class for displaying to the user who has poked
/// them when the notifications button is pressed
///*********************************************************
class PokeNotificationsPage extends StatelessWidget {
  const PokeNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Poke Notifications',
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('UID')
            .doc(auth.currentUser?.uid)
            .collection('pokes')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var pokes = snapshot.data!.docs;
          if (pokes.isEmpty) {
            return const Center(
                child: Text(
              'No pokes yet!',
            ));
          }

          return SizedBox(
            child: ListView.builder(
              itemCount: pokes.length,
              itemBuilder: (context, index) {
                var pokeData = pokes[index].data() as Map<String, dynamic>;
                String fromUID = pokeData['from'];

                return FutureBuilder<DocumentSnapshot>(
                  future: firestore.collection('UID').doc(fromUID).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const SizedBox();
                    }

                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    String displayName = userData['displayName'] ?? 'Unknown';
                    String profilePic =
                        userData['pfp'] ?? 'https://picsum.photos/200';

                    return ListTile(
                      leading: CircleAvatar(
                          backgroundImage: NetworkImage(profilePic)),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'poked you!',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () async {
                          await firestore
                              .collection('UID')
                              .doc(auth.currentUser?.uid)
                              .collection('pokes')
                              .doc(fromUID)
                              .delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

bool _isExiting = false;

///*********************************************************
/// Name: ShowAddFriendsSheet
///
/// Description: Displays a bottom sheet for adding friends.
/// Contains a search bar, the user's profile picture, and a
/// button to copy their UID.
///*********************************************************
class ShowAddFriendsSheet extends StatelessWidget {
  ShowAddFriendsSheet({super.key});
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ///*********************************************************
    /// Name: _addFriend
    ///
    /// Description: Takes in a entered UID and searches
    /// the db for that user. If found adds to the friend list
    ///*********************************************************
    void _addFriend(String friendUID, BuildContext context) async {
      if (friendUID == _auth.currentUser?.uid as String) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot add self as friend')));
        return; // Not AI code just bad code. Would be better to throw error in here but *shrug* it works
      }

      CollectionReference uidCollection = _firestore.collection('UID');
      DocumentSnapshot friendDocRef = await uidCollection.doc(friendUID).get();

      if (friendDocRef.exists) {
        // This will be true even if the document has no fields
        DocumentReference friendsRequests = uidCollection
            .doc(friendUID)
            .collection('friendRequests')
            .doc(_auth.currentUser?.uid);

        await friendsRequests.set({
          'from': _auth.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }

      // await userDocRef.set({
      //   'friends': FieldValue.arrayUnion([friendUID])
      // }, SetOptions(merge: true));

      // await userDocRef.collection('friends').doc(friendUID).set({
      //   'UID': friendUID
      // });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User profile picture
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(_auth.currentUser?.photoURL ??
                'https://picsum.photos/id/443/367/267'),
          ),
          const SizedBox(height: 16),

          // Copy UID button
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text("Copy UID"),
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: _auth.currentUser?.uid ?? ""));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('UID copied to clipboard!')));
            },
          ),
          const SizedBox(height: 16),

          // Friend search bar
          TextField(
            controller: _searchController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]*')),
              LengthLimitingTextInputFormatter(28)
            ],
            decoration: InputDecoration(
              labelText: 'Enter Friend UID',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _addFriend(_searchController.text, context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///*********************************************************
/// Name: FriendRequestsSheet
///
/// Description: Displays a bottom sheet of all pending friend
/// requests the user has
///*********************************************************
class FriendRequestsSheet extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FriendRequestsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 400, // Adjust height as needed
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Friend Requests",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('UID')
                  .doc(_auth.currentUser?.uid)
                  .collection('friendRequests')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No friend requests"));
                }

                var requests = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var request = requests[index];
                    var senderUID = request['from'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('UID').doc(senderUID).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        var friendData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        String senderName =
                            friendData['displayName'] ?? 'Unknown';
                        String senderPhoto =
                            friendData['pfp'] ?? 'https://picsum.photos/200';

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(senderPhoto),
                            ),
                            title: Text(senderName),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () =>
                                      _handleFriendRequest(senderUID, true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _handleFriendRequest(senderUID, false),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  ///*********************************************************
  /// Name: _handleFriendRequest
  ///
  /// Description: Handles when a user accepts or denies a friend
  /// request.
  ///*********************************************************
  void _handleFriendRequest(String friendUID, bool accept) async {
    DocumentReference userDocRef =
        _firestore.collection('UID').doc(_auth.currentUser?.uid);
    DocumentReference friendDocRef =
        _firestore.collection('UID').doc(friendUID);

    if (accept) {
      await userDocRef.update({
        'friends': FieldValue.arrayUnion([friendUID]),
      });
      await friendDocRef.update({
        'friends': FieldValue.arrayUnion([_auth.currentUser?.uid]),
      });

      await userDocRef.collection('friendRequests').doc(friendUID).delete();
    } else {
      await userDocRef.collection('friendRequests').doc(friendUID).delete();
    }
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
                        _isExiting = true;
                     
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
