import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/journal_model.dart';

class AiService {
  final Dio _dio = Dio();
  final String _openRouterApiKey;
  final String _openAiApiKey;
  
  // Choose which API to use
  static const bool _useOpenRouter = true;
  
  // API endpoints
  static const String _openRouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  // Get the appropriate API endpoint
  String get _apiEndpoint => _useOpenRouter ? _openRouterEndpoint : _openAiEndpoint;
  
  // Get the appropriate API key
  String get _apiKey => _useOpenRouter ? _openRouterApiKey : _openAiApiKey;
  
  // Get model name
  String get _modelName => _useOpenRouter ? 'mistralai/mistral-7b-instruct' : 'gpt-3.5-turbo';
  
  AiService({required String openRouterApiKey, required String openAiApiKey}) 
      : _openRouterApiKey = openRouterApiKey,
        _openAiApiKey = openAiApiKey;
  
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
      final response = await _callLlmApi(prompt);
      
      // Parse the response into Task objects
      return _parseTaskSuggestions(response);
    } catch (error) {
      print('Error generating task suggestions: $error');
      return [];
    }
  }
  
  // Generate a daily plan based on tasks and calendar events
  Future<Map<String, dynamic>> generateDailyPlan({
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
      final response = await _callLlmApi(prompt);
      
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
      final response = await _callLlmApi(prompt);
      
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
      // Create the prompt
      final prompt = _createWeeklySummaryPrompt(journals, completedTasks);
      
      // Call the API
      return await _callLlmApi(prompt);
    } catch (error) {
      print('Error generating weekly summary: $error');
      return 'Error generating weekly summary';
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
  
  // Create a prompt for weekly summary
  String _createWeeklySummaryPrompt(List<Journal> journals, List<Task> completedTasks) {
    final journalsStr = journals.map((journal) => 
      '- ${journal.date.toString().substring(0, 10)}: ${journal.content.substring(0, journal.content.length > 100 ? 100 : journal.content.length)}...'
    ).join('\n');
    
    final tasksStr = completedTasks.map((task) => 
      '- ${task.title} (Category: ${task.category}, Completed: ${task.completedAt?.toString().substring(0, 16)})'
    ).join('\n');
    
    return '''
Create a concise weekly summary based on the user's journal entries and completed tasks.

Journal Entries:
$journalsStr

Completed Tasks:
$tasksStr

Provide a summary that includes:
1. Main accomplishments
2. Patterns or trends in productivity
3. Suggestions for the upcoming week
4. Areas that might need more attention

Keep the summary positive, motivational, and actionable.
''';
  }
  
  // Call the LLM API
  Future<String> _callLlmApi(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    
    if (_useOpenRouter) {
      headers['HTTP-Referer'] = 'https://smart-todo-app.com';
    }
    
    final body = jsonEncode({
      'model': _modelName,
      'messages': [
        {'role': 'system', 'content': 'You are a helpful AI assistant for a smart todo app.'},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 1000,
    });
    
    final response = await http.post(
      Uri.parse(_apiEndpoint),
      headers: headers,
      body: body,
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to call LLM API: ${response.statusCode} ${response.body}');
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
} 