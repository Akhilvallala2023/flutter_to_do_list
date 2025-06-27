import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/journal_model.dart';
import '../models/user_xp_model.dart';

class SupabaseService {
  final SupabaseClient _client;
  
  // Tables
  static const String _tasksTable = 'tasks';
  static const String _journalsTable = 'journals';
  static const String _userXpTable = 'user_xp';
  
  SupabaseService({required SupabaseClient client}) : _client = client;
  
  // Initialize Supabase
  static Future<SupabaseService> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    return SupabaseService(client: Supabase.instance.client);
  }
  
  // Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;
  
  // Check if user is signed in
  bool get isSignedIn => _client.auth.currentUser != null;
  
  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // TASK OPERATIONS
  
  // Get all tasks for current user
  Future<List<Task>> getTasks() async {
    if (!isSignedIn || currentUserId == null) return [];
    
    try {
      final response = await _client
          .from(_tasksTable)
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((taskJson) => Task.fromMap(taskJson))
          .toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return [];
    }
  }
  
  // Add a task
  Future<bool> addTask(Task task) async {
    if (!isSignedIn || currentUserId == null) return false;
    
    try {
      await _client.from(_tasksTable).insert({
        'id': task.id,
        'user_id': currentUserId!,
        'title': task.title,
        'description': task.description,
        'start_time': task.startTime?.millisecondsSinceEpoch,
        'end_time': task.endTime?.millisecondsSinceEpoch,
        'duration': task.duration?.inSeconds,
        'priority': task.priority.index,
        'status': task.status.index,
        'is_ai_generated': task.isAiGenerated,
        'category': task.category,
        'created_at': task.createdAt.millisecondsSinceEpoch,
        'completed_at': task.completedAt?.millisecondsSinceEpoch,
        'tags': task.tags,
        'color': task.color?.value,
        'google_calendar_event_id': task.googleCalendarEventId,
        'metadata': task.metadata,
        'xp_earned': task.xpEarned,
        'xp_claimed': task.xpClaimed,
        'timer_sessions': task.timerSessions?.map((session) => session.toMap()).toList(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding task: $e');
      return false;
    }
  }
  
  // Update a task
  Future<bool> updateTask(Task task) async {
    if (!isSignedIn || currentUserId == null) return false;
    
    try {
      await _client
          .from(_tasksTable)
          .update({
            'title': task.title,
            'description': task.description,
            'start_time': task.startTime?.millisecondsSinceEpoch,
            'end_time': task.endTime?.millisecondsSinceEpoch,
            'duration': task.duration?.inSeconds,
            'priority': task.priority.index,
            'status': task.status.index,
            'is_ai_generated': task.isAiGenerated,
            'category': task.category,
            'completed_at': task.completedAt?.millisecondsSinceEpoch,
            'tags': task.tags,
            'color': task.color?.value,
            'google_calendar_event_id': task.googleCalendarEventId,
            'metadata': task.metadata,
            'xp_earned': task.xpEarned,
            'xp_claimed': task.xpClaimed,
            'timer_sessions': task.timerSessions?.map((session) => session.toMap()).toList(),
          })
          .eq('id', task.id)
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      debugPrint('Error updating task: $e');
      return false;
    }
  }
  
  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    if (!isSignedIn || currentUserId == null) return false;
    
    try {
      await _client
          .from(_tasksTable)
          .delete()
          .eq('id', taskId)
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      debugPrint('Error deleting task: $e');
      return false;
    }
  }
  
  // JOURNAL OPERATIONS
  
  // Get all journal entries for current user
  Future<List<Journal>> getJournals() async {
    if (!isSignedIn || currentUserId == null) return [];
    
    try {
      final response = await _client
          .from(_journalsTable)
          .select()
          .eq('user_id', currentUserId!)
          .order('date', ascending: false);
      
      return (response as List)
          .map((journalJson) => Journal.fromMap(journalJson))
          .toList();
    } catch (e) {
      debugPrint('Error fetching journals: $e');
      return [];
    }
  }
  
  // Add a journal entry
  Future<bool> addJournal(Journal journal) async {
    if (!isSignedIn || currentUserId == null) return false;
    
    try {
      await _client.from(_journalsTable).insert({
        'id': journal.id,
        'user_id': currentUserId!,
        'content': journal.content,
        'date': journal.date.millisecondsSinceEpoch,
        'sentiment': journal.sentiment.index,
        'metadata': journal.metadata,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding journal: $e');
      return false;
    }
  }
  
  // Update a journal entry
  Future<bool> updateJournal(Journal journal) async {
    if (!isSignedIn || currentUserId == null) return false;
    
    try {
      await _client
          .from(_journalsTable)
          .update({
            'content': journal.content,
            'date': journal.date.millisecondsSinceEpoch,
            'sentiment': journal.sentiment.index,
            'metadata': journal.metadata,
          })
          .eq('id', journal.id)
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      debugPrint('Error updating journal: $e');
      return false;
    }
  }
  
  // Delete a journal entry
  Future<bool> deleteJournal(String journalId) async {
    if (!isSignedIn || currentUserId == null) return false;
    
    try {
      await _client
          .from(_journalsTable)
          .delete()
          .eq('id', journalId)
          .eq('user_id', currentUserId!);
      return true;
    } catch (e) {
      debugPrint('Error deleting journal: $e');
      return false;
    }
  }
  
  // USER XP OPERATIONS
  
  // Get user XP data
  Future<UserXP?> getUserXP() async {
    if (!isSignedIn || currentUserId == null) return null;
    
    try {
      final response = await _client
          .from(_userXpTable)
          .select()
          .eq('user_id', currentUserId!)
          .single();
      
      return UserXP.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching user XP: $e');
      return null;
    }
  }
  
  // Save user XP data
  Future<bool> saveUserXP(UserXP userXP) async {
    if (!isSignedIn || currentUserId == null) return false;
    
    try {
      // Check if user XP record exists
      final exists = await _client
          .from(_userXpTable)
          .select('user_id')
          .eq('user_id', currentUserId!)
          .maybeSingle();
      
      if (exists != null) {
        // Update existing record
        await _client
            .from(_userXpTable)
            .update({
              'total_xp': userXP.totalXP,
              'current_day_xp': userXP.currentDayXP,
              'current_streak': userXP.currentStreak,
              'longest_streak': userXP.longestStreak,
              'last_activity': userXP.lastActivity.millisecondsSinceEpoch,
              'daily_xp': userXP.dailyXP,
              'daily_xp_cap': userXP.dailyXPCap,
            })
            .eq('user_id', currentUserId!);
      } else {
        // Create new record
        await _client.from(_userXpTable).insert({
          'user_id': currentUserId!,
          'total_xp': userXP.totalXP,
          'current_day_xp': userXP.currentDayXP,
          'current_streak': userXP.currentStreak,
          'longest_streak': userXP.longestStreak,
          'last_activity': userXP.lastActivity.millisecondsSinceEpoch,
          'daily_xp': userXP.dailyXP,
          'daily_xp_cap': userXP.dailyXPCap,
        });
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving user XP: $e');
      return false;
    }
  }
} 