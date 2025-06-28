import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskTimer extends ConsumerStatefulWidget {
  final Task task;
  
  const TaskTimer({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  ConsumerState<TaskTimer> createState() => _TaskTimerState();
}

class _TaskTimerState extends ConsumerState<TaskTimer> {
  Timer? _timer;
  Duration _elapsed = const Duration();
  bool _isRunning = false;
  
  @override
  void initState() {
    super.initState();
    _updateElapsedTime();
    
    // Automatically start timer if task is not completed
    if (widget.task.status != TaskStatus.completed) {
      _startTimer();
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  // Calculate total elapsed time
  void _updateElapsedTime() {
    _elapsed = widget.task.calculateTotalTimerDuration();
  }
  
  // Start the timer
  void _startTimer() {
    final taskNotifier = ref.read(tasksProvider.notifier);
    
    // Update task in provider to start timer
    if (widget.task.timerStartedAt == null) {
      taskNotifier.startTaskTimer(widget.task.id);
    }
    
    // Start local timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateElapsedTime();
        });
      }
    });
    
    setState(() {
      _isRunning = true;
    });
  }
  
  // Complete the task and stop timer
  void _completeTask() {
    final taskNotifier = ref.read(tasksProvider.notifier);
    
    // Stop the timer first
    if (_isRunning) {
      taskNotifier.stopTaskTimer(widget.task.id);
      _timer?.cancel();
      _timer = null;
    }
    
    // Mark task as completed
    taskNotifier.completeTask(widget.task.id);
    
    setState(() {
      _isRunning = false;
      _updateElapsedTime();
    });
  }
  
  // Format duration as HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return '$hours:$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Time Tracking',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        
        CircularPercentIndicator(
          radius: 50.0,
          lineWidth: 8.0,
          percent: _isRunning ? 0.75 : 1.0, // Visual indicator only
          center: Text(
            _formatDuration(_elapsed),
            style: theme.textTheme.titleMedium,
          ),
          progressColor: _isRunning ? Colors.green : theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceVariant,
          animation: true,
          animationDuration: 300,
        ),
        
        const SizedBox(height: 16),
        
        // Only show complete button if task is not completed
        if (widget.task.status != TaskStatus.completed)
          ElevatedButton.icon(
            onPressed: _completeTask,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 45),
            ),
          )
        else
          Text(
            'Task Completed',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
} 