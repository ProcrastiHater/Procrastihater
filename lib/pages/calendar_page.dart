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

//Other Imports
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final List<DateTime>? dateTime =
                    await showOmniDateTimeRangePicker(context: context);

                // Use dateTime here
                debugPrint('dateTime: $dateTime');
              },
              child: const Text('Open Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}
