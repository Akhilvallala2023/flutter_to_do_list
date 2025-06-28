import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../config/theme.dart';
import '../providers/preferences_provider.dart';

class TimelineView extends ConsumerWidget {
  final List<Task> tasks;
  final DateTime date;
  final Function(Task) onTaskTap;
  final Function(DateTime)? onDateChanged;
  
  const TimelineView({
    super.key,
    required this.tasks,
    required this.date,
    required this.onTaskTap,
    this.onDateChanged,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workingHours = ref.watch(workingHoursProvider);
    final startHour = workingHours.$1;
    final endHour = workingHours.$2;
    
    // Sort tasks by start time
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) {
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });
    
    // Filter tasks with start time only
    final scheduledTasks = sortedTasks.where((task) => task.startTime != null).toList();
    final unscheduledTasks = sortedTasks.where((task) => task.startTime == null).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Previous day button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  if (onDateChanged != null) {
                    onDateChanged!(date.subtract(const Duration(days: 1)));
                  }
                },
              ),
              
              // Date display
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (onDateChanged != null) {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (selectedDate != null) {
                        onDateChanged!(selectedDate);
                      }
                    }
                  },
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(date),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Next day button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  if (onDateChanged != null) {
                    onDateChanged!(date.add(const Duration(days: 1)));
                  }
                },
              ),
            ],
          ),
        ),
        
        // Timeline
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Time blocks
                for (int hour = startHour; hour <= endHour; hour++)
                  _buildTimeBlock(context, hour, scheduledTasks),
                
                // Unscheduled tasks section
                if (unscheduledTasks.isNotEmpty) ...[
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Unscheduled Tasks',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final task in unscheduledTasks)
                    _buildUnscheduledTask(context, task),
                ],
                
                // Empty state
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks scheduled for this day',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Extra padding at bottom
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeBlock(BuildContext context, int hour, List<Task> scheduledTasks) {
    final timeFormat = DateFormat('h:mm a');
    final startTime = DateTime(date.year, date.month, date.day, hour);
    final endTime = DateTime(date.year, date.month, date.day, hour + 1);
    
    // Find tasks that fall within this hour
    final tasksInHour = scheduledTasks.where((task) {
      if (task.startTime == null) return false;
      
      final taskStart = task.startTime!;
      final taskEnd = task.endTime ?? 
                     (task.duration != null ? taskStart.add(task.duration!) : taskStart.add(const Duration(hours: 1)));
      
      // Check if task overlaps with this hour
      return (taskStart.isBefore(endTime) && taskEnd.isAfter(startTime));
    }).toList();
    
    return Column(
      children: [
        // Hour marker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  timeFormat.format(startTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
        
        // Tasks in this hour
        if (tasksInHour.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 76.0, right: 16.0, top: 8.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tasksInHour.map((task) => _buildTimelineTask(context, task)).toList(),
            ),
          )
        else
          const SizedBox(height: 40),
      ],
    );
  }
  
  Widget _buildTimelineTask(BuildContext context, Task task) {
    final timeFormat = DateFormat('h:mm a');
    final textTheme = Theme.of(context).textTheme;
    
    // Format time
    String timeString = '';
    if (task.startTime != null) {
      timeString = timeFormat.format(task.startTime!);
      
      if (task.endTime != null) {
        timeString += ' - ${timeFormat.format(task.endTime!)}';
      } else if (task.duration != null) {
        final endTime = task.startTime!.add(task.duration!);
        timeString += ' - ${timeFormat.format(endTime)}';
      }
    }
    
    // Priority color
    final priorityColor = TaskColors.getPriorityColor(task.priority.index);
    
    return InkWell(
      onTap: () => onTaskTap(task),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: textTheme.titleMedium?.copyWith(
                      decoration: task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnscheduledTask(BuildContext context, Task task) {
    final textTheme = Theme.of(context).textTheme;
    final priorityColor = TaskColors.getPriorityColor(task.priority.index);
    
    return InkWell(
      onTap: () => onTaskTap(task),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: textTheme.titleMedium?.copyWith(
                  decoration: task.status == TaskStatus.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              task.category,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 