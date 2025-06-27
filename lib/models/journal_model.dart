import 'package:uuid/uuid.dart';

enum SentimentType { veryNegative, negative, neutral, positive, veryPositive }

class Journal {
  final String id;
  final DateTime date;
  String title;
  String content;
  SentimentType sentiment;
  double? sentimentScore; // Numerical score from -1.0 to 1.0
  List<String> taskIdsCompleted;
  List<String> taskIdsCreated;
  Map<String, dynamic>? aiAnalysis;
  Map<String, dynamic>? metadata;
  
  Journal({
    String? id,
    required this.date,
    this.title = '',
    this.content = '',
    this.sentiment = SentimentType.neutral,
    this.sentimentScore,
    List<String>? taskIdsCompleted,
    List<String>? taskIdsCreated,
    this.aiAnalysis,
    this.metadata,
  }) : 
    id = id ?? const Uuid().v4(),
    taskIdsCompleted = taskIdsCompleted ?? [],
    taskIdsCreated = taskIdsCreated ?? [];
  
  // Add a completed task to the journal
  void addCompletedTask(String taskId) {
    if (!taskIdsCompleted.contains(taskId)) {
      taskIdsCompleted.add(taskId);
    }
  }
  
  // Add a created task to the journal
  void addCreatedTask(String taskId) {
    if (!taskIdsCreated.contains(taskId)) {
      taskIdsCreated.add(taskId);
    }
  }
  
  // Update sentiment based on AI analysis
  void updateSentiment(SentimentType newSentiment, double? score) {
    sentiment = newSentiment;
    sentimentScore = score;
  }
  
  // Convert journal to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'title': title,
      'content': content,
      'sentiment': sentiment.index,
      'sentimentScore': sentimentScore,
      'taskIdsCompleted': taskIdsCompleted,
      'taskIdsCreated': taskIdsCreated,
      'aiAnalysis': aiAnalysis,
      'metadata': metadata,
    };
  }
  
  // Create journal from Map
  factory Journal.fromMap(Map<String, dynamic> map) {
    return Journal(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      sentiment: SentimentType.values[map['sentiment'] ?? 2],
      sentimentScore: map['sentimentScore'],
      taskIdsCompleted: List<String>.from(map['taskIdsCompleted'] ?? []),
      taskIdsCreated: List<String>.from(map['taskIdsCreated'] ?? []),
      aiAnalysis: map['aiAnalysis'],
      metadata: map['metadata'],
    );
  }
  
  // Create a copy of this journal with modified fields
  Journal copyWith({
    String? title,
    String? content,
    SentimentType? sentiment,
    double? sentimentScore,
    List<String>? taskIdsCompleted,
    List<String>? taskIdsCreated,
    Map<String, dynamic>? aiAnalysis,
    Map<String, dynamic>? metadata,
  }) {
    return Journal(
      id: this.id,
      date: this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      sentiment: sentiment ?? this.sentiment,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      taskIdsCompleted: taskIdsCompleted ?? List.from(this.taskIdsCompleted),
      taskIdsCreated: taskIdsCreated ?? List.from(this.taskIdsCreated),
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      metadata: metadata ?? this.metadata,
    );
  }
} 