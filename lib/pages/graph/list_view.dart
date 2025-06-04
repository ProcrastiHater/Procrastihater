///*********************************
/// Name: list_view.dart
///
/// Description: File for holding
/// list view class for easy switching
/// between different list views
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//Page Imports
import '/pages/graph/fetch_data.dart';
import '/pages/graph/graph.dart';
import '/main.dart';

///*********************************
/// Name: ExpandedListView
///
/// Description: Root stateful widget
/// for ExpandedListView
///*********************************
class ExpandedListView extends StatefulWidget {
  final String selectedBar;
  final Map<String, Color> appColors;
  final int graphIndex;
  final Map<String, Map<String, String>> dayFilteredData;
  final Map<String, Map<String, Map<String, dynamic>>> weekFilteredData;
  const ExpandedListView(
      {super.key,
      required this.selectedBar,
      required this.appColors,
      required this.graphIndex,
      required this.dayFilteredData,
      required this.weekFilteredData});
  @override
  State<ExpandedListView> createState() => _ExpandedListViewState();
}

///*********************************
/// Name: _MyExpandedListViewState
///
/// Description: Root stateful widget
/// for ExpandedListView
///*********************************
class _ExpandedListViewState extends State<ExpandedListView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.graphIndex) {
      //Daily list view
      case 0:
        //Return loading icon if no data is present
        if (widget.dayFilteredData.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        //Data to be displayed
        Map<String, Map<String, String>> dayData = widget.dayFilteredData;
        final entries = dayData.entries.toList();
        //Builder to display list
        return ListView.builder(
          //Builds from the top of parent widget
          padding: EdgeInsets.zero,
          //Data tiles plus 1 for title
          itemCount: dayData.length + 1,
          //Data tile builder
          itemBuilder: (context, index) {
            //Display title if first tile
            if (index == 0) {
              return Center(
                child: Text(
                  "Daily Hours",
                  style: TextStyle(fontSize: 22),
                ),
              );
            }
            //Build data tile
            else {
              final entry = entries.elementAt(index - 1);
              final appName = entry.key;
              final appHours = entry.value['hours'];
              String? appType = entry.value['category'];
              //Animated Data tile
              return TweenAnimationBuilder(
                //Slide up animation based on offset
                tween: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero),
                duration: Duration(milliseconds: 300 + index * 50),
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset * 100,
                    child: Opacity(
                      opacity: 1.0 - offset.dy,
                      child: ListTile(
                        title: Text(
                          appName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.appColors[appName],
                          ),
                        ),
                        subtitle: Text('$appHours hours'),
                        trailing: Text(appType!),
                      ),
                    ),
                  );
                },
              );
            }
          },
        );
      //Weekly list view
      case 1:
        if (widget.selectedBar == "null") {
          return Center(
            child: Text(
              "Select a bar to expand",
              style: const TextStyle(
                decoration: TextDecoration.none,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          );
        }
        //Load loading screen if data is empty
        if (!weeklyData.containsKey(widget.selectedBar)) {
          //Return text string if the selected bar does not contain data
          return Center(
            child: Text(
              "No data available for ${widget.selectedBar}",
              style: const TextStyle(
                decoration: TextDecoration.none,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          );
        }
        //Data to be displayed
        final weekData = widget.weekFilteredData;
        final dayData = weekData[widget.selectedBar]!;
        final reversedEntries = dayData.entries.toList().reversed.toList();
        //Builder to display list
        return ListView.builder(
          //Builds from the top of parent widget
          padding: EdgeInsets.zero,
          //Data tiles plus 1 for title
          itemCount: dayData.length + 1,
          //Data tile builder
          itemBuilder: (context, index) {
            //Display title if first tile
            if (index == 0) {
              return Center(
                child: Text(
                  /*"${DateFormat('MM-dd-yyyy').format(currentDataset)}:*/ "${widget.selectedBar} Hours",
                  style: TextStyle(fontSize: 22),
                ),
              );
            }
            //Build data tile
            else {
              final entry = reversedEntries.elementAt(index - 1);
              final appName = entry.key;
              final appHours = entry.value['hours'];
              final appType = entry.value['appType'];
              //Animated Data tile
              return TweenAnimationBuilder(
                //Slide up animation based on offset
                tween: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero),
                duration: Duration(milliseconds: 300 + index * 100),
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset * 100,
                    child: Opacity(
                      opacity: 1.0 - offset.dy,
                      child: ListTile(
                        title: Text(
                          appName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.appColors[appName],
                          ),
                        ),
                        subtitle: Text('$appHours hours'),
                        trailing: Text(appType),
                      ),
                    ),
                  );
                },
              );
            }
          },
        );
      default:
        return Center(child: CircularProgressIndicator());
    }
  }
}
