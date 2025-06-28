import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/journal_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for AI service
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    openRouterApiKey: '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',
  );
});

class AiService {
  final String openRouterApiKey;
  final String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  AiService({
    required this.openRouterApiKey,
  });
  
  // Headers for OpenRouter API
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $openRouterApiKey',
    'HTTP-Referer': 'https://smarttodo.app', // Replace with your app's domain
    'X-Title': 'Smart Todo App',
  };
  
  // Generate task suggestions based on existing tasks and calendar data
  Future<List<Task>> generateTaskSuggestions({
    required List<Task> existingTasks,
    required List<Map<String, dynamic>> calendarEvents,
    int count = 3,
  }) async {
    try {
      // Prepare data for the prompt
      final completedTasks = existingTasks.where((task) => task.status == TaskStatus.completed).toList();
      final pendingTasks = existingTasks.where((task) => task.status == TaskStatus.pending).toList();
      
      // Create the prompt
      final prompt = _createTaskSuggestionPrompt(
        completedTasks: completedTasks,
        pendingTasks: pendingTasks,
        calendarEvents: calendarEvents,
        count: count,
      );
      
      // Call the API
      final response = await _callOpenRouter(prompt);
      
      // Parse the response into Task objects
      return _parseTaskSuggestions(response);
    } catch (error) {
      print('Error generating task suggestions: $error');
      return [];
    }
  }
  
  // Generate a daily plan based on tasks and calendar events
  Future<Map<String, dynamic>> generateScheduledDailyPlan({
    required List<Task> tasks,
    required List<Map<String, dynamic>> calendarEvents,
    required DateTime date,
  }) async {
    try {
      // Create the prompt
      final prompt = _createDailyPlanPrompt(
        tasks: tasks,
        calendarEvents: calendarEvents,
        date: date,
      );
      
      // Call the API
      final response = await _callOpenRouter(prompt);
      
      // Parse the response into a structured plan
      return _parseDailyPlan(response);
    } catch (error) {
      print('Error generating daily plan: $error');
      return {};
    }
  }
  
  // Analyze journal entry for sentiment
  Future<Map<String, dynamic>> analyzeSentiment(String journalText) async {
    try {
      // Create the prompt
      final prompt = _createSentimentAnalysisPrompt(journalText);
      
      // Call the API
      final response = await _callOpenRouter(prompt);
      
      // Parse the response
      return _parseSentimentAnalysis(response);
    } catch (error) {
      print('Error analyzing sentiment: $error');
      return {
        'sentiment': SentimentType.neutral.index,
        'score': 0.0,
        'analysis': 'Error analyzing sentiment',
      };
    }
  }
  
  // Generate a weekly summary
  Future<String> generateWeeklySummary(List<Journal> journals, List<Task> completedTasks) async {
    try {
      // Format journals and tasks for the prompt
      final journalEntries = journals.map((journal) => 
        '${journal.date.toString().substring(0, 10)}: ${journal.content}'
      ).join('\n\n');
      
      final taskEntries = completedTasks.map((task) => 
        '${task.title} (${task.category}) - Completed on ${task.completedAt.toString().substring(0, 10)}'
      ).join('\n');
      
      // Create the prompt
      final prompt = '''
      Based on the following journal entries and completed tasks from the past week, provide a concise weekly summary.
      
      JOURNAL ENTRIES:
      $journalEntries
      
      COMPLETED TASKS:
      $taskEntries
      
      Please provide:
      1. A brief overview of the week
      2. Key accomplishments
      3. Areas that might need more focus next week
      4. Any patterns or insights you notice
      
      Keep the summary concise, positive, and actionable.
      ''';
      
      // Call the LLM
      final response = await _callOpenRouter(prompt);
      return response;
    } catch (e) {
      debugPrint('Error generating weekly summary: $e');
      return 'Unable to generate summary at this time. Please try again later.';
    }
  }
  
  // Create a prompt for task suggestions
  String _createTaskSuggestionPrompt({
    required List<Task> completedTasks,
    required List<Task> pendingTasks,
    required List<Map<String, dynamic>> calendarEvents,
    required int count,
  }) {
    final completedTasksStr = completedTasks.map((task) => 
      '- ${task.title} (Category: ${task.category}, Priority: ${task.priority.name})'
    ).join('\n');
    
    final pendingTasksStr = pendingTasks.map((task) => 
      '- ${task.title} (Category: ${task.category}, Priority: ${task.priority.name})'
    ).join('\n');
    
    final calendarEventsStr = calendarEvents.map((event) => 
      '- ${event['title']} (${event['startTime']} - ${event['endTime']})'
    ).join('\n');
    
    return '''
You are an intelligent task assistant. Based on the user's completed and pending tasks, as well as their calendar events, suggest $count new tasks that would be helpful for them to add to their to-do list.

Completed Tasks:
$completedTasksStr

Pending Tasks:
$pendingTasksStr

Calendar Events:
$calendarEventsStr

For each suggested task, provide the following in JSON format:
1. title: A clear and specific task title
2. description: A brief description of the task
3. category: A suitable category (e.g., Work, Personal, Health, etc.)
4. priority: Either "high", "medium", or "low"
5. estimatedDuration: Estimated duration in minutes

Format your response as a valid JSON array of task objects.
''';
  }
  
  // Create a prompt for daily plan
  String _createDailyPlanPrompt({
    required List<Task> tasks,
    required List<Map<String, dynamic>> calendarEvents,
    required DateTime date,
  }) {
    final tasksStr = tasks.map((task) => 
      '- ${task.title} (Category: ${task.category}, Priority: ${task.priority.name}, Duration: ${task.duration?.inMinutes ?? 'unknown'} minutes)'
    ).join('\n');
    
    final calendarEventsStr = calendarEvents.map((event) => 
      '- ${event['title']} (${event['startTime']} - ${event['endTime']})'
    ).join('\n');
    
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    return '''
You are a smart daily planner assistant. Create an optimal schedule for $dateStr based on the user's tasks and calendar events.

Tasks to Schedule:
$tasksStr

Fixed Calendar Events:
$calendarEventsStr

Please create a time-blocked schedule for the day, allocating appropriate time for each task based on priority and estimated duration. Suggest optimal order and timing.

Format your response as a valid JSON with:
1. "timeBlocks": An array of scheduled blocks with "startTime", "endTime", "title", and "type" (either "task" or "event")
2. "recommendations": Brief suggestions for improving the day's productivity
3. "summary": A short summary of the day's focus areas
''';
  }
  
  // Create a prompt for sentiment analysis
  String _createSentimentAnalysisPrompt(String journalText) {
    return '''
Analyze the sentiment of the following journal entry. Provide a sentiment score from -1.0 (very negative) to 1.0 (very positive), and a brief analysis of the emotional tone.

Journal Entry:
$journalText

Format your response as a valid JSON with:
1. "sentiment": One of "veryNegative", "negative", "neutral", "positive", "veryPositive"
2. "score": A numerical score from -1.0 to 1.0
3. "analysis": A brief analysis of the emotional content (2-3 sentences)
''';
  }
  
  // Call OpenRouter API
  Future<String> _callOpenRouter(String prompt) async {
    try {
      final body = jsonEncode({
        'model': 'mistralai/mistral-7b-instruct',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      });
      
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: _headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('OpenRouter API error: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to get response from AI service');
      }
    } catch (e) {
      debugPrint('Error calling OpenRouter: $e');
      throw Exception('Failed to communicate with AI service');
    }
  }
  
  // Parse task suggestions from LLM response
  List<Task> _parseTaskSuggestions(String response) {
    try {
      // Try to extract JSON from the response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0 || jsonEnd <= jsonStart) {
        throw Exception('Invalid JSON response format');
      }
      
      final jsonStr = response.substring(jsonStart, jsonEnd);
      final List<dynamic> taskList = jsonDecode(jsonStr);
      
      return taskList.map((taskData) {
        final priority = _parsePriority(taskData['priority']);
        final duration = taskData['estimatedDuration'] != null 
            ? Duration(minutes: int.tryParse(taskData['estimatedDuration'].toString()) ?? 30) 
            : const Duration(minutes: 30);
            
        return Task(
          title: taskData['title'],
          description: taskData['description'] ?? '',
          category: taskData['category'] ?? 'Personal',
          priority: priority,
          duration: duration,
          isAiGenerated: true,
        );
      }).toList();
    } catch (error) {
      print('Error parsing task suggestions: $error');
      return [];
    }
  }
  
  // Parse daily plan from LLM response
  Map<String, dynamic> _parseDailyPlan(String response) {
    try {
      // Try to extract JSON from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0 || jsonEnd <= jsonStart) {
        throw Exception('Invalid JSON response format');
      }
      
      final jsonStr = response.substring(jsonStart, jsonEnd);
      return jsonDecode(jsonStr);
    } catch (error) {
      print('Error parsing daily plan: $error');
      return {
        'timeBlocks': [],
        'recommendations': 'Error parsing daily plan',
        'summary': 'Error parsing daily plan',
      };
    }
  }
  
  // Parse sentiment analysis from LLM response
  Map<String, dynamic> _parseSentimentAnalysis(String response) {
    try {
      // Try to extract JSON from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0 || jsonEnd <= jsonStart) {
        throw Exception('Invalid JSON response format');
      }
      
      final jsonStr = response.substring(jsonStart, jsonEnd);
      final Map<String, dynamic> result = jsonDecode(jsonStr);
      
      // Convert sentiment string to enum index
      final sentimentStr = result['sentiment']?.toString().toLowerCase() ?? 'neutral';
      int sentimentIndex;
      
      switch (sentimentStr) {
        case 'verynegative':
          sentimentIndex = SentimentType.veryNegative.index;
          break;
        case 'negative':
          sentimentIndex = SentimentType.negative.index;
          break;
        case 'positive':
          sentimentIndex = SentimentType.positive.index;
          break;
        case 'verypositive':
          sentimentIndex = SentimentType.veryPositive.index;
          break;
        default:
          sentimentIndex = SentimentType.neutral.index;
      }
      
      return {
        'sentiment': sentimentIndex,
        'score': double.tryParse(result['score'].toString()) ?? 0.0,
        'analysis': result['analysis'] ?? 'No analysis provided',
      };
    } catch (error) {
      print('Error parsing sentiment analysis: $error');
      return {
        'sentiment': SentimentType.neutral.index,
        'score': 0.0,
        'analysis': 'Error parsing sentiment analysis',
      };
    }
  }
  
  // Helper method to parse priority from string
  TaskPriority _parsePriority(String? priorityStr) {
    switch (priorityStr?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  // Suggest optimal timing for a new task based on past tasks
  Future<Map<String, dynamic>> suggestTaskTiming(String taskTitle, List<Task> existingTasks) async {
    try {
      // Filter to completed tasks with timing data
      final relevantTasks = existingTasks.where((task) => 
        task.status == TaskStatus.completed && 
        task.timerSessions != null && 
        task.timerSessions!.isNotEmpty
      ).toList();
      
      if (relevantTasks.isEmpty) {
        return {
          'suggestedStartTime': null,
          'suggestedDuration': null,
          'explanation': 'Not enough task history to make a suggestion.',
          'confidence': 0.0,
        };
      }
      
      // Format tasks for the prompt
      final taskData = relevantTasks.map((task) {
        final totalDuration = task.calculateTotalTimerDuration().inMinutes;
        final startTimeStr = task.startTime != null 
            ? '${task.startTime!.hour}:${task.startTime!.minute.toString().padLeft(2, '0')}'
            : 'unknown';
            
        return {
          'title': task.title,
          'category': task.category,
          'startTime': startTimeStr,
          'durationMinutes': totalDuration,
          'priority': task.priority.toString().split('.').last,
        };
      }).toList();
      
      // Create the prompt
      final prompt = '''
      Based on the following completed tasks and their timing data, suggest the optimal start time and duration for a new task titled "$taskTitle".
      
      EXISTING TASKS:
      ${jsonEncode(taskData)}
      
      Return a JSON object with the following structure:
      {
        "suggestedStartTime": "HH:MM" (24-hour format),
        "suggestedDuration": minutes (integer),
        "explanation": "brief explanation of why this timing is suggested",
        "confidence": 0.0-1.0 (confidence score)
      }
      
      Only return the JSON object, nothing else. If you can't make a confident suggestion, set confidence to 0.0.
      ''';
      
      // Call the LLM
      final response = await _callOpenRouter(prompt);
      
      // Parse the JSON response
      try {
        return jsonDecode(response);
      } catch (e) {
        debugPrint('Error parsing timing suggestion: $e');
        return {
          'suggestedStartTime': null,
          'suggestedDuration': null,
          'explanation': 'Unable to generate a timing suggestion.',
          'confidence': 0.0,
        };
      }
    } catch (e) {
      debugPrint('Error suggesting task timing: $e');
      return {
        'suggestedStartTime': null,
        'suggestedDuration': null,
        'explanation': 'Error generating timing suggestion.',
        'confidence': 0.0,
      };
    }
  }

  // Generate a simple daily plan based on pending tasks
  Future<String> generateDailyPlan(List<Task> pendingTasks) async {
    try {
      // Format tasks for the prompt
      final taskEntries = pendingTasks.map((task) {
        final priority = task.priority.toString().split('.').last;
        final estimatedDuration = task.duration != null 
            ? '${task.duration!.inMinutes} minutes' 
            : 'unknown duration';
            
        return '- ${task.title} (Priority: $priority, Category: ${task.category}, $estimatedDuration)';
      }).join('\n');
      
      // Create the prompt
      final prompt = '''
      Based on the following pending tasks, create an optimized daily plan.
      
      PENDING TASKS:
      $taskEntries
      
      Please provide:
      1. A suggested schedule with specific time blocks
      2. Task prioritization reasoning
      3. Breaks and rest periods
      4. Any tips for completing these tasks efficiently
      
      Format the schedule in a clear, easy-to-follow manner.
      ''';
      
      // Call the LLM
      final response = await _callOpenRouter(prompt);
      return response;
    } catch (e) {
      debugPrint('Error generating daily plan: $e');
      return 'Unable to generate a daily plan at this time. Please try again later.';
    }
  }
} 