///*********************************
/// Name: calendar_page.dart
///
/// Description: Allows the user to
/// specify dates and times to be
/// blocked off in their device calendar
///*******************************
library;

//Dart Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String? reccurance;
  bool? isAllDay = false;

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

  Color getColor(Set<WidgetState> states) {
    const Set<WidgetState> interactiveStates = <WidgetState>{
      WidgetState.pressed,
      WidgetState.hovered,
      WidgetState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.grey;
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
      startDate: dateTimeRange != null && dateTimeRange!.isNotEmpty
          ? dateTimeRange![0]
          : (dateTime ?? DateTime.now()),
      endDate: dateTimeRange != null && dateTimeRange!.length > 1
          ? dateTimeRange![1]
          : (dateTime ?? DateTime.now()).add(const Duration(minutes: 30)),
      allDay: isAllDay ?? false,
      recurrence: recurrence,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ProcrastiPlanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Event Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Event Location',
                border: OutlineInputBorder(),
              ),
            ),
            ListTile(
                title: const Text('All Day'),
                trailing: Checkbox(
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith(getColor),
                  value: isAllDay,
                  onChanged: (bool? value) {
                    setState(() {
                      isAllDay = value!;
                    });
                  },
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await showOmniDateTimeRangePicker(
                    context: context, is24HourMode: true);
                setState(() {
                  dateTimeRange = result;
                });
                debugPrint('dateTime: $dateTime');
              },
              child: const Text('Event Times'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Add event to calendar'),
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
