import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class GoogleCalendarService {
  static const _scopes = [calendar.CalendarApi.calendarScope];
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );
  
  calendar.CalendarApi? _calendarApi;
  bool _isInitialized = false;
  
  // Initialize the service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Try to sign in silently first
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _setupCalendarApi(account);
        _isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing Google Calendar service: $e');
      return false;
    }
  }
  
  // Sign in to Google
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _setupCalendarApi(account);
        _isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error signing in to Google: $e');
      return false;
    }
  }
  
  // Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _calendarApi = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }
  
  // Check if signed in
  bool get isSignedIn => _isInitialized;
  
  // Set up the Calendar API client
  Future<void> _setupCalendarApi(GoogleSignInAccount account) async {
    final authHeaders = await account.authHeaders;
    final client = GoogleHttpClient(authHeaders);
    _calendarApi = calendar.CalendarApi(client);
  }
  
  // Get calendar events for a specific time range
  Future<List<Map<String, dynamic>>> getEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_isInitialized || _calendarApi == null) {
      if (!await initialize()) {
        return [];
      }
    }
    
    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      
      return events.items?.map((event) {
        final startTime = event.start?.dateTime ?? DateTime.now();
        final endTime = event.end?.dateTime ?? startTime.add(const Duration(hours: 1));
        
        return {
          'id': event.id ?? '',
          'title': event.summary ?? 'No Title',
          'description': event.description ?? '',
          'startTime': startTime,
          'endTime': endTime,
          'isAllDay': event.start?.date != null,
          'location': event.location ?? '',
          'colorId': event.colorId,
        };
      }).toList() ?? [];
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      return [];
    }
  }
  
  // Create a calendar event from a task
  Future<String?> createEventFromTask(Task task) async {
    if (!_isInitialized || _calendarApi == null) {
      if (!await initialize()) {
        return null;
      }
    }
    
    if (task.startTime == null || task.endTime == null) {
      debugPrint('Task must have start and end times to create calendar event');
      return null;
    }
    
    try {
      final event = calendar.Event()
        ..summary = task.title
        ..description = task.description;
        
      event.start = calendar.EventDateTime()
        ..dateTime = task.startTime!.toUtc()
        ..timeZone = DateTime.now().timeZoneName;
        
      event.end = calendar.EventDateTime()
        ..dateTime = task.endTime!.toUtc()
        ..timeZone = DateTime.now().timeZoneName;
      
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      return createdEvent.id;
    } catch (e) {
      debugPrint('Error creating calendar event: $e');
      return null;
    }
  }
  
  // Update a calendar event from a task
  Future<bool> updateEventFromTask(Task task) async {
    if (!_isInitialized || _calendarApi == null || task.googleCalendarEventId == null) {
      return false;
    }
    
    if (task.startTime == null || task.endTime == null) {
      debugPrint('Task must have start and end times to update calendar event');
      return false;
    }
    
    try {
      // Get the existing event
      final existingEvent = await _calendarApi!.events.get('primary', task.googleCalendarEventId!);
      
      // Update the event
      existingEvent.summary = task.title;
      existingEvent.description = task.description;
      
      existingEvent.start = calendar.EventDateTime()
        ..dateTime = task.startTime!.toUtc()
        ..timeZone = DateTime.now().timeZoneName;
        
      existingEvent.end = calendar.EventDateTime()
        ..dateTime = task.endTime!.toUtc()
        ..timeZone = DateTime.now().timeZoneName;
      
      await _calendarApi!.events.update(existingEvent, 'primary', task.googleCalendarEventId!);
      return true;
    } catch (e) {
      debugPrint('Error updating calendar event: $e');
      return false;
    }
  }
  
  // Delete a calendar event
  Future<bool> deleteEvent(String eventId) async {
    if (!_isInitialized || _calendarApi == null) {
      return false;
    }
    
    try {
      await _calendarApi!.events.delete('primary', eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
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