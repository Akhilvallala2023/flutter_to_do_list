import '../models/task_model.dart';
import '../models/journal_model.dart';
import '../models/user_preferences.dart';

class StorageService {
  // In-memory storage for web compatibility
  static final Map<String, Task> _tasksStorage = {};
  static final Map<String, Journal> _journalsStorage = {};
  static UserPreferences _preferences = const UserPreferences();
  
  static Future<void> initialize() async {
    // No initialization needed for in-memory storage
    print('Storage service initialized with in-memory storage');
  }
  
  // Task operations
  Future<void> saveTask(Task task) async {
    _tasksStorage[task.id] = task;
  }
  
  Future<void> saveTasks(List<Task> tasks) async {
    for (var task in tasks) {
      _tasksStorage[task.id] = task;
    }
  }
  
  Future<Task?> getTask(String id) async {
    return _tasksStorage[id];
  }
  
  Future<List<Task>> getAllTasks() async {
    return _tasksStorage.values.toList();
  }
  
  Future<void> deleteTask(String id) async {
    _tasksStorage.remove(id);
  }
  
  Future<void> clearAllTasks() async {
    _tasksStorage.clear();
  }
  
  // Journal operations
  Future<void> saveJournal(Journal journal) async {
    _journalsStorage[journal.id] = journal;
  }
  
  Future<Journal?> getJournal(String id) async {
    return _journalsStorage[id];
  }
  
  Future<Journal?> getJournalByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    for (var journal in _journalsStorage.values) {
      if (journal.date.isAfter(startOfDay) && journal.date.isBefore(endOfDay)) {
        return journal;
      }
    }
    return null;
  }
  
  Future<List<Journal>> getAllJournals() async {
    return _journalsStorage.values.toList();
  }
  
  Future<void> deleteJournal(String id) async {
    _journalsStorage.remove(id);
  }
  
  // User preferences operations
  Future<void> savePreferences(UserPreferences preferences) async {
    _preferences = preferences;
  }
  
  Future<UserPreferences> getPreferences() async {
    return _preferences;
  }
} 