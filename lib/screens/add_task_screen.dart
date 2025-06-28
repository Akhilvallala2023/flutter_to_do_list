// Add Task Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/google_calendar_service.dart';
import '../services/google_auth_service.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  
  const AddTaskScreen({Key? key, this.initialDate}) : super(key: key);

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _startTime;
  DateTime? _endTime;
  TaskPriority _priority = TaskPriority.medium;
  String _category = 'Personal';
  bool _isLoading = false;
  bool _useAiSuggestion = false;
  Map<String, dynamic>? _aiSuggestion;

  final List<String> _categories = ['Work', 'Personal', 'Shopping', 'Health', 'Other'];

  @override
  void initState() {
    super.initState();
    
    // Initialize start time with initialDate if provided
    if (widget.initialDate != null) {
      final now = DateTime.now();
      // Set time to current time but date to initialDate
      _startTime = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        now.hour,
        now.minute,
      );
      
      // Set default end time to 1 hour after start time
      _endTime = _startTime!.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Get AI suggestion for task timing
  Future<void> _getAiSuggestion() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestion = await ref.read(taskTimeSuggestionsProvider(_titleController.text).future);
      
      setState(() {
        _aiSuggestion = suggestion;
        _isLoading = false;
        
        if (suggestion != null && suggestion['confidence'] > 0.5) {
          _useAiSuggestion = true;
          
          // Parse suggested start time if available
          final suggestedStartTime = suggestion['suggestedStartTime'];
          if (suggestedStartTime != null) {
            final timeParts = suggestedStartTime.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);
              
              if (hour != null && minute != null) {
                final now = DateTime.now();
                _startTime = DateTime(now.year, now.month, now.day, hour, minute);
                
                // Calculate end time based on suggested duration
                final suggestedDuration = suggestion['suggestedDuration'];
                if (suggestedDuration != null) {
                  _endTime = _startTime!.add(Duration(minutes: suggestedDuration));
                }
              }
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting AI suggestion: $e')),
      );
    }
  }

  // Save the task
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if Google Sign-In is available
    final googleAuthService = ref.read(googleAuthServiceProvider);
    bool isGoogleSignedIn = googleAuthService.isSignedIn;
    
    // If not signed in, ask user if they want to sign in
    if (!isGoogleSignedIn) {
      final shouldSignIn = await _showGoogleSignInDialog();
      
      if (shouldSignIn) {
        final success = await googleAuthService.signIn();
        isGoogleSignedIn = success;
        
        if (!success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to sign in with Google')),
          );
        }
      }
    }

    // Create the task
    final task = Task(
      title: _titleController.text,
      description: _descriptionController.text,
      startTime: _startTime,
      endTime: _endTime,
      priority: _priority,
      category: _category,
    );

    // Add the task
    await ref.read(tasksProvider.notifier).addTask(task);

    // Show success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task added successfully')),
    );

    // Navigate back
    Navigator.pop(context);
  }

  // Show dialog to ask user if they want to sign in with Google
  Future<bool> _showGoogleSignInDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Calendar Integration'),
        content: const Text(
          'Would you like to sync this task with Google Calendar? '
          'This will require signing in with your Google account.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Watch for AI suggestions
    final aiSuggestionAsync = ref.watch(
      taskTimeSuggestionsProvider(_titleController.text)
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Clear AI suggestion when title changes
                  setState(() {
                    _aiSuggestion = null;
                    _useAiSuggestion = false;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // AI Suggestion Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getAiSuggestion,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lightbulb_outline),
                label: const Text('Get AI Timing Suggestion'),
              ),
              const SizedBox(height: 8),
              
              // AI Suggestion Display
              if (_aiSuggestion != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Suggestion',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _useAiSuggestion,
                              onChanged: (value) {
                                setState(() {
                                  _useAiSuggestion = value;
                                  
                                  if (value && _aiSuggestion != null) {
                                    // Apply AI suggestion
                                    final suggestedStartTime = _aiSuggestion!['suggestedStartTime'];
                                    if (suggestedStartTime != null) {
                                      final timeParts = suggestedStartTime.split(':');
                                      if (timeParts.length == 2) {
                                        final hour = int.tryParse(timeParts[0]);
                                        final minute = int.tryParse(timeParts[1]);
                                        
                                        if (hour != null && minute != null) {
                                          final now = DateTime.now();
                                          _startTime = DateTime(now.year, now.month, now.day, hour, minute);
                                          
                                          // Calculate end time based on suggested duration
                                          final suggestedDuration = _aiSuggestion!['suggestedDuration'];
                                          if (suggestedDuration != null) {
                                            _endTime = _startTime!.add(Duration(minutes: suggestedDuration));
                                          }
                                        }
                                      }
                                    }
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        if (_aiSuggestion!['suggestedStartTime'] != null)
                          Text('Start time: ${_aiSuggestion!['suggestedStartTime']}'),
                        if (_aiSuggestion!['suggestedDuration'] != null)
                          Text('Duration: ${_aiSuggestion!['suggestedDuration']} minutes'),
                        const SizedBox(height: 8),
                        Text('${_aiSuggestion!['explanation']}'),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _aiSuggestion!['confidence'] ?? 0.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _aiSuggestion!['confidence'] > 0.7
                                ? Colors.green
                                : _aiSuggestion!['confidence'] > 0.4
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(_aiSuggestion!['confidence'] * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Start Time
              Row(
                children: [
                  const Text('Start Time: '),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startTime ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
                        );
                        
                        if (time != null) {
                          setState(() {
                            _startTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            
                            // If end time is not set or is before start time, set it to start time + 1 hour
                            if (_endTime == null || _endTime!.isBefore(_startTime!)) {
                              _endTime = _startTime!.add(const Duration(hours: 1));
                            }
                          });
                        }
                      }
                    },
                    child: Text(
                      _startTime == null
                          ? 'Select'
                          : DateFormat('MMM dd, yyyy - hh:mm a').format(_startTime!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // End Time
              Row(
                children: [
                  const Text('End Time: '),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endTime ?? (_startTime?.add(const Duration(hours: 1)) ?? DateTime.now()),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_endTime ?? (_startTime?.add(const Duration(hours: 1)) ?? DateTime.now())),
                        );
                        
                        if (time != null) {
                          setState(() {
                            _endTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text(
                      _endTime == null
                          ? 'Select'
                          : DateFormat('MMM dd, yyyy - hh:mm a').format(_endTime!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Priority
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Save Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 