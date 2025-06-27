import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskTimer extends ConsumerStatefulWidget {
  final Task task;
  final bool showControls;
  final bool showSummary;
  
  const TaskTimer({
    Key? key,
    required this.task,
    this.showControls = true,
    this.showSummary = true,
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
    
    // Check if timer was already running
    if (widget.task.timerStartedAt != null) {
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
  
  // Stop the timer
  void _stopTimer() {
    final taskNotifier = ref.read(tasksProvider.notifier);
    
    // Update task in provider to stop timer
    taskNotifier.stopTaskTimer(widget.task.id);
    
    // Stop local timer
    _timer?.cancel();
    _timer = null;
    
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
  
  // Calculate progress percentage if task has an estimated duration
  double _calculateProgress() {
    if (widget.task.duration == null || widget.task.duration!.inSeconds == 0) {
      return 0.0;
    }
    
    return _elapsed.inSeconds / widget.task.duration!.inSeconds;
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSummary) ...[
          Text(
            'Time Tracked',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        
        CircularPercentIndicator(
          radius: 50.0,
          lineWidth: 8.0,
          percent: progress.isFinite && progress <= 1.0 ? progress : 0.0,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(_elapsed),
                style: theme.textTheme.titleMedium,
              ),
              if (widget.task.duration != null) ...[
                const SizedBox(height: 4),
                Text(
                  'of ${_formatDuration(widget.task.duration!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
          progressColor: _isRunning ? Colors.green : theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceVariant,
          animation: true,
          animationDuration: 300,
        ),
        
        if (widget.showControls) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning)
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _stopTimer,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
        
        if (widget.showSummary && widget.task.timerSessions != null && widget.task.timerSessions!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Sessions: ${widget.task.timerSessions!.length}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
} 