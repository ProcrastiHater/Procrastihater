///*********************************
/// Name: graph.dart
///
/// Description: File for holding
/// graph classes for easy switching
/// between different graphs
///*******************************
library;

//Dart imports
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//Plugin imports
import 'package:fl_chart/fl_chart.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

//Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

//Page Imports
import '/main.dart';
import '/profile/profile_settings.dart';
import '/pages/graph/fetch_data.dart';
import '/pages/graph/list_view.dart';
import '/pages/graph/widget.dart';
import '/pages/graph/colors.dart';

//Global Variables
Map<String, Map<String, String>> dailyData = {};

///*********************************
/// Name: WeeklyGraphView
///
/// Description: Stateful widget for
/// weekly state
///*********************************
class WeeklyGraphView extends StatefulWidget {
  final Function(String) onBarSelected;
  final Function(Map<String, Map<String, Map<String, dynamic>>>) onFilteredData;
  const WeeklyGraphView(
      {super.key, required this.onBarSelected, required this.onFilteredData});

  @override
  State<WeeklyGraphView> createState() => _WeeklyGraphViewState();
}

///*********************************
/// Name: _WeeklyGraphViewState
///
/// Description: State for WeeklyGraphView,
/// holds layout and state management for
/// weekly graph
///*********************************
class _WeeklyGraphViewState extends State<WeeklyGraphView> {
  //Variables for filtered data
  List<String> selectedCategories = [];
  List<String> selectedApps = [];
  String? selectedFilter = "";

  //Varaibles for week scrolling data
  Map<String, Map<String, Map<String, dynamic>>> weekData = {};
  String currentWeek = DateFormat('MM-dd-yyyy').format(currentDataset);
  bool isLoading = false;

  //Wrapper for loading bar touch,
  BarTouchData loadTouch(Map<String, Map<String, Map<String, dynamic>>> data) {
    return getBarWeekTouch(data, widget.onBarSelected);
  }

  //Asynchronous function for initializing data
  Future<void> initWeeklyData() async {
    await fetchWeeklyScreenTime();
    //Do not run following code if the build context is mounted
    if (!mounted) return;
    //Reload page with updated data
    setState(() {
      weekData = weeklyData;
      availableDays = weekData.keys.toList();
      widget.onFilteredData(weekData);
    });
  }

  //Initial state for view
  @override
  void initState() {
    super.initState();
    if (availableWeekKeys.isNotEmpty) {
      formattedCurrent = availableWeekKeys.last;
      currentWeek = formattedCurrent;
      currentDataset = DateFormat('MM-dd-yyyy').parse(currentWeek);
    }
    initWeeklyData();
  }

  //Filter function for data
  Map<String, Map<String, Map<String, dynamic>>> filterData() {
    //Member for holding filtered data
    Map<String, Map<String, Map<String, dynamic>>> filteredData = {};
    //Fill member with unfiltered data
    weeklyData.forEach((dayKey, dayData) {
      Map<String, Map<String, dynamic>> appsMap = {};
      dayData.forEach((appKey, appData) {
        appsMap[appKey] = Map<String, dynamic>.from(appData);
      });
      filteredData[dayKey] = appsMap;
    });

    //Dropdown Multi-Select Search filtering for individual apps
    if (selectedApps.isNotEmpty) {
      filteredData.forEach((dayKey, dayData) {
        dayData.removeWhere((appKey, appData) {
          String? appName = appKey as String?;
          return appName == null || !selectedApps.contains(appName);
        });
      });
    }

    //Multi-Select filtering for selecting one or more categories
    if (selectedCategories.isNotEmpty) {
      filteredData.forEach((dayKey, dayData) {
        dayData.removeWhere((appKey, appData) {
          String? category = appData['appType'] as String?;
          return category == null || !selectedCategories.contains(category);
        });
      });
    }

    //Filtering options for sorting data
    filteredData.forEach((dayKey, appsKey) {
      //Convert the map to list of entries for sorting
      final entries = appsKey.entries.toList();
      switch (selectedFilter) {
        case 'Alphabet(asc)':
          entries.sort((a, b) => a.key.compareTo(b.key));
          break;
        case 'Alphabet(desc)':
          entries.sort((a, b) => b.key.compareTo(a.key));
          break;
        case 'Hours(asc)':
          entries
              .sort((a, b) => (a.value['hours'])!.compareTo(b.value['hours']!));
          break;
        case 'Hours(desc)':
          entries
              .sort((a, b) => (b.value['hours'])!.compareTo(a.value['hours']!));
          break;
        default:
          break;
      }
      //Convert list of entries back into map
      filteredData[dayKey] =
          Map<String, Map<String, dynamic>>.fromEntries(entries);
    });
    return filteredData;
  }

  //Weekly graph view widget tree
  @override
  Widget build(BuildContext context) {
    //Height of users phone
    double? screenWidth = MediaQuery.of(context).size.width;
    //Display loading indicator while async function returns
    if (weekData.isEmpty) {
      return Center(child: Text("No Weekly Data"));
    }
    return Padding(
        padding: const EdgeInsets.all(4.0),
        //Column structure for home page
        child: Column(
          children: [
            //Filter for individual apps
            CustomDropdown.multiSelectSearch(
              decoration: CustomDropdownDecoration(
                closedFillColor: lightBlue,
                expandedFillColor: lightBlue,
                searchFieldDecoration: SearchFieldDecoration(
                  textStyle: TextStyle(color: lightBeige),
                  fillColor: darkBlue,
                ),
                listItemDecoration: ListItemDecoration(
                  highlightColor: darkBlue,
                  selectedColor: darkBlue,
                ),
              ),
              closedHeaderPadding: EdgeInsets.all(8.0),
              expandedHeaderPadding: EdgeInsets.all(8.0),
              //Options to select for this dropdown
              items: appNameToColor.keys.toList(),
              //Text displayed when no options are selected
              hintBuilder: (context, hint, enabled) {
                return Text(
                  "All Apps",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0,
                  ),
                );
              },
              //Filter the data on click and rerender all elements holding data
              onListChanged: (value) {
                setState(() {
                  selectedApps = value;
                  weekData = filterData();
                  availableDays = weekData.keys.toList();
                  widget.onFilteredData(weekData);
                });
              },
            ),
            //Row structure for other filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Filter for categories
                Expanded(
                  child: CustomDropdown.multiSelect(
                      decoration: CustomDropdownDecoration(
                          closedFillColor: lightBlue,
                          expandedFillColor: lightBlue,
                          listItemDecoration: ListItemDecoration(
                            highlightColor: darkBlue,
                            selectedColor: darkBlue,
                          )),
                      overlayHeight: 525,
                      closedHeaderPadding: EdgeInsets.all(8.0),
                      expandedHeaderPadding: EdgeInsets.all(8.0),
                      //Options to select for this dropdown
                      items: categories,
                      //Text displayed when no options are selected
                      hintBuilder: (context, hint, enabled) {
                        return Text(
                          "All Categories",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                          ),
                        );
                      },
                      //Filter the data on click and rerender all elements holding data
                      onListChanged: (value) {
                        setState(() {
                          selectedCategories = value;
                          weekData = filterData();
                          availableDays = weekData.keys.toList();
                          widget.onFilteredData(weekData);
                        });
                      }),
                ),
                //Filters for data sorting
                Expanded(
                  child: CustomDropdown(
                      decoration: CustomDropdownDecoration(
                        closedFillColor: lightBlue,
                        expandedFillColor: lightBlue,
                        listItemDecoration: ListItemDecoration(
                          highlightColor: darkBlue,
                          selectedColor: darkBlue,
                        ),
                      ),
                      closedHeaderPadding: EdgeInsets.all(8.0),
                      expandedHeaderPadding: EdgeInsets.all(8.0),
                      items: filters,
                      hintBuilder: (context, hint, enabled) {
                        return Text(
                          "Filters",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                          ),
                        );
                      },
                      //Filter the data on click and rerender all elements holding data
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value;
                          weekData = filterData();
                          availableDays = weekData.keys.toList();
                          widget.onFilteredData(weekData);
                        });
                      }),
                ),
              ],
            ),
            //Graph Title
            Text(
              "Historical Phone Usage",
              style: TextStyle(fontSize: 18),
            ),
            Expanded(
              child: SizedBox(
                width: screenWidth - (screenWidth * 0.05),
                child: BarChart(BarChartData(
                  maxY: tallestDayBar(weekData),
                  groupsSpace: 60,
                  alignment: BarChartAlignment.spaceAround,
                  backgroundColor: lightBlue,
                  //Title Widgets
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                      maxIncluded: true,
                      showTitles: true,
                      interval: 1,
                      reservedSize: 20,
                      getTitlesWidget: sideTitles,
                    )),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                      maxIncluded: true,
                      showTitles: true,
                      interval: 1,
                      reservedSize: 20,
                      getTitlesWidget: sideTitles,
                    )),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: bottomDayTitles,
                      reservedSize: 20,
                    )),
                  ),
                  //Style Widgets
                  borderData: FlBorderData(
                      border: Border.all(
                        color: beige,
                        width: 2,
                      ),
                      show: true),
                  gridData: FlGridData(
                    show: false,
                  ),
                  //Functionality Widgets
                  barTouchData: loadTouch(weekData),
                  barGroups: generateWeeklyChart(weekData),
                )),
              ),
            ),
            Row(
              //Equal spacing between children
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                //Previous arrow button
                IconButton(
                  onPressed: availableWeekKeys.isNotEmpty &&
                          availableWeekKeys.indexOf(currentWeek) > 0 &&
                          !isLoading
                      ? () async {
                          setState(() {
                            isLoading = true;
                          });
                          int currentIndex =
                              availableWeekKeys.indexOf(currentWeek);
                          currentWeek = availableWeekKeys[currentIndex - 1];
                          currentDataset =
                              DateFormat('MM-dd-yyyy').parse(currentWeek);
                          await fetchWeeklyScreenTime();
                          weekData = filterData();
                          availableDays = weekData.keys.toList();
                          widget.onFilteredData(weekData);
                          setState(() {
                            isLoading = false;
                          });
                        }
                      : null,
                  icon: Icon(Icons.arrow_back),
                ),
                Text(currentWeek),
                //Next arrow button
                IconButton(
                  onPressed: availableWeekKeys.isNotEmpty &&
                          availableWeekKeys.indexOf(currentWeek) <
                              availableWeekKeys.length - 1 &&
                          !isLoading
                      ? () async {
                          setState(() {
                            isLoading = true;
                          });
                          int currentIndex =
                              availableWeekKeys.indexOf(currentWeek);
                          currentWeek = availableWeekKeys[currentIndex + 1];
                          currentDataset =
                              DateFormat('MM-dd-yyyy').parse(currentWeek);
                          await fetchWeeklyScreenTime();
                          weekData = filterData();
                          availableDays = weekData.keys.toList();
                          widget.onFilteredData(weekData);
                          setState(() {
                            isLoading = false;
                          });
                        }
                      : null,
                  icon: Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ));
  }
}

///*********************************
/// Name: DailyGraphView
///
/// Description: Stateful widget for
/// daily state
///*********************************
class DailyGraphView extends StatefulWidget {
  final Map<String, Map<String, String>> data;
  final Function(Map<String, Map<String, String>>) onFilteredData;
  const DailyGraphView(
      {super.key, required this.onFilteredData, required this.data});

  @override
  State<DailyGraphView> createState() => _DailyGraphViewState();
}

///*********************************
/// Name: _DailyGraphViewState
///
/// Description: State for DailyGraphView,
/// holds layout and state management for
/// daily graph
///*********************************
class _DailyGraphViewState extends State<DailyGraphView> {
  List<String> selectedCategories = [];
  Map<String, Map<String, String>> dailyData = {};
  String? selectedFilter = "";
  double totalDaily = 0;
  int points = 0;

  @override
  //Initialize colors making sure all apps are mapped to a color before displaying
  void initState() {
    super.initState();
    _initializeData();
    dailyData = screenTimeData;
  }

  @override
  void didUpdateWidget(covariant DailyGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      setState(() {
        dailyData = widget.data;
        availableApps = dailyData.keys.toList();
      });
    }
  }

  Future<void> _initializeData() async {
    totalDaily = await fetchTotalDayScreentime();
    points = await fetchPoints();
    if (!mounted) return;
    setState(() {
      availableApps = screenTimeData.keys.toList();
    });
  }

  Map<String, Map<String, String>> filterData() {
    Map<String, Map<String, String>> filteredData =
        Map<String, Map<String, String>>.from(screenTimeData);
    if (selectedCategories.isNotEmpty) {
      filteredData.removeWhere((key, value) {
        String? category = value['category'];
        return category == null || !selectedCategories.contains(category);
      });
    }
    final entries = filteredData.entries.toList();
    switch (selectedFilter) {
      case 'Alphabet(asc)':
        entries.sort((a, b) => a.key.compareTo(b.key));
        break;
      case 'Alphabet(desc)':
        entries.sort((a, b) => b.key.compareTo(a.key));
        break;
      case 'Hours(asc)':
        entries
            .sort((a, b) => (a.value['hours'])!.compareTo(b.value['hours']!));
        break;
      case 'Hours(desc)':
        entries
            .sort((a, b) => (b.value['hours'])!.compareTo(a.value['hours']!));
        break;
      default:
        break;
    }
    return Map<String, Map<String, String>>.fromEntries(entries);
  }

  //Wrapper for loading bar touch
  BarTouchData loadTouch(Map<String, Map<String, String>> data) {
    return getBarDayTouch(data);
  }

  @override
  Widget build(BuildContext context) {
    double? screenWidth = MediaQuery.of(context).size.width;
    return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomDropdown.multiSelect(
                    decoration: CustomDropdownDecoration(
                      closedFillColor: lightBlue,
                      expandedFillColor: lightBlue,
                      listItemDecoration: ListItemDecoration(
                        highlightColor: darkBlue,
                        selectedColor: darkBlue,
                      ),
                    ),
                    items: categories,
                    overlayHeight: 525,
                    closedHeaderPadding: EdgeInsets.all(8.0),
                    expandedHeaderPadding: EdgeInsets.all(8.0),
                    hintBuilder: (context, hint, enabled) {
                      return Text(
                        "All Categories",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16.0,
                        ),
                      );
                    },
                    onListChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          selectedCategories = [];
                          dailyData = screenTimeData;
                          availableApps = dailyData.keys.toList();
                          widget.onFilteredData(dailyData);
                        });
                      } else {
                        setState(() {
                          selectedCategories = value;
                          dailyData = filterData();
                          availableApps = dailyData.keys.toList();
                          widget.onFilteredData(dailyData);
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: CustomDropdown(
                      decoration: CustomDropdownDecoration(
                        closedFillColor: lightBlue,
                        expandedFillColor: lightBlue,
                        listItemDecoration: ListItemDecoration(
                          highlightColor: darkBlue,
                          selectedColor: darkBlue,
                        ),
                      ),
                      closedHeaderPadding: EdgeInsets.all(8.0),
                      expandedHeaderPadding: EdgeInsets.all(8.0),
                      items: filters,
                      hintBuilder: (context, hint, enabled) {
                        return Text(
                          "Filters",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                          ),
                        );
                      },
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value;
                          dailyData = filterData();
                          availableApps = dailyData.keys.toList();
                          widget.onFilteredData(dailyData);
                        });
                      }),
                )
              ],
            ),
            //Title for graph
            Text(
              "Current Phone Usage",
              style: TextStyle(fontSize: 18),
            ),
            Expanded(
              //Widget to allow scrolling of graph if it overflows the screen
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    //Sets a minimum size for graph
                    constraints: BoxConstraints(
                        minWidth: screenWidth - (screenWidth * 0.05)),
                    child: SizedBox(
                        //Dynamically size graph based on amount of apps
                        width: 100 + availableApps.length * 70,
                        child: BarChart(BarChartData(
                          maxY: tallestAppBar(dailyData),
                          groupsSpace: 60,
                          alignment: BarChartAlignment.spaceAround,
                          backgroundColor: lightBlue,
                          //Title Widgets
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                              maxIncluded: true,
                              showTitles: true,
                              interval: 1,
                              reservedSize: 20,
                              getTitlesWidget: sideTitles,
                            )),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                              maxIncluded: true,
                              showTitles: true,
                              interval: 1,
                              reservedSize: 20,
                              getTitlesWidget: sideTitles,
                            )),
                            topTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: bottomAppTitles,
                              reservedSize: 25,
                            )),
                          ),
                          //Style Widgets
                          borderData: FlBorderData(
                              border: Border.all(
                                color: beige,
                                width: 2,
                              ),
                              show: true),
                          gridData: FlGridData(
                            show: false,
                          ),
                          //Functionality Widgets
                          barTouchData: loadTouch(dailyData),
                          barGroups: generateDailyChart(dailyData),
                        ))),
                  )),
            ),
            Text(
              "Today's Procrastination Total:",
            ),
            Text("Hours: $totalDaily | Points: $points"),
          ],
        ));
  }
}
