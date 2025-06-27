import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { pending, inProgress, completed, cancelled }

class Task {
  final String id;
  String title;
  String description;
  DateTime? startTime;
  DateTime? endTime;
  Duration? duration;
  TaskPriority priority;
  TaskStatus status;
  bool isAiGenerated;
  String category;
  DateTime createdAt;
  DateTime? completedAt;
  List<String> tags;
  Color? color;
  String? googleCalendarEventId;
  Map<String, dynamic>? metadata;
  
  // XP System
  int xpEarned;
  bool xpClaimed;
  
  // Timer functionality
  DateTime? timerStartedAt;
  List<TimerSession>? timerSessions;
  
  // Constructor
  Task({
    String? id,
    required this.title,
    this.description = '',
    this.startTime,
    this.endTime,
    this.duration,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.isAiGenerated = false,
    this.category = 'Personal',
    DateTime? createdAt,
    this.completedAt,
    List<String>? tags,
    this.color,
    this.googleCalendarEventId,
    this.metadata,
    this.xpEarned = 0,
    this.xpClaimed = false,
    this.timerStartedAt,
    List<TimerSession>? timerSessions,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    tags = tags ?? [],
    timerSessions = timerSessions ?? [];
  
  // Calculate duration if start and end time are set
  Duration calculateDuration() {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return duration ?? const Duration();
  }
  
  // Mark task as completed
  void markCompleted() {
    status = TaskStatus.completed;
    completedAt = DateTime.now();
    
    // Calculate XP based on task properties
    calculateXP();
  }
  
  // Calculate XP based on task properties
  void calculateXP() {
    // Base XP for completing any task
    int baseXP = 10;
    
    // Bonus XP based on priority
    int priorityBonus = 0;
    switch (priority) {
      case TaskPriority.low:
        priorityBonus = 0;
        break;
      case TaskPriority.medium:
        priorityBonus = 5;
        break;
      case TaskPriority.high:
        priorityBonus = 10;
        break;
    }
    
    // Bonus XP based on duration (if tracked)
    int durationBonus = 0;
    final taskDuration = calculateTotalTimerDuration();
    if (taskDuration.inMinutes > 0) {
      // 1 XP per 10 minutes, capped at 20 XP
      durationBonus = (taskDuration.inMinutes / 10).floor();
      durationBonus = durationBonus > 20 ? 20 : durationBonus;
    }
    
    // Calculate total XP
    xpEarned = baseXP + priorityBonus + durationBonus;
  }
  
  // Start the timer for this task
  void startTimer() {
    if (status != TaskStatus.inProgress) {
      status = TaskStatus.inProgress;
    }
    timerStartedAt = DateTime.now();
  }
  
  // Stop the timer and record the session
  void stopTimer() {
    if (timerStartedAt != null) {
      final now = DateTime.now();
      final session = TimerSession(
        startTime: timerStartedAt!,
        endTime: now,
        duration: now.difference(timerStartedAt!),
      );
      timerSessions!.add(session);
      timerStartedAt = null;
    }
  }
  
  // Calculate total time spent on this task from all timer sessions
  Duration calculateTotalTimerDuration() {
    Duration total = const Duration();
    
    // Add completed sessions
    if (timerSessions != null && timerSessions!.isNotEmpty) {
      for (var session in timerSessions!) {
        total += session.duration;
      }
    }
    
    // Add current ongoing session if timer is active
    if (timerStartedAt != null) {
      total += DateTime.now().difference(timerStartedAt!);
    }
    
    return total;
  }
  
  // Check if task is overdue
  bool isOverdue() {
    if (endTime == null) return false;
    return endTime!.isBefore(DateTime.now()) && status != TaskStatus.completed;
  }
  
  // Convert task to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'priority': priority.index,
      'status': status.index,
      'isAiGenerated': isAiGenerated,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'tags': tags,
      'color': color?.value,
      'googleCalendarEventId': googleCalendarEventId,
      'metadata': metadata,
      'xpEarned': xpEarned,
      'xpClaimed': xpClaimed,
      'timerStartedAt': timerStartedAt?.millisecondsSinceEpoch,
      'timerSessions': timerSessions?.map((session) => session.toMap()).toList(),
    };
  }
  
  // Create task from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      startTime: map['startTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endTime']) : null,
      duration: map['duration'] != null ? Duration(seconds: map['duration']) : null,
      priority: TaskPriority.values[map['priority'] ?? 1],
      status: TaskStatus.values[map['status'] ?? 0],
      isAiGenerated: map['isAiGenerated'] ?? false,
      category: map['category'] ?? 'Personal',
      createdAt: map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : DateTime.now(),
      completedAt: map['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedAt']) : null,
      tags: List<String>.from(map['tags'] ?? []),
      color: map['color'] != null ? Color(map['color']) : null,
      googleCalendarEventId: map['googleCalendarEventId'],
      metadata: map['metadata'],
      xpEarned: map['xpEarned'] ?? 0,
      xpClaimed: map['xpClaimed'] ?? false,
      timerStartedAt: map['timerStartedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['timerStartedAt']) : null,
      timerSessions: map['timerSessions'] != null 
          ? (map['timerSessions'] as List).map((session) => TimerSession.fromMap(session)).toList() 
          : [],
    );
  }
  
  // Create a copy of this task with modified fields
  Task copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    TaskPriority? priority,
    TaskStatus? status,
    bool? isAiGenerated,
    String? category,
    DateTime? completedAt,
    List<String>? tags,
    Color? color,
    String? googleCalendarEventId,
    Map<String, dynamic>? metadata,
    int? xpEarned,
    bool? xpClaimed,
    DateTime? timerStartedAt,
    List<TimerSession>? timerSessions,
  }) {
    return Task(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      category: category ?? this.category,
      createdAt: this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? List.from(this.tags),
      color: color ?? this.color,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
      metadata: metadata ?? this.metadata,
      xpEarned: xpEarned ?? this.xpEarned,
      xpClaimed: xpClaimed ?? this.xpClaimed,
      timerStartedAt: timerStartedAt ?? this.timerStartedAt,
      timerSessions: timerSessions ?? this.timerSessions,
    );
  }
}

// Class to track individual timer sessions for a task
class TimerSession {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  
  TimerSession({
    required this.startTime,
    required this.endTime,
    required this.duration,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'duration': duration.inSeconds,
    };
  }
  
  factory TimerSession.fromMap(Map<String, dynamic> map) {
    return TimerSession(
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      duration: Duration(seconds: map['duration']),
    );
  }
} 