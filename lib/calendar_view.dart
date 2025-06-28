import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'models/task_model.dart';
import 'providers/task_provider.dart';
import 'services/google_calendar_service.dart';
import 'services/google_auth_service.dart';
import 'screens/task_detail_screen.dart';
import 'screens/add_task_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> tasks;

  const CalendarScreen({super.key, required this.tasks});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;
  bool _showGoogleCalendarEvents = true;

  @override
  void initState() {
    super.initState();
    _syncWithGoogleCalendar();
  }

  // Sync with Google Calendar
  Future<void> _syncWithGoogleCalendar() async {
    final googleAuthService = ref.read(googleAuthServiceProvider);
    
    if (!googleAuthService.isSignedIn) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(tasksProvider.notifier).syncWithGoogleCalendar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing with Google Calendar: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add a new task for the selected date
  void _addNewTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(initialDate: _selectedDay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(tasksProvider);
    final googleAuthService = ref.watch(googleAuthServiceProvider);
    
    // Get tasks for the selected day
    final selectedDayTasks = _getTasksForDay(allTasks, _selectedDay);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        actions: [
          // Google Calendar sync indicator
          if (googleAuthService.isSignedIn)
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _showGoogleCalendarEvents 
                        ? Icons.cloud_done 
                        : Icons.cloud_off,
                    color: _showGoogleCalendarEvents 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                setState(() {
                  _showGoogleCalendarEvents = !_showGoogleCalendarEvents;
                });
                if (_showGoogleCalendarEvents) {
                  _syncWithGoogleCalendar();
                }
              },
              tooltip: _showGoogleCalendarEvents 
                  ? 'Hide Google Calendar events' 
                  : 'Show Google Calendar events',
            ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: (day) => _getTasksForDay(allTasks, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildTaskList(selectedDayTasks),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Get tasks for a specific day
  List<Task> _getTasksForDay(List<Task> allTasks, DateTime day) {
    // Filter tasks based on Google Calendar setting
    List<Task> filteredTasks = _showGoogleCalendarEvents 
        ? allTasks 
        : allTasks.where((task) => task.googleCalendarEventId == null).toList();
    
    // Filter for the specific day
    return filteredTasks.where((task) {
      if (task.startTime == null) return false;
      
      return isSameDay(task.startTime!, day);
    }).toList();
  }

  // Build task list for selected day
  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks for this day'),
      );
    }
    
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _buildPriorityIndicator(task.priority),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.status == TaskStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              _getTaskTimeString(task),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: task.googleCalendarEventId != null
                ? const Icon(Icons.event, size: 16, color: Colors.blue)
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(taskId: task.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Build priority indicator
  Widget _buildPriorityIndicator(TaskPriority priority) {
    Color color;
    switch (priority) {
      case TaskPriority.high:
        color = Colors.red;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        break;
      case TaskPriority.low:
        color = Colors.green;
        break;
    }
    
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // Get formatted time string for task
  String _getTaskTimeString(Task task) {
    if (task.startTime == null) return '';
    
    final timeFormat = DateFormat('h:mm a');
    final startTimeStr = timeFormat.format(task.startTime!);
    
    if (task.endTime != null) {
      final endTimeStr = timeFormat.format(task.endTime!);
      return '$startTimeStr - $endTimeStr';
    }
    
    return startTimeStr;
  }
} 