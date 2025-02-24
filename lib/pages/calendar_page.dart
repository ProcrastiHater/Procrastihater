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
import 'package:add_2_calendar/add_2_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime? dateTime;
  List<DateTime>? dateTimeRange;

  Event buildEvent({Recurrence? recurrence}) {
    return Event(
      title: 'Test event',
      description: 'example',
      location: 'Flutter app',
      startDate: dateTime ?? DateTime.now(),
      endDate: (dateTime ?? DateTime.now()).add(const Duration(minutes: 30)),
      allDay: false,
      androidParams: const AndroidParams(
        emailInvites: ["test@example.com"],
      ),
      recurrence: recurrence,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await showOmniDateTimePicker(
                    context: context, is24HourMode: false);
                setState(() {
                  dateTime = result;
                });
                debugPrint('dateTime: $dateTime');
              },
              child: const Text('Show DateTime Picker'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showOmniDateTimeRangePicker(
                    context: context, is24HourMode: false);
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
                textAlign: TextAlign.center,
              ),
            if (dateTimeRange != null)
              Text(
                'Selected Range: ${dateTimeRange!.map((date) => date.toString()).join(" to ")}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ListTile(
              title: const Text('Add normal event'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () {
                Add2Calendar.addEvent2Cal(
                  buildEvent(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
