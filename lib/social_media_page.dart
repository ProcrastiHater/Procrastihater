///*********************************
/// Name: social_media_page.dart
///
/// Description: Social Media page file for
/// application
///*******************************

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Graphing Imports
import 'package:graphic/graphic.dart';

//Page Imports
import 'home_page.dart';

///*********************************
/// Name: SocialMediaPage
///
/// Description: Root stateless widget of
/// the SocialMediaPage, builds and displays
/// social media page view
/// Temporary residence of the daily app usage graph
///*********************************
class SocialMediaPage extends StatefulWidget {
  const SocialMediaPage({Key? key}) : super(key: key);
  @override
  State<SocialMediaPage> createState() => _SocialMediaPageState();
}

class _SocialMediaPageState extends State<SocialMediaPage> {
  //data to be used by the chart
  List<Map<String, dynamic>> chartData = [];
  //data to be used in the listview
  Map<String, List<Map<String, dynamic>>> categoryData = {};
  bool isLoading = true;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ///**************************************************
  /// Name: _loadData
  ///
  /// Description: calls _fetchscreentime and converts
  /// screentime data into a list of maps to be used by
  /// the graphic plugin and a map of list of maps to be
  /// used in the listview
  ///***************************************************
  Future<void> _loadData() async {
    try {
      // Get screentime data
      final data = await _fetchScreenTime();

      // Map to accumulate hours by category
      Map<String, double> categoryHours = {};

      // Other map for categorized apps
      Map<String, List<Map<String, dynamic>>> categorizedApps = {};

      // Process each app entry
      for (var entry in data.entries) {
        final category = entry.value['category'];
        final hours = entry.value['Hours'] as double;

        // Accumulate hours by category
        categoryHours[category] = (categoryHours[category] ?? 0) + hours;

        // Store app data in categorized list
        final appData = {'appName': entry.key, 'hours': hours};

        // Initialize category list if it doesn't exist
        if (!categorizedApps.containsKey(category)) {
          categorizedApps[category] = [];
        }

        // Add app data to its category
        categorizedApps[category]!.add(appData);
      }

      // Transform category hours into final chart format
      final transformedData = categoryHours.entries
          .map((entry) => {
                'Category': entry.key,
                'Hours': entry.value,
              })
          .toList();

      setState(() {
        chartData = transformedData;
        categoryData = categorizedApps;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading screen time data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleChartTap(TapDownDetails details, BoxConstraints constraints) {
    // Convert tap position to chart coordinates
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // Calculate which bar was tapped based on position
    final chartWidth = constraints.maxWidth;
    final barWidth = chartWidth / chartData.length;
    final tappedIndex = (localPosition.dx / barWidth).floor();

    if (tappedIndex >= 0 && tappedIndex < chartData.length) {
      setState(() {
        selectedCategory = chartData[tappedIndex]['Category'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Daily App Usage'),
        ),
        body: Container(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.indigo.shade50,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) =>
                            _handleChartTap(details, constraints),
                        child: Chart(
                          data: chartData,
                          variables: {
                            'App Category': Variable(
                              accessor: (Map map) => map['Category'] as String,
                            ),
                            'Hours': Variable(
                              accessor: (Map map) => map['Hours'] as num,
                            ),
                          },
                          marks: [
                            IntervalMark(
                              label: LabelEncode(
                                encoder: (tuple) =>
                                    Label(tuple['Hours'].toString()),
                              ),
                              elevation: ElevationEncode(
                                value: 0,
                                updaters: {
                                  'tap': {true: (_) => 5}
                                },
                              ),
                              color: ColorEncode(
                                value: const Color(0xFFFF8C00),
                                updaters: {
                                  'tap': {
                                    false: (color) => color.withAlpha(100)
                                  },
                                },
                              ),
                            ),
                          ],
                          axes: [
                            Defaults.horizontalAxis,
                            Defaults.verticalAxis,
                          ],
                          selections: {
                            'tap': PointSelection(
                              dim: Dim.x,
                              on: {GestureType.tap},
                            ),
                          },
                          tooltip: TooltipGuide(),
                          crosshair: CrosshairGuide(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.indigo.shade100,
                  child: selectedCategory == null
                      ? const Center(
                          child: Text(
                            "Select a category to view apps",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              categoryData[selectedCategory]?.length ?? 0,
                          itemBuilder: (context, index) {
                            final apps = categoryData[selectedCategory]!;
                            final app = apps[index];
                            return ListTile(
                              title: Text(
                                app['appName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('${app['hours']} hours'),
                              leading: const Icon(Icons.app_shortcut),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///**************************************************
/// Name: _fetchScreenTime
///
/// Description: Takes the data
/// from the Firestore database
/// and returns a map of maps
/// of the user's current screentime
///***************************************************
Future<Map<String, Map<String, dynamic>>> _fetchScreenTime() async {
  _updateUserRef();
  Map<String, Map<String, dynamic>> fetchedData = {};
  try {
    final CURRENT = userRef.collection("appUsageCurrent");
    final CUR_SNAPSHOT = await CURRENT.get();
    //Temp map for saving data from database
    //Loop to access all screentime data from hard coded user
    for (var doc in CUR_SNAPSHOT.docs) {
      String docName = doc.id;
      double? hours = doc['dailyHours']?.toDouble();
      String category = doc['appType'];
      if (hours != null) {
        fetchedData[docName] = {'Hours': hours, 'category': category};
      }
    }
  } catch (e) {
    debugPrint("error fetching screentime data: $e");
  }
  return fetchedData;
}

///**************************************************
/// Name: _updateUserRef
///
/// Description: Updates userRef to doc if the UID has changed
///***************************************************
void _updateUserRef() {
  //Grab current UID
  var curUid = uid;
  //Regrab UID in case it's changed
  uid = AUTH.currentUser?.uid;
  //Update user reference if UID has changed
  if (curUid != uid) {
    userRef = MAIN_COLLECTION.doc(uid);
  }
}
