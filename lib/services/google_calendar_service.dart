import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import 'google_auth_service.dart';

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  return GoogleCalendarService(authService);
});

class GoogleCalendarService {
  final GoogleAuthService _authService;
  calendar.CalendarApi? _calendarApi;

  GoogleCalendarService(this._authService);

  // Initialize the calendar API
  Future<void> init() async {
    if (_authService.isSignedIn) {
      _calendarApi = await _authService.getCalendarApi();
    }
  }

  // Get calendar API (initialize if needed)
  Future<calendar.CalendarApi?> _getApi() async {
    if (_calendarApi == null) {
      _calendarApi = await _authService.getCalendarApi();
    }
    return _calendarApi;
  }

  // Check if user is signed in and calendar API is available
  Future<bool> isAvailable() async {
    final api = await _getApi();
    return api != null;
  }

  // Get user's primary calendar ID
  Future<String?> getPrimaryCalendarId() async {
    final api = await _getApi();
    if (api == null) return null;

    try {
      final calendarList = await api.calendarList.list();
      final primaryCalendar = calendarList.items?.firstWhere(
        (calendar) => calendar.primary == true,
        orElse: () => throw Exception('No primary calendar found'),
      );
      
      return primaryCalendar?.id;
    } catch (e) {
      debugPrint('Error getting primary calendar: $e');
      return null;
    }
  }

  // Create a task in Google Calendar
  Future<String?> createTaskEvent(Task task) async {
    final api = await _getApi();
    final calendarId = await getPrimaryCalendarId();
    
    if (api == null || calendarId == null) return null;

    try {
      // Calculate event time
      final now = DateTime.now();
      final startTime = task.startTime ?? now;
      final endTime = task.endTime ?? startTime.add(const Duration(hours: 1));
      
      // Create event
      final event = calendar.Event()
        ..summary = task.title
        ..description = task.description;
      
      // Set start time
      event.start = calendar.EventDateTime()
        ..dateTime = startTime.toUtc()
        ..timeZone = 'UTC';
      
      // Set end time
      event.end = calendar.EventDateTime()
        ..dateTime = endTime.toUtc()
        ..timeZone = 'UTC';
      
      // Set color and reminders
      event.colorId = _getPriorityColorId(task.priority);
      event.reminders = calendar.EventReminders()
        ..useDefault = true;
      
      // Add task metadata
      event.extendedProperties = calendar.EventExtendedProperties()
        ..private = {
          'taskId': task.id,
          'category': task.category,
          'priority': task.priority.toString(),
          'appSource': 'SmartTodo',
        };

      // Insert event
      final createdEvent = await api.events.insert(event, calendarId);
      return createdEvent.id;
    } catch (e) {
      debugPrint('Error creating calendar event: $e');
      return null;
    }
  }

  // Update a task in Google Calendar
  Future<bool> updateTaskEvent(Task task) async {
    if (task.googleCalendarEventId == null) return false;
    
    final api = await _getApi();
    final calendarId = await getPrimaryCalendarId();
    
    if (api == null || calendarId == null) return false;

    try {
      // Get existing event
      final existingEvent = await api.events.get(
        calendarId, 
        task.googleCalendarEventId!
      );
      
      // Calculate event time
      final startTime = task.startTime ?? DateTime.now();
      final endTime = task.endTime ?? startTime.add(const Duration(hours: 1));
      
      // Update event properties
      existingEvent.summary = task.title;
      existingEvent.description = task.description;
      
      // Update start time
      existingEvent.start = calendar.EventDateTime()
        ..dateTime = startTime.toUtc()
        ..timeZone = 'UTC';
      
      // Update end time
      existingEvent.end = calendar.EventDateTime()
        ..dateTime = endTime.toUtc()
        ..timeZone = 'UTC';
      
      // Update color and status
      existingEvent.colorId = _getPriorityColorId(task.priority);
      existingEvent.status = task.status == TaskStatus.completed ? 'confirmed' : 'tentative';
      
      // Update task metadata
      existingEvent.extendedProperties ??= calendar.EventExtendedProperties();
      existingEvent.extendedProperties!.private ??= {};
      existingEvent.extendedProperties!.private!.addAll({
        'category': task.category,
        'priority': task.priority.toString(),
        'status': task.status.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      // Update event
      await api.events.update(existingEvent, calendarId, task.googleCalendarEventId!);
      return true;
    } catch (e) {
      debugPrint('Error updating calendar event: $e');
      return false;
    }
  }

  // Delete a task from Google Calendar
  Future<bool> deleteTaskEvent(String eventId) async {
    final api = await _getApi();
    final calendarId = await getPrimaryCalendarId();
    
    if (api == null || calendarId == null) return false;

    try {
      await api.events.delete(calendarId, eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
    }
  }

  // Get all events from Google Calendar for a specific date range
  Future<List<Task>> getTasksFromCalendar(DateTime start, DateTime end) async {
    final api = await _getApi();
    final calendarId = await getPrimaryCalendarId();
    
    if (api == null || calendarId == null) return [];

    try {
      final events = await api.events.list(
        calendarId,
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items == null) return [];

      // Convert events to tasks
      return events.items!
          .where((event) => 
              event.extendedProperties?.private?['appSource'] == 'SmartTodo' ||
              event.extendedProperties?.private?['taskId'] != null)
          .map((event) => _convertEventToTask(event))
          .toList();
    } catch (e) {
      debugPrint('Error getting calendar events: $e');
      return [];
    }
  }

  // Convert a Google Calendar event to a Task
  Task _convertEventToTask(calendar.Event event) {
    final startTime = event.start?.dateTime ?? DateTime.now();
    final endTime = event.end?.dateTime;
    final taskId = event.extendedProperties?.private?['taskId'];
    final category = event.extendedProperties?.private?['category'] ?? 'Personal';
    final priorityString = event.extendedProperties?.private?['priority'] ?? 'TaskPriority.medium';
    final statusString = event.extendedProperties?.private?['status'] ?? 'TaskStatus.pending';
    
    // Parse priority
    TaskPriority priority;
    try {
      priority = TaskPriority.values.firstWhere(
        (p) => p.toString() == priorityString,
        orElse: () => TaskPriority.medium,
      );
    } catch (_) {
      priority = TaskPriority.medium;
    }
    
    // Parse status
    TaskStatus status;
    try {
      status = TaskStatus.values.firstWhere(
        (s) => s.toString() == statusString,
        orElse: () => TaskStatus.pending,
      );
    } catch (_) {
      status = event.status == 'confirmed' ? TaskStatus.completed : TaskStatus.pending;
    }

    return Task(
      id: taskId ?? event.id ?? '',
      title: event.summary ?? 'Untitled Task',
      description: event.description ?? '',
      startTime: startTime,
      endTime: endTime,
      priority: priority,
      status: status,
      category: category,
      googleCalendarEventId: event.id,
      isAiGenerated: false,
    );
  }

  // Map task priority to Google Calendar color ID
  String _getPriorityColorId(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return '11'; // Red
      case TaskPriority.medium:
        return '5'; // Yellow
      case TaskPriority.low:
        return '7'; // Green
      default:
        return '1'; // Blue
    }
  }
}

// Helper class for Google HTTP client
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  
  GoogleHttpClient(this._headers);
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
} 