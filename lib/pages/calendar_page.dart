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
  String? title;
  String? description;
  String? location;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {
        title = _titleController.text;
      });
    });
    _descriptionController.addListener(() {
      setState(() {
        description = _descriptionController.text;
      });
    });
    _locationController.addListener(() {
      setState(() {
        location = _locationController.text;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Event buildEvent({Recurrence? recurrence}) {
    return Event(
      title: title ?? 'Test event',
      description: description ?? 'example',
      location: location ?? 'Flutter app',
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
      appBar: AppBar(title: const Text('ProcrastiPlanner')),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Event Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Event Location',
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await showOmniDateTimePicker(
                    context: context, is24HourMode: true);
                setState(() {
                  dateTime = result;
                });
                debugPrint('dateTime: $dateTime');
              },
              child: const Text('Select Event Time'),
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
