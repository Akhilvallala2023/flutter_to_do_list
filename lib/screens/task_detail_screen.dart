import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_timer.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _priority;
  late String _category;
  final List<String> categories = ['Work', 'Personal', 'Shopping', 'Health', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadTaskData() {
    final tasks = ref.read(tasksProvider);
    final task = tasks.firstWhere((t) => t.id == widget.taskId);
    
    _titleController = TextEditingController(text: task.title);
    _descriptionController = TextEditingController(text: task.description);
    _priority = task.priority;
    _category = task.category;
  }

  void _saveTask() async {
    final taskNotifier = ref.read(tasksProvider.notifier);
    final tasks = ref.read(tasksProvider);
    final task = tasks.firstWhere((t) => t.id == widget.taskId);
    
    final updatedTask = task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _priority,
      category: _category,
    );
    
    await taskNotifier.updateTask(updatedTask);
    setState(() {
      _isEditing = false;
    });
  }

  void _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final taskNotifier = ref.read(tasksProvider.notifier);
      await taskNotifier.deleteTask(widget.taskId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _selectCategory() {
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

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _loadTaskData(); // Reset to original data
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final task = tasks.firstWhere((t) => t.id == widget.taskId);
    
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Task Details'),
        actions: [
          if (!_isEditing) IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _toggleEditing,
          ),
          if (_isEditing) IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
          ),
          if (_isEditing) IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: _toggleEditing,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: task.status == TaskStatus.completed
                    ? Colors.green.withOpacity(0.2)
                    : task.status == TaskStatus.inProgress
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                task.status == TaskStatus.completed
                    ? 'Completed'
                    : task.status == TaskStatus.inProgress
                        ? 'In Progress'
                        : 'Pending',
                style: TextStyle(
                  color: task.status == TaskStatus.completed
                      ? Colors.green
                      : task.status == TaskStatus.inProgress
                          ? Colors.blue
                          : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            if (_isEditing)
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const SizedBox(height: 16),
            
            // Description
            if (_isEditing)
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              )
            else if (task.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(task.description),
                  const SizedBox(height: 16),
                ],
              ),
            
            // Task Timer (only show if not editing)
            if (!_isEditing) ...[
              const Divider(),
              const SizedBox(height: 8),
              Center(
                child: TaskTimer(task: task),
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
            
            const SizedBox(height: 16),
            
            // Priority
            Row(
              children: [
                Text(
                  'Priority: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isEditing)
                  DropdownButton<TaskPriority>(
                    value: _priority,
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
                  )
                else
                  Text(
                    task.priority.toString().split('.').last,
                    style: TextStyle(
                      color: task.priority == TaskPriority.high
                          ? Colors.red
                          : task.priority == TaskPriority.medium
                              ? Colors.orange
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Category
            Row(
              children: [
                Text(
                  'Category: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isEditing)
                  TextButton(
                    onPressed: _selectCategory,
                    child: Text(_category),
                  )
                else
                  Text(task.category),
              ],
            ),
            const SizedBox(height: 16),
            
            // Time information
            Text(
              'Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Created'),
              trailing: Text(dateFormat.format(task.createdAt)),
            ),
            if (task.completedAt != null)
              ListTile(
                title: const Text('Completed'),
                trailing: Text(dateFormat.format(task.completedAt!)),
              ),
            if (task.endTime != null)
              ListTile(
                title: const Text('Due Date'),
                trailing: Text('${dateFormat.format(task.endTime!)} ${timeFormat.format(task.endTime!)}'),
              ),
          ],
        ),
      ),
    );
  }
} 