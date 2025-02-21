///*********************************
/// Name: calendar_page.dart
///
/// Description: Allows the user to
/// specify dates and times to be
/// blocked off in their device calendar
///*******************************
library;

//Dart Imports
import 'package:flutter/material.dart';

//Calendar Imports
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime? dateTime;
  List<DateTime>? dateTimeRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await showOmniDateTimePicker(context: context);
                setState(() {
                  dateTime = result;
                });
                // Use dateTime here
                debugPrint('dateTime: $dateTime');
              },
              child: const Text('Show DateTime Picker'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result =
                    await showOmniDateTimeRangePicker(context: context);
                setState(() {
                  dateTimeRange = result;
                });
                debugPrint('dateTime: $dateTime');
              },
              child: const Text('Open Calendar'),
            ),
            if (dateTime != null)
              Text(
                'Selected Date: ${dateTime!.toString()}',
                style: const TextStyle(fontSize: 16),
              ),
            if (dateTimeRange != null)
              Text(
                'Selected Range: ${dateTimeRange!.map((date) => date.toString()).join(" to ")}',
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
