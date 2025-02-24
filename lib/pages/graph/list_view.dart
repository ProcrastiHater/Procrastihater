///*********************************
/// Name: list_view.dart
///
/// Description: 
///*******************************
library;

import 'package:app_screen_time/pages/graph/fetch_data.dart';
import 'package:flutter/material.dart';


///*********************************
/// Name: ExpandedListView
/// 
/// Description: Root stateful widget
/// for ExpandedListView
///*********************************
class ExpandedListView extends StatefulWidget {
  final String selectedBar;
  final Map<String, Color> appColors;
  const ExpandedListView(
      {super.key, required this.selectedBar, required this.appColors});
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
  //Load text as placeholder while waiting for bar touch
  Widget build(BuildContext context) {
    if (widget.selectedBar == "null") {
      return Center(
        child: Text("Select a day to view",
            style: const TextStyle(
              decoration: TextDecoration.none,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            )),
      );
    }

    //Load loading screen if data is empty
    if (!weeklyData.containsKey(widget.selectedBar)) {
      if (weeklyData.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }  
      return Center(
          child: Text("No data available for ${widget.selectedBar}",
              style: const TextStyle(
                decoration: TextDecoration.none,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )
           )
        );
      }

    //List view built of daily data from bar touch
    final dayData = weeklyData[widget.selectedBar]!;
    final reversedEntries = dayData.entries.toList().reversed.toList();
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: dayData.length,
      itemBuilder: (context, index) {
        final entry = reversedEntries.elementAt(index);
        final appName = entry.key;
        final appHours = entry.value['hours'];
        final appType = entry.value['appType'];
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
      },
    );
  }
}
