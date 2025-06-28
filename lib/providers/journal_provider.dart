import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_model.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import 'task_provider.dart';

// Provider for the AI service
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    openRouterApiKey: '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',
  );
});

// Provider for all journals
final journalsProvider = StateNotifierProvider<JournalsNotifier, List<Journal>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final aiService = ref.watch(aiServiceProvider);
  return JournalsNotifier(storageService, aiService);
});

// Provider for journal by date
final journalByDateProvider = Provider.family<Journal?, DateTime>((ref, date) {
  final journals = ref.watch(journalsProvider);
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
  
  try {
    return journals.firstWhere((journal) {
      final journalDate = journal.date;
      return journalDate.isAfter(startOfDay) && journalDate.isBefore(endOfDay);
    });
  } catch (e) {
    return null;
  }
});

// Provider for weekly summary
final weeklySummaryProvider = FutureProvider.family<String, DateTime>((ref, weekStartDate) async {
  final journals = ref.watch(journalsProvider);
  final completedTasks = ref.watch(completedTasksProvider);
  final aiService = ref.watch(aiServiceProvider);
  
  // Get journals for the specified week
  final weekEndDate = weekStartDate.add(const Duration(days: 7));
  final weekJournals = journals.where((journal) {
    return journal.date.isAfter(weekStartDate) && journal.date.isBefore(weekEndDate);
  }).toList();
  
  // Get completed tasks for the specified week
  final weekCompletedTasks = completedTasks.where((task) {
    if (task.completedAt == null) return false;
    return task.completedAt!.isAfter(weekStartDate) && task.completedAt!.isBefore(weekEndDate);
  }).toList();
  
  // Generate weekly summary
  return await aiService.generateWeeklySummary(weekJournals, weekCompletedTasks);
});

// Journals state notifier
class JournalsNotifier extends StateNotifier<List<Journal>> {
  final StorageService _storageService;
  final AiService _aiService;
  
  JournalsNotifier(this._storageService, this._aiService) : super([]) {
    _loadJournals();
  }
  
  // Load all journals from storage
  Future<void> _loadJournals() async {
    final journals = await _storageService.getAllJournals();
    state = journals;
  }
  
  // Add a new journal
  Future<void> addJournal(Journal journal) async {
    // Add to state
    state = [...state, journal];
    
    // Save to storage
    await _storageService.saveJournal(journal);
  }
  
  // Update an existing journal
  Future<void> updateJournal(Journal updatedJournal) async {
    state = state.map((journal) {
      if (journal.id == updatedJournal.id) {
        return updatedJournal;
      }
      return journal;
    }).toList();
    
    // Save to storage
    await _storageService.saveJournal(updatedJournal);
  }
  
  // Delete a journal
  Future<void> deleteJournal(String journalId) async {
    // Delete from state
    state = state.where((journal) => journal.id != journalId).toList();
    
    // Delete from storage
    await _storageService.deleteJournal(journalId);
  }
  
  // Get or create a journal for today
  Future<Journal> getOrCreateTodayJournal() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    try {
      return state.firstWhere((journal) {
        final journalDate = journal.date;
        return journalDate.isAfter(startOfDay) && journalDate.isBefore(endOfDay);
      });
    } catch (e) {
      // Create a new journal for today
      final newJournal = Journal(date: today);
      await addJournal(newJournal);
      return newJournal;
    }
  }
  
  // Add a completed task to today's journal
  Future<void> addCompletedTaskToJournal(String taskId) async {
    final journal = await getOrCreateTodayJournal();
    final updatedJournal = journal.copyWith(
      taskIdsCompleted: [...journal.taskIdsCompleted, taskId],
    );
    
    await updateJournal(updatedJournal);
  }
  
  // Analyze journal sentiment
  Future<void> analyzeSentiment(String journalId, String content) async {
    final journal = state.firstWhere((journal) => journal.id == journalId);
    
    // Update journal content
    final updatedJournal = journal.copyWith(content: content);
    await updateJournal(updatedJournal);
    
    // Analyze sentiment
    final sentimentResult = await _aiService.analyzeSentiment(content);
    
    // Update journal with sentiment analysis
    final sentimentType = SentimentType.values[sentimentResult['sentiment']];
    final sentimentScore = sentimentResult['score'] as double?;
    final analysis = sentimentResult['analysis'] as String?;
    
    final journalWithSentiment = updatedJournal.copyWith(
      sentiment: sentimentType,
      sentimentScore: sentimentScore,
      aiAnalysis: {'analysis': analysis},
    );
    
    await updateJournal(journalWithSentiment);
  }
} 