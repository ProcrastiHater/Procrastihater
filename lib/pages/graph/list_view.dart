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
  const ExpandedListView({super.key, required this.selectedBar, required this.appColors, required this.graphIndex});
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
  Widget build(BuildContext context) {
    switch(widget.graphIndex) {
      //Daily list view
      case 0:
      //Return loading icon if no data is present
        if (screenTimeData.isEmpty) {
          return Center(child: CircularProgressIndicator());
        } 
        //Data to be displayed 
        final dayData = screenTimeData;
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
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    "Daily Data", 
                    style: TextStyle(fontSize: 22),
                  )
                ),
              );
            }
            //Build data tile
            else {
              final entry = entries.elementAt(index - 1);
              final appName = entry.key;
              final appHours = entry.value['hours'];
              String? appType = entry.value['category'];
              //Data tile
              return ListTile(
                title: Text(
                  appName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.appColors[appName],
                  ),
                ),
                subtitle: Text('$appHours hours'),
                trailing: Text(appType!),
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
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )
            ),
          );
        }
        //Load loading screen if data is empty
        if (!weeklyData.containsKey(widget.selectedBar)) {
          if (weeklyData.isEmpty) {
            return Center(child: CircularProgressIndicator());
          } 
          //Return text string if the selected bar does not contain data
          return Center(
            child: Text(
              "No data available for ${widget.selectedBar}",
              style: const TextStyle(
                decoration: TextDecoration.none,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )
            )
          );
        }
        //Data to be displayed 
        final dayData = weeklyData[widget.selectedBar]!;
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
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text("${DateFormat('MM-dd-yyyy').format(currentDataset)}: ${widget.selectedBar}", style: TextStyle(fontSize: 22),)),
              );
            }
            //Build data tile
            else {
              final entry = reversedEntries.elementAt(index - 1);
              final appName = entry.key;
              final appHours = entry.value['hours'];
              final appType = entry.value['appType'];
              //Data tile
              return ListTile(
                title: Text(
                  appName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.appColors[appName],
                  ),
                ),
                subtitle: Text('$appHours hours'),
                trailing: Text(appType),
              );
            }
          },
        );
      //Monthly list view
      case 2:
        return Center(child: Text("Monthly Graph Display"),);
        //Center(child: CircularProgressIndicator());
      default: 
        return Center(child: CircularProgressIndicator());
    }
  }
}
