///*********************************
/// Name: main.dart
///
/// Description: Entry point for main app,
/// initializes firebase, handles authentication
/// and sets up main structure of app
///*******************************
library;

//Dart Imports
import 'dart:async';
import 'dart:io';
import 'package:app_screen_time/pages/graph/colors.dart';
import 'package:app_screen_time/pages/graph/fetch_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//Page Imports
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/friend_page.dart';
import 'profile/login_screen.dart';
import 'profile/profile_picture_selection.dart';
import 'profile/profile_settings.dart';
import 'pages/calendar.dart';
import 'pages/study_mode.dart';
import 'pages/app_limits_page.dart';
import 'apps_list.dart';
import 'pages/graph/colors.dart';

//Global Variables
//Native Kotlin method channel
const platformChannel = MethodChannel('kotlin.methods/procrastihater');
//Maps for reading/writing data from the database
Map<String, Map<String, String>> screenTimeData = {};
//Permission variables for screen time usage permission
bool hasPermission = false;
bool hasNotifsPermission = false;

//Firestore Connection Variables
final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;
final CollectionReference mainCollection = firestore.collection('UID');
String? uid = auth.currentUser?.uid;
//Reference to user's document in Firestore
DocumentReference userRef = mainCollection.doc(uid);

const Color darkBlue = Color.fromRGBO(10, 27, 46, 1);
const Color lightBlue = Color.fromRGBO(14, 40, 77, 1);
const Color beige = Color.fromARGB(255, 229, 214, 160);
const Color lightBeige = Color.fromARGB(255, 208, 196, 153);

///*********************************
/// Name: main
///
/// Description: Initializes Firebase,
///
/// launches the main app and instantiates
/// all neccesary connections and permissions
///*********************************
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Firebase initialization
  await Firebase.initializeApp();
  await initializeMain();
  runApp(const ProcrastiHater());

}

Future<void> initializeMain() async {
  await checkNotifsPermission();
  if (auth.currentUser != null) {
    await _currentToHistorical();
    await _checkSTPermission();
    await _getScreenTime();
    await getAvailableWeeks();
    await fetchWeeklyScreenTime();
    await generateAppsList();
    await initializeAppNameColorMapping();
    await _writeScreenTimeData();
 }
}

///*********************************
/// Name: MyApp
///
/// Description: Root stateless widget of
/// the app, builds naviagation tree for app
///*********************************
class ProcrastiHater extends StatelessWidget {
  const ProcrastiHater({super.key});

  @override
  //Main material app for app
  Widget build(BuildContext context) {
    double? screenWidth = MediaQuery.of(context).size.width;
    double? screenHeight = MediaQuery.of(context).size.height;
    return MaterialApp(
      theme: ThemeData(
        //brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBlue,
        //canvasColor: beige,
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: beige,
          onPrimary: lightBlue,
          primaryContainer: beige,
          surface: lightBlue,
          onSurface: beige,
          outline: lightBeige,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: beige),
          displayMedium: TextStyle(color: beige),
          displaySmall: TextStyle(color: beige),
          headlineLarge: TextStyle(color: beige),
          headlineMedium: TextStyle(color: beige),
          headlineSmall: TextStyle(color: beige),
          titleLarge: TextStyle(color: beige),
          titleMedium: TextStyle(color: beige),
          titleSmall: TextStyle(color: lightBeige),
          bodyLarge: TextStyle(color: lightBeige),
          bodyMedium: TextStyle(color: lightBeige),
          bodySmall: TextStyle(color: lightBeige),
          labelLarge: TextStyle(color: lightBeige),
          labelMedium: TextStyle(color: lightBeige),
          labelSmall: TextStyle(color: lightBeige),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          toolbarHeight: screenHeight * .06,
          backgroundColor: lightBlue,
          foregroundColor: beige,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightBlue,
            foregroundColor: beige,
          )
        ),
        dividerTheme: DividerThemeData(
          color: Color(0xFFC9D1D9),
          indent: 5,
          endIndent: 5,
          thickness: 1,
        ),
        cardTheme: CardThemeData(
          color: lightBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: darkBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
        home: StreamBuilder<User?>(
        // Listen to auth state changes instead of using a FutureBuilder
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          // If user is null (signed out), show login screen
          if (snapshot.data == null) {
            return const LoginScreen();
          }

          // If user is authenticated, initialize app data and show home page
          initializeMain();
          return const HomePage();
        },
      ),
      onGenerateRoute: _generateRoutes,
    );
  }

  Route<dynamic>? _generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      //Home page case builds default navigation
      case '/homePage':
        return MaterialPageRoute(
          builder: (context) => HomePage(),
          settings: settings,
        );
      //Leaderboard page case builds animated right swiping navigation
      case '/leaderBoardPage':
        return createSwipingRoute(LeaderBoardPage(), Offset(1.0, 0.0));
      //Leaderboard page back case builds animated left swiping navigation
      case '/leaderBoardPageBack':
        return createSwipingRoute(HomePage(), Offset(-1.0, 0.0));
      //Friends page case builds animated left swiping navigation
      case '/friendsPage':
        return createSwipingRoute(FriendsPage(), Offset(-1.0, 0.0));
      //Friends page back case builds animated right swiping navigation
      case '/friendsPageBack':
        return createSwipingRoute(HomePage(), Offset(1.0, 0.0));
      //Profile settings case builds default navigation
      case '/profileSettings':
        return MaterialPageRoute(
          builder: (context) => ProfileSettings(),
          settings: settings,
        );
      //Profile picture selection case builds default navigation
      case '/profilePictureSelection':
        return MaterialPageRoute(
          builder: (context) => ProfilePictureSelectionScreen(),
          settings: settings,
        );
      case '/studyModePage':
        return MaterialPageRoute(
          builder: (context) => StudyModePage(),
          settings: settings,
        );
      case '/calendarPage':
        return MaterialPageRoute(
          builder: (context) => CalendarPage(),
          settings: settings,
        );
      case '/appLimitsPage':
        return MaterialPageRoute(
          builder: (context) => AppLimitsPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
      }
    }
  }

  ///*********************************
  /// Name: createSwipingRoute
  ///
  /// Description: Function to build the
  /// navigation and swiping animation for
  /// main pages of the app
  ///*********************************
  Route createSwipingRoute(Widget page, Offset beginOffset) {
    return PageRouteBuilder(
        //Navigation for the page param
        pageBuilder: (context, animation, secondaryAnimation) => page,
        //Duration of the animation
        transitionDuration: Duration(milliseconds: 400),
        //Animation builder
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          //Animation style for swipe
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
          );
          //Tween variable for animation
          final tween = Tween(begin: beginOffset, end: Offset.zero)
              .chain(CurveTween(curve: Curves.fastEaseInToSlowEaseOut));
          //Actual slide transition variable
          return SlideTransition(
            position: curvedAnimation.drive(tween),
            //Fade transition for smoothness
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          );
        }
      );
  }


///**************************************************
/// Name: _updateUserRef
///
/// Description: Updates userRef to doc if the UID has changed
///***************************************************
void updateUserRef() {
  //Grab current UID
  var curUid = uid;
  //Regrab UID in case it's changed
  uid = auth.currentUser?.uid;
  //Update user reference if UID has changed
  if (curUid != uid) {
    userRef = mainCollection.doc(uid);
  }
}

///*********************************
/// Name: _checkSTPermission
///
/// Description: Invokes method from platform channel
/// to check for screetime usage permissions
///*********************************
Future<void> _checkSTPermission() async {
  try {
    final bool _hasPermission =
        await platformChannel.invokeMethod('checkScreenTimePermission');
    hasPermission = _hasPermission;
  } on PlatformException catch (e) {
    debugPrint("Failed to check permission: ${e.message}");
  }
}

///*******************************************************
/// Name: _currentToHistorical
///
/// Description: Moves data from the current collection to
/// history in Firestore
///********************************************************
Future<void> _currentToHistorical() async {
  updateUserRef();

  //Temp map for saving current data from database
  Map<String, Map<String, dynamic>> fetchedData = {};

  DateTime currentTime = DateTime.now();
  DateTime dateUpdated;
  bool needToMoveData = false;
  //Grab data from current
  try {
    final current = userRef.collection('appUsageCurrent');
    final curSnapshot = await current.get();
    //Loop to access all current screentime data from user
    for (var doc in curSnapshot.docs) {
      String docName = doc.id;
      double? hours = doc['dailyHours']?.toDouble();
      Timestamp timestamp = doc['lastUpdated'];
      dateUpdated = timestamp.toDate();
      String category = doc['appType'];
      if (hours != null) {
        fetchedData[docName] = {
          'dailyHours': hours,
          'lastUpdated': timestamp,
          'appType': category
        };
      }
      //Check if any data needs to be written to history
      if (dateUpdated.day != currentTime.day ||
          dateUpdated.month != currentTime.month ||
          dateUpdated.year != currentTime.year) {
        needToMoveData = true;
      }
    }
  } catch (e) {
    debugPrint("error fetching screentime data: $e");
  }

  //If any data needs to be written to history
  if (needToMoveData) {
    //Create batch
    var batch = firestore.batch();
    double totalDaily = 0.0;
    double totalWeekly = 0.0;
    DocumentSnapshot<Map<String, dynamic>>? histSnapshot;
    try {
      // Iterate through each app and its screen time
      for (var appMap in fetchedData.entries) {
        double screenTimeHours = appMap.value['dailyHours'];
        Timestamp timestamp = appMap.value['lastUpdated'];
        String category = appMap.value['appType'];
        // Reference to the document with app name
        DateTime dateUpdated = timestamp.toDate();
        DateTime currentTime = DateTime.now();
        //Check if date has changed since database was updated
        if (dateUpdated.day != currentTime.day ||
            dateUpdated.month != currentTime.month ||
            dateUpdated.year != currentTime.year) {
          //Gets the number of the day of the week for the last update day
          int dayOfWeekNum = dateUpdated.weekday;
          //Gets the name of the day of the week for last update day
          String dayOfWeekStr = DateFormat('EEEE').format(dateUpdated);
          //Gets the start of that week
          String startOfWeek = DateFormat('MM-dd-yyyy')
              .format(dateUpdated.subtract(Duration(days: dayOfWeekNum - 1)));
          var historical =
              userRef.collection('appUsageHistory').doc(startOfWeek);
          histSnapshot ??= await historical.get();
          if (totalWeekly == 0.0 &&
              histSnapshot.data() != null &&
              histSnapshot.data()!.containsKey('totalWeeklyHours')) {
            totalWeekly = histSnapshot['totalWeeklyHours'].toDouble();
          }
          totalDaily += screenTimeHours;
          totalWeekly += screenTimeHours;
          // Move data to historical
          batch.set(
            historical,
            {
              dayOfWeekStr: {
                appMap.key: {
                  'hours': screenTimeHours,
                  'lastUpdated': dateUpdated,
                  'appType': category
                },
                'totalDailyHours': (totalDaily * 100).round().toDouble() / 100
              },
              'totalWeeklyHours': (totalWeekly * 100).round().toDouble() / 100
            },
            SetOptions(merge: true),
          );
        }
      }

      //Commit the batch
      await batch.commit();

      debugPrint('Successfully wrote screen time data to History');
    } catch (e) {
      debugPrint('Error writing screen time data to Firestore: $e');
      rethrow;
    }
  } else {
    debugPrint('No data needed to be written to history');
  }
}

///*********************************
/// Name: _requestSTPermission
///
/// Description: Invokes method from platform channel to
/// send a request for screentime usage permissions
///*********************************
Future<void> _requestSTPermission() async {
  try {
    await platformChannel.invokeMethod('requestScreenTimePermission');
    await _checkSTPermission();
  } on PlatformException catch (e) {
    debugPrint("Failed to request permission: ${e.message}");
  }
}

///*********************************
/// Name: checkNotifsPermission
///
/// Description: Invokes method from platform channel
/// to check for notification permissions
///*********************************
Future<void> checkNotifsPermission() async {
  try {
    final bool _hasNotifsPermission =
        await platformChannel.invokeMethod('checkNotificationsPermission');
    hasNotifsPermission = _hasNotifsPermission;
  } on PlatformException catch (e) {
    debugPrint("Failed to check permission: ${e.message}");
  }
}

///*********************************
/// Name: requestNotifsPermission
///
/// Description: Invokes method from platform channel to
/// send a request for notification permissions
///*********************************
Future<void> requestNotifsPermission() async {
  try {
    await platformChannel.invokeMethod('requestNotificationsPermission');
    await checkNotifsPermission();
  } on PlatformException catch (e) {
    debugPrint("Failed to request permission: ${e.message}");
  }
}

///*********************************
/// Name: _startTestNotifications
///
/// Description: Invokes method from platform channel to
/// start sending the test notification
///*********************************
Future<void> _startTestNotifications() async {
  if (!hasNotifsPermission) {
    return;
  }
  try {
    await platformChannel.invokeMethod('startTestNotifications');
  } on PlatformException catch (e) {
    debugPrint("Failed to start notifications: ${e.message}");
  }
}

///*********************************
/// Name: _getScreenTime
///
/// Description: Accesses screentime data
/// by storing into a Map.
///*********************************
Future<void> _getScreenTime() async {
  //Checks if user has permission, if not it requests the permissions
  if (!hasPermission) {
    await _requestSTPermission();
    return;
  }

  try {
    //Raw data from screentime method of platform channel
    final Map<dynamic, dynamic> result =
        await platformChannel.invokeMethod('getScreenTime');
    //Convert data obtained by kotlin method to dart equivalent
    screenTimeData = Map<String, Map<String, String>>.from(
      result.map((key, value) =>
          MapEntry(key as String, Map<String, String>.from(value))),
    );
    debugPrint('Got screen time!');
  } on PlatformException catch (e) {
    debugPrint("Failed to get screen time: ${e.message}");
  }
}

///**************************************************
/// Name: _writeScreenTimeData
///
/// Description: Takes the data
/// that was accessed in _getScreenTime
/// and writes it to the Firestore database
/// using batches for multiple writes
///***************************************************
Future<void> _writeScreenTimeData() async {
  //Update ref to user's doc if UID has changed
  updateUserRef();
  if (screenTimeData.isNotEmpty) {
    double totalDaily = 0.0;
    final current = userRef.collection('appUsageCurrent');
    // Create a batch to handle multiple writes
    final batch = firestore.batch();
    try {
      //Purge old data
      final currentSnap = await current.get();
      for (final doc in currentSnap.docs) {
        batch.delete(doc.reference);
      }
      // Iterate through each app and its screen time
      for (final entry in screenTimeData.entries) {
        final appName = entry.key;
        final screenTimeHours = double.parse(entry.value['hours']!);
        final category = entry.value['category'];
        totalDaily += screenTimeHours;

        // Reference to the document with app name
        final docRef = current.doc(appName);

        // Set the data with merge option to update existing documents
        // or create new ones if they don't exist
        batch.set(
          docRef,
          {
            'dailyHours': screenTimeHours,
            'lastUpdated': FieldValue.serverTimestamp(),
            'appType': category
          },
          SetOptions(merge: true),
        );
      }
      //Put user's daily hours in their doc
      batch.set(
        userRef,
        {
          'totalDailyHours': (totalDaily * 100).round().toDouble() / 100,
          'lastUpdated': FieldValue.serverTimestamp()
        },
        SetOptions(merge: true),
      );
      // Commit the batch
      await batch.commit();
      debugPrint('Successfully wrote screentime data');
    } catch (e) {
      debugPrint('Error writing screen time data to Firestore: $e');
      rethrow;
    }
  }
}
