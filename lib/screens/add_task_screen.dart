// Add Task Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../config/theme.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  String _category = 'Personal';
  DateTime? _startTime;
  DateTime? _endTime;
  Duration? _duration;
  bool _useAiSuggestions = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        category: _category,
        startTime: _startTime,
        endTime: _endTime,
        duration: _duration,
        isAiGenerated: _useAiSuggestions,
      );
      
      ref.read(tasksProvider.notifier).addTask(task);
      Navigator.pop(context);
    }
  }
  
  Future<void> _selectStartTime() async {
    final initialDate = _startTime ?? DateTime.now();
    final initialTime = TimeOfDay.fromDateTime(initialDate);
    
    // Select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      // Select time
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      
      if (pickedTime != null) {
        setState(() {
          _startTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          // If end time is set and is before start time, clear it
          if (_endTime != null && _endTime!.isBefore(_startTime!)) {
            _endTime = null;
          }
          
          // If duration is set, calculate end time
          if (_duration != null) {
            _endTime = _startTime!.add(_duration!);
          }
        });
      }
    }
  }
  
  Future<void> _selectEndTime() async {
    final initialDate = _endTime ?? (_startTime?.add(const Duration(hours: 1)) ?? DateTime.now());
    final initialTime = TimeOfDay.fromDateTime(initialDate);
    
    // Select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      // Select time
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      
      if (pickedTime != null) {
        setState(() {
          _endTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          // If start time is set, calculate duration
          if (_startTime != null) {
            _duration = _endTime!.difference(_startTime!);
          }
        });
      }
    }
  }
  
  void _selectDuration() {
    showDialog(
      context: context,
      builder: (context) {
        int hours = _duration?.inHours ?? 0;
        int minutes = (_duration?.inMinutes ?? 0) % 60;
        
        return AlertDialog(
          title: const Text('Set Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text('Hours'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: hours.toString()),
                          onChanged: (value) {
                            hours = int.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      const Text('Minutes'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: minutes.toString()),
                          onChanged: (value) {
                            minutes = int.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _duration = Duration(hours: hours, minutes: minutes);
                  
                  // If start time is set, calculate end time
                  if (_startTime != null) {
                    _endTime = _startTime!.add(_duration!);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  void _selectCategory() {
    final categories = ['Personal', 'Work', 'Health', 'Shopping', 'Education', 'Other'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category),
                  trailing: _category == category ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() {
                      _category = category;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Priority
              Text(
                'Priority',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(
                    value: TaskPriority.low,
                    label: Text('Low'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TaskPriority.medium,
                    label: Text('Medium'),
                    icon: Icon(Icons.remove),
                  ),
                  ButtonSegment(
                    value: TaskPriority.high,
                    label: Text('High'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<TaskPriority> newSelection) {
                  setState(() {
                    _priority = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Category
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_category),
                trailing: const Icon(Icons.arrow_drop_down),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onTap: _selectCategory,
              ),
              const SizedBox(height: 16),
              
              // Time
              Text(
                'Time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_startTime == null
                    ? 'Select start time'
                    : 'Start: ${dateFormat.format(_startTime!)} at ${timeFormat.format(_startTime!)}'),
                trailing: const Icon(Icons.access_time),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onTap: _selectStartTime,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_endTime == null
                    ? 'Select end time'
                    : 'End: ${dateFormat.format(_endTime!)} at ${timeFormat.format(_endTime!)}'),
                trailing: const Icon(Icons.access_time),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onTap: _selectEndTime,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_duration == null
                    ? 'Set duration'
                    : 'Duration: ${_duration!.inHours}h ${_duration!.inMinutes % 60}m'),
                trailing: const Icon(Icons.timer),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onTap: _selectDuration,
              ),
              const SizedBox(height: 16),
              
              // AI Suggestions
              SwitchListTile(
                title: const Text('Use AI suggestions'),
                subtitle: const Text('Let AI help optimize this task'),
                value: _useAiSuggestions,
                onChanged: (value) {
                  setState(() {
                    _useAiSuggestions = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 