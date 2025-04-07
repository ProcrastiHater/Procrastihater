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

//Calendar Imports
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

///*********************************
/// Name: CalendarPage
///
/// Description: Root stateful widget of
/// the CalendarPage
///*********************************
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

///*********************************
/// Name: _CalendarPageState
///
/// Description: State for the CalendarPage
///*********************************
class _CalendarPageState extends State<CalendarPage> {
  final ColorScheme _colorScheme = const ColorScheme(
    primary: Color.fromARGB(255, 10, 27, 46),
    secondary: Color.fromARGB(255, 19, 52, 88),
    surface: Color.fromARGB(255, 10, 27, 46),
    error: Color(0xFFFF5252),
    onPrimary: Color.fromARGB(255, 19, 52, 88),
    onSecondary: Color.fromARGB(255, 19, 60, 88),
    onSurface: Color.fromARGB(255, 252, 231, 193),
    onError: Color.fromARGB(255, 10, 27, 46),
    brightness: Brightness.light,
  );

  List<DateTime>? dateTimeRange;
  String? title;
  String? description;
  String? location;
  String? recurrenceType;
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  ///*********************************
  /// Name: buildEvent
  ///
  /// Description: Creates the event to be added to device calendar
  ///*********************************
  Event buildEvent({Recurrence? recurrence}) {
    Recurrence? recurrence;

    if (recurrenceType != null) {
      switch (recurrenceType) {
        case 'daily':
          recurrence = Recurrence(frequency: Frequency.daily);
          break;
        case 'weekly':
          recurrence = Recurrence(frequency: Frequency.weekly);
          break;
        case 'monthly':
          recurrence = Recurrence(frequency: Frequency.monthly);
          break;
        case 'yearly':
          recurrence = Recurrence(frequency: Frequency.yearly);
          break;
      }
    }
    //If valid parameters are selected, they will be included in the event.
    //Otherwise just default to placeholder text and event starts immediately
    //and ends 30 minutes later.
    return Event(
      title: title ?? 'Test event',
      description: description ?? 'example',
      location: location ?? 'Flutter app',
      startDate: dateTimeRange != null && dateTimeRange!.isNotEmpty
          ? dateTimeRange![0]
          : (DateTime.now()),
      endDate: dateTimeRange != null && dateTimeRange!.length > 1
          ? dateTimeRange![1]
          : (DateTime.now()).add(const Duration(minutes: 30)),
      allDay: isAllDay ?? false,
      recurrence: recurrence,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ProcrastiPlanner',
          style: TextStyle(color: _colorScheme.onSurface),
        ),
        backgroundColor: _colorScheme.primary,
      ),
      backgroundColor: _colorScheme.primary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: _colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Event Title',
                labelStyle: TextStyle(color: _colorScheme.onSurface),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: _colorScheme.onSurface, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: TextStyle(color: _colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Event Description',
                labelStyle: TextStyle(color: _colorScheme.onSurface),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: _colorScheme.onSurface, width: 2.0),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              style: TextStyle(color: _colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Event Location',
                labelStyle: TextStyle(color: _colorScheme.onSurface),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: _colorScheme.onSurface, width: 2.0),
                ),
              ),
            ),
            ListTile(
              title: Text(
                'All Day',
                style: TextStyle(color: _colorScheme.onSurface),
              ),
              trailing: Checkbox(
                checkColor: _colorScheme.primary,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _colorScheme.onSurface;
                  }
                  return _colorScheme.onSecondary;
                }),
                value: isAllDay,
                onChanged: (bool? value) {
                  setState(() {
                    isAllDay = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: _colorScheme.primary,
              style: TextStyle(color: _colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Recurrence',
                labelStyle: TextStyle(color: _colorScheme.onSurface),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: _colorScheme.onSurface, width: 2.0),
                ),
              ),
              value: recurrenceType,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('No Recurrence',
                      style: TextStyle(color: _colorScheme.onSurface)),
                ),
                DropdownMenuItem(
                  value: 'daily',
                  child: Text('Daily',
                      style: TextStyle(color: _colorScheme.onSurface)),
                ),
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text('Weekly',
                      style: TextStyle(color: _colorScheme.onSurface)),
                ),
                DropdownMenuItem(
                  value: 'monthly',
                  child: Text('Monthly',
                      style: TextStyle(color: _colorScheme.onSurface)),
                ),
                DropdownMenuItem(
                  value: 'yearly',
                  child: Text('Yearly',
                      style: TextStyle(color: _colorScheme.onSurface)),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  recurrenceType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await showOmniDateTimeRangePicker(
                  context: context,
                  is24HourMode: true,
                );
                setState(() {
                  dateTimeRange = result;
                });
                debugPrint('dateTime: $dateTimeRange');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorScheme.onSecondary,
                foregroundColor: _colorScheme.onSurface,
              ),
              child: Text('Event Times',
                  style: TextStyle(color: _colorScheme.onSurface)),
            ),
            const SizedBox(height: 24),
            Card(
              color: _colorScheme.onSecondary,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
                title: Text(
                  'Add event to calendar',
                  style: TextStyle(color: _colorScheme.onSurface),
                ),
                trailing:
                    Icon(Icons.calendar_today, color: _colorScheme.onSurface),
                tileColor: _colorScheme.onSecondary,
                onTap: () {
                  Add2Calendar.addEvent2Cal(
                    buildEvent(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
