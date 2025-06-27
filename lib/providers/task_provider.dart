import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';

// Provider for the storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Provider for all tasks
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TasksNotifier(storageService);
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

// Tasks state notifier
class TasksNotifier extends StateNotifier<List<Task>> {
  final StorageService _storageService;
  
  TasksNotifier(this._storageService) : super([]) {
    _loadTasks();
  }
  
  // Load all tasks from storage
  Future<void> _loadTasks() async {
    final tasks = await _storageService.getAllTasks();
    state = tasks;
  }
  
  // Add a new task
  Future<void> addTask(Task task) async {
    // Add to state
    state = [...state, task];
    
    // Save to storage
    await _storageService.saveTask(task);
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
  }
  
  // Delete a task
  Future<void> deleteTask(String taskId) async {
    // Delete from state
    state = state.where((task) => task.id != taskId).toList();
    
    // Delete from storage
    await _storageService.deleteTask(taskId);
  }
  
  // Mark a task as completed
  Future<void> completeTask(String taskId) async {
    final task = state.firstWhere((task) => task.id == taskId);
    
    // Stop timer if it's running
    if (task.timerStartedAt != null) {
      await stopTaskTimer(taskId);
    }
    
    // Calculate XP if not already done
    if (task.xpEarned == 0) {
      task.calculateXP();
    }
    
    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      xpEarned: task.xpEarned,
    );
    
    await updateTask(updatedTask);
  }
  
  // Mark a task as in progress
  Future<void> startTask(String taskId) async {
    final task = state.firstWhere((task) => task.id == taskId);
    final updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
    );
    
    await updateTask(updatedTask);
  }
  
  // Start the timer for a task
  Future<void> startTaskTimer(String taskId) async {
    final task = state.firstWhere((task) => task.id == taskId);
    
    // Start the timer
    task.startTimer();
    
    // Also mark as in progress
    final updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
      timerStartedAt: task.timerStartedAt,
    );
    
    await updateTask(updatedTask);
  }
  
  // Stop the timer for a task
  Future<void> stopTaskTimer(String taskId) async {
    final task = state.firstWhere((task) => task.id == taskId);
    
    // Stop the timer
    task.stopTimer();
    
    final updatedTask = task.copyWith(
      timerStartedAt: null,
      timerSessions: task.timerSessions,
    );
    
    await updateTask(updatedTask);
  }
  
  // Mark XP as claimed for a task
  Future<void> markXPClaimed(String taskId) async {
    final task = state.firstWhere((task) => task.id == taskId);
    
    final updatedTask = task.copyWith(
      xpClaimed: true,
    );
    
    await updateTask(updatedTask);
  }
} 