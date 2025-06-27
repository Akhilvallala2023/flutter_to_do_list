import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences.dart';
import '../services/storage_service.dart';
import 'task_provider.dart';

// Provider for user preferences
final preferencesProvider = StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PreferencesNotifier(storageService);
});

// Provider for theme mode
final isDarkModeProvider = Provider<bool>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return preferences.darkMode;
});

// Provider for AI suggestions enabled
final aiSuggestionsEnabledProvider = Provider<bool>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return preferences.useAiSuggestions;
});

// Provider for Google Calendar sync enabled
final calendarSyncEnabledProvider = Provider<bool>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return preferences.syncWithGoogleCalendar;
});

// Provider for working hours
final workingHoursProvider = Provider<(int, int)>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return (preferences.workingHoursStart, preferences.workingHoursEnd);
});

// Provider for favorite categories
final favoriteCategoriesProvider = Provider<List<String>>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return preferences.favoriteCategories;
});

// Provider for work days
final workDaysProvider = Provider<List<String>>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return preferences.workDays;
});

// Preferences state notifier
class PreferencesNotifier extends StateNotifier<UserPreferences> {
  final StorageService _storageService;
  
  PreferencesNotifier(this._storageService) : super(const UserPreferences()) {
    _loadPreferences();
  }
  
  // Load preferences from storage
  Future<void> _loadPreferences() async {
    final preferences = await _storageService.getPreferences();
    state = preferences;
  }
  
  // Save preferences to storage
  Future<void> _savePreferences() async {
    await _storageService.savePreferences(state);
  }
  
  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    state = state.copyWith(darkMode: !state.darkMode);
    await _savePreferences();
  }
  
  // Toggle AI suggestions
  Future<void> toggleAiSuggestions() async {
    state = state.copyWith(useAiSuggestions: !state.useAiSuggestions);
    await _savePreferences();
  }
  
  // Toggle Google Calendar sync
  Future<void> toggleCalendarSync() async {
    state = state.copyWith(syncWithGoogleCalendar: !state.syncWithGoogleCalendar);
    await _savePreferences();
  }
  
  // Update working hours
  Future<void> updateWorkingHours(int start, int end) async {
    state = state.copyWith(workingHoursStart: start, workingHoursEnd: end);
    await _savePreferences();
  }
  
  // Add a favorite category
  Future<void> addFavoriteCategory(String category) async {
    if (!state.favoriteCategories.contains(category)) {
      state = state.copyWith(
        favoriteCategories: [...state.favoriteCategories, category],
      );
      await _savePreferences();
    }
  }
  
  // Remove a favorite category
  Future<void> removeFavoriteCategory(String category) async {
    state = state.copyWith(
      favoriteCategories: state.favoriteCategories.where((c) => c != category).toList(),
    );
    await _savePreferences();
  }
  
  // Update work days
  Future<void> updateWorkDays(List<String> workDays) async {
    state = state.copyWith(workDays: workDays);
    await _savePreferences();
  }
  
  // Update AI preferences
  Future<void> updateAiPreferences(Map<String, dynamic> aiPreferences) async {
    state = state.copyWith(aiPreferences: aiPreferences);
    await _savePreferences();
  }
  
  // Update calendar preferences
  Future<void> updateCalendarPreferences(Map<String, dynamic> calendarPreferences) async {
    state = state.copyWith(calendarPreferences: calendarPreferences);
    await _savePreferences();
  }
} 