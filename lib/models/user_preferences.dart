class UserPreferences {
  final bool darkMode;
  final bool useAiSuggestions;
  final bool syncWithGoogleCalendar;
  final int workingHoursStart; // 24-hour format, e.g., 9 for 9 AM
  final int workingHoursEnd; // 24-hour format, e.g., 17 for 5 PM
  final List<String> favoriteCategories;
  final List<String> workDays; // e.g., ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
  final Map<String, dynamic>? aiPreferences;
  final Map<String, dynamic>? calendarPreferences;
  
  const UserPreferences({
    this.darkMode = false,
    this.useAiSuggestions = true,
    this.syncWithGoogleCalendar = false,
    this.workingHoursStart = 9,
    this.workingHoursEnd = 17,
    this.favoriteCategories = const ['Work', 'Personal', 'Health'],
    this.workDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    this.aiPreferences,
    this.calendarPreferences,
  });
  
  // Convert preferences to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'useAiSuggestions': useAiSuggestions,
      'syncWithGoogleCalendar': syncWithGoogleCalendar,
      'workingHoursStart': workingHoursStart,
      'workingHoursEnd': workingHoursEnd,
      'favoriteCategories': favoriteCategories,
      'workDays': workDays,
      'aiPreferences': aiPreferences,
      'calendarPreferences': calendarPreferences,
    };
  }
  
  // Create preferences from Map
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      darkMode: map['darkMode'] ?? false,
      useAiSuggestions: map['useAiSuggestions'] ?? true,
      syncWithGoogleCalendar: map['syncWithGoogleCalendar'] ?? false,
      workingHoursStart: map['workingHoursStart'] ?? 9,
      workingHoursEnd: map['workingHoursEnd'] ?? 17,
      favoriteCategories: List<String>.from(map['favoriteCategories'] ?? ['Work', 'Personal', 'Health']),
      workDays: List<String>.from(map['workDays'] ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']),
      aiPreferences: map['aiPreferences'],
      calendarPreferences: map['calendarPreferences'],
    );
  }
  
  // Create a copy of this preferences with modified fields
  UserPreferences copyWith({
    bool? darkMode,
    bool? useAiSuggestions,
    bool? syncWithGoogleCalendar,
    int? workingHoursStart,
    int? workingHoursEnd,
    List<String>? favoriteCategories,
    List<String>? workDays,
    Map<String, dynamic>? aiPreferences,
    Map<String, dynamic>? calendarPreferences,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      useAiSuggestions: useAiSuggestions ?? this.useAiSuggestions,
      syncWithGoogleCalendar: syncWithGoogleCalendar ?? this.syncWithGoogleCalendar,
      workingHoursStart: workingHoursStart ?? this.workingHoursStart,
      workingHoursEnd: workingHoursEnd ?? this.workingHoursEnd,
      favoriteCategories: favoriteCategories ?? List.from(this.favoriteCategories),
      workDays: workDays ?? List.from(this.workDays),
      aiPreferences: aiPreferences ?? this.aiPreferences,
      calendarPreferences: calendarPreferences ?? this.calendarPreferences,
    );
  }
} 