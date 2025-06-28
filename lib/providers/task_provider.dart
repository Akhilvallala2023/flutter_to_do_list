import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/google_calendar_service.dart';
import '../services/ai_service.dart';
import 'user_xp_provider.dart';

// Provider for the storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Provider for all tasks
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final googleCalendarService = ref.watch(googleCalendarServiceProvider);
  final aiService = ref.watch(aiServiceProvider);
  final userXpNotifier = ref.watch(userXpProvider.notifier);
  return TasksNotifier(
    storageService, 
    googleCalendarService, 
    aiService,
    userXpNotifier
  );
});

// Provider for a single task by ID
final taskProvider = Provider.family<Task?, String>((ref, taskId) {
  final tasks = ref.watch(tasksProvider);
  try {
    return tasks.firstWhere((task) => task.id == taskId);
  } catch (e) {
    return null;
  }
});

// Provider for filtered tasks (pending)
final pendingTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((task) => task.status == TaskStatus.pending).toList();
});

// Provider for filtered tasks (completed)
final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((task) => task.status == TaskStatus.completed).toList();
});

// Provider for filtered tasks (in progress)
final inProgressTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((task) => task.status == TaskStatus.inProgress).toList();
});

// Provider for tasks by category
final tasksByCategoryProvider = Provider.family<List<Task>, String>((ref, category) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((task) => task.category == category).toList();
});

// Provider for tasks by date
final tasksByDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((task) {
    if (task.startTime == null) return false;
    
    return task.startTime!.year == date.year &&
           task.startTime!.month == date.month &&
           task.startTime!.day == date.day;
  }).toList();
});

// Provider for time suggestions for a new task
final taskTimeSuggestionsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, taskTitle) async {
  final aiService = ref.watch(aiServiceProvider);
  final tasks = ref.watch(tasksProvider);
  
  if (tasks.isEmpty || taskTitle.isEmpty) return null;
  
  try {
    return await aiService.suggestTaskTiming(taskTitle, tasks);
  } catch (e) {
    debugPrint('Error getting task timing suggestion: $e');
    return {
      'suggestedStartTime': null,
      'suggestedDuration': 60,
      'explanation': 'Unable to generate a timing suggestion due to an error.',
      'confidence': 0.0,
    };
  }
});

// Tasks state notifier
class TasksNotifier extends StateNotifier<List<Task>> {
  final StorageService _storageService;
  final GoogleCalendarService _googleCalendarService;
  final AiService _aiService;
  final UserXpNotifier _userXpNotifier;
  
  TasksNotifier(
    this._storageService, 
    this._googleCalendarService, 
    this._aiService,
    this._userXpNotifier
  ) : super([]) {
    _loadTasks();
  }
  
  // Load tasks from storage
  Future<void> _loadTasks() async {
    final tasks = await _storageService.getAllTasks();
    state = tasks;
    
    // Initialize Google Calendar service
    await _googleCalendarService.init();
    
    // Sync with Google Calendar if available
    if (await _googleCalendarService.isAvailable()) {
      await syncWithGoogleCalendar();
    }
  }
  
  // Add a new task
  Future<void> addTask(Task task) async {
    // Add to state
    state = [...state, task];
    
    // Save to storage
    await _storageService.saveTask(task);
    
    // Add to Google Calendar if available
    if (await _googleCalendarService.isAvailable()) {
      final eventId = await _googleCalendarService.createTaskEvent(task);
      if (eventId != null) {
        // Update task with Google Calendar event ID
        final updatedTask = task.copyWith(googleCalendarEventId: eventId);
        updateTask(updatedTask);
      }
    }
  }
  
  // Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    state = state.map((task) {
      if (task.id == updatedTask.id) {
        return updatedTask;
      }
      return task;
    }).toList();
    
    // Save to storage
    await _storageService.saveTask(updatedTask);
    
    // Update in Google Calendar if available
    if (updatedTask.googleCalendarEventId != null && 
        await _googleCalendarService.isAvailable()) {
      await _googleCalendarService.updateTaskEvent(updatedTask);
    }
  }
  
  // Delete a task
  Future<void> deleteTask(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    
    // Delete from state
    state = state.where((t) => t.id != taskId).toList();
    
    // Delete from storage
    await _storageService.deleteTask(taskId);
    
    // Delete from Google Calendar if available
    if (task.googleCalendarEventId != null && 
        await _googleCalendarService.isAvailable()) {
      await _googleCalendarService.deleteTaskEvent(task.googleCalendarEventId!);
    }
  }
  
  // Mark a task as completed
  Future<void> completeTask(String taskId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    
    final task = state[taskIndex];
    
    // Don't complete already completed tasks
    if (task.status == TaskStatus.completed) return;
    
    // Mark as completed and calculate XP
    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    
    // Calculate XP if not already calculated
    if (updatedTask.xpEarned == 0) {
      updatedTask.calculateXP();
    }
    
    // Update state
    state = [
      ...state.sublist(0, taskIndex),
      updatedTask,
      ...state.sublist(taskIndex + 1),
    ];
    
    // Save to storage
    await _storageService.saveTask(updatedTask);
    
    // Update in Google Calendar if available
    if (updatedTask.googleCalendarEventId != null && 
        await _googleCalendarService.isAvailable()) {
      await _googleCalendarService.updateTaskEvent(updatedTask);
    }
    
    // Award XP if not already claimed
    if (!updatedTask.xpClaimed) {
      await _userXpNotifier.addXp(updatedTask.xpEarned);
      
      // Mark XP as claimed
      final claimedTask = updatedTask.copyWith(xpClaimed: true);
      await updateTask(claimedTask);
    }
  }
  
  // Start task timer
  Future<void> startTaskTimer(String taskId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    
    final task = state[taskIndex];
    
    // Start the timer
    task.startTimer();
    
    // Update status if not already in progress
    final updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
      timerStartedAt: task.timerStartedAt,
    );
    
    // Update state
    state = [
      ...state.sublist(0, taskIndex),
      updatedTask,
      ...state.sublist(taskIndex + 1),
    ];
    
    // Save to storage
    await _storageService.saveTask(updatedTask);
    
    // Update in Google Calendar if available
    if (updatedTask.googleCalendarEventId != null && 
        await _googleCalendarService.isAvailable()) {
      await _googleCalendarService.updateTaskEvent(updatedTask);
    }
  }
  
  // Stop task timer
  Future<void> stopTaskTimer(String taskId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;
    
    final task = state[taskIndex];
    
    // Stop the timer
    task.stopTimer();
    
    // Update the task with the new timer session
    final updatedTask = task.copyWith(
      timerStartedAt: null,
      timerSessions: task.timerSessions,
    );
    
    // Update state
    state = [
      ...state.sublist(0, taskIndex),
      updatedTask,
      ...state.sublist(taskIndex + 1),
    ];
    
    // Save to storage
    await _storageService.saveTask(updatedTask);
    
    // Update in Google Calendar if available
    if (updatedTask.googleCalendarEventId != null && 
        await _googleCalendarService.isAvailable()) {
      await _googleCalendarService.updateTaskEvent(updatedTask);
    }
  }
  
  // Sync tasks with Google Calendar
  Future<void> syncWithGoogleCalendar() async {
    if (!await _googleCalendarService.isAvailable()) return;
    
    try {
      // Get start and end dates for sync (last 30 days to next 30 days)
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final end = now.add(const Duration(days: 30));
      
      // Get tasks from Google Calendar
      final calendarTasks = await _googleCalendarService.getTasksFromCalendar(start, end);
      
      // Process each calendar task
      for (final calendarTask in calendarTasks) {
        final existingTaskIndex = state.indexWhere((t) => 
            t.googleCalendarEventId == calendarTask.googleCalendarEventId);
        
        if (existingTaskIndex == -1) {
          // New task from calendar - add to local tasks
          await _storageService.saveTask(calendarTask);
          state = [...state, calendarTask];
        } else {
          // Existing task - check if calendar version is newer
          final existingTask = state[existingTaskIndex];
          
          // For simplicity, we'll just update local tasks with calendar data
          // In a real app, you might want to implement more sophisticated conflict resolution
          final updatedTask = existingTask.copyWith(
            title: calendarTask.title,
            description: calendarTask.description,
            startTime: calendarTask.startTime,
            endTime: calendarTask.endTime,
            status: calendarTask.status,
            category: calendarTask.category,
          );
          
          await _storageService.saveTask(updatedTask);
          state = [
            ...state.sublist(0, existingTaskIndex),
            updatedTask,
            ...state.sublist(existingTaskIndex + 1),
          ];
        }
      }
      
      // Upload local tasks that don't have a Google Calendar ID
      for (final task in state) {
        if (task.googleCalendarEventId == null) {
          final eventId = await _googleCalendarService.createTaskEvent(task);
          if (eventId != null) {
            final updatedTask = task.copyWith(googleCalendarEventId: eventId);
            await _storageService.saveTask(updatedTask);
            
            final taskIndex = state.indexWhere((t) => t.id == task.id);
            state = [
              ...state.sublist(0, taskIndex),
              updatedTask,
              ...state.sublist(taskIndex + 1),
            ];
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing with Google Calendar: $e');
    }
  }
  
  // Get AI-suggested time for a task
  Future<Map<String, dynamic>?> getTaskTimeSuggestion(String taskTitle) async {
    if (state.isEmpty || taskTitle.isEmpty) return null;
    
    try {
      return await _aiService.suggestTaskTiming(taskTitle, state);
    } catch (e) {
      debugPrint('Error getting task time suggestion: $e');
      return null;
    }
  }
} 