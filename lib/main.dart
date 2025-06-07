import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter To-Do Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: const TodoListScreen(),
    );
  }
}

class Todo {
  String title;
  bool isCompleted;
  String category;
  bool isRunning;
  Duration elapsedTime;
  DateTime? startTime;
  DateTime? completionTime;

  Todo({
    required this.title,
    this.isCompleted = false,
    this.isRunning = false,
    this.category = 'Personal',
    this.elapsedTime = Duration.zero,
  });
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  final Map<int, Timer> _timers = {};
  int _currentXp = 0;
  int _level = 0;
  String _currentView = 'To-Do List';

  void _addXpAndLevelUp(int xpToAdd) {
    setState(() {
      _currentXp += xpToAdd;
      while (_currentXp >= (_level + 1) * 50) {
        _currentXp -= (_level + 1) * 50;
        _level++;
      }
    });
  }

  void _addTodoItem(Todo task) {
    _todos.add(task);
    _todos.sort((a, b) => a.isCompleted ? 1 : -1);
  }

  void _removeTodoItem(int index) {
    _stopTimer(index);
    setState(() {
      _todos.removeAt(index);
    });
  }

  void _toggleTodoComplete(int index) {
    _stopTimer(index);
    setState(() {
      _todos[index].isCompleted = true;
      _todos[index].completionTime = DateTime.now();
    });
    _addXpAndLevelUp(10);
  }

  void _toggleTimer(int index) {
    final todo = _todos[index];
    if (todo.isRunning) {
      _stopTimer(index);
    } else {
      _startTimer(index);
    }
    setState(() {});
  }

  void _startTimer(int index) {
    _stopAllTimers();
    final todo = _todos[index];
    todo.isRunning = true;
    todo.startTime = DateTime.now();

    _timers[index] = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  void _stopTimer(int index) {
    final todo = _todos[index];
    if (todo.startTime != null) {
      todo.elapsedTime += DateTime.now().difference(todo.startTime!);
    }
    _timers[index]?.cancel();
    _timers.remove(index);
    todo.isRunning = false;
    todo.startTime = null;
  }

  void _stopAllTimers() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    for (var todo in _todos) {
      if (todo.isRunning && todo.startTime != null) {
        todo.elapsedTime += DateTime.now().difference(todo.startTime!);
      }
      todo.isRunning = false;
      todo.startTime = null;
    }
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _stopAllTimers();
    super.dispose();
  }

  void _selectView(String viewName) {
    Navigator.pop(context); // Close drawer
    setState(() {
      _currentView = viewName;
    });
  }

  @override
  Widget build(BuildContext context) {
    int xpNeededForNextLevel = (_level + 1) * 50;
    double progress = xpNeededForNextLevel > 0 ? _currentXp / xpNeededForNextLevel : 0.0;

    final List<Todo> displayedTodos = _currentView == 'To-Do List'
        ? _todos.where((todo) => !todo.isCompleted).toList()
        : _todos.where((todo) => todo.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('To-Do List'),
              onTap: () => _selectView('To-Do List'),
            ),
            ListTile(
              title: const Text('Completed Tasks'),
              onTap: () => _selectView('Completed Tasks'),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text('XP: $_currentXp'),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                  ),
                ),
                Text('  Level: $_level'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayedTodos.length,
              itemBuilder: (context, index) {
                final todo = displayedTodos[index];
                final originalIndex = _todos.indexOf(todo);

                if (_currentView == 'To-Do List') {
                  final displayTime = todo.isRunning
                      ? DateTime.now().difference(todo.startTime!) + todo.elapsedTime
                      : todo.elapsedTime;

                  return ListTile(
                    title: Text(todo.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(todo.category),
                        if (todo.isRunning || todo.elapsedTime > Duration.zero)
                          Text('⏱ ${_formatDuration(displayTime)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            todo.isRunning ? Icons.pause : Icons.play_arrow,
                            color: Colors.blue,
                          ),
                          onPressed: () => _toggleTimer(originalIndex),
                        ),
                        Checkbox(
                          value: todo.isCompleted,
                          onChanged: (bool? newValue) {
                            if (newValue == true) {
                              _toggleTodoComplete(originalIndex);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text(
                      todo.title,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (todo.completionTime != null)
                          Text('Completed at: ${_formatTime(todo.completionTime!)}'),
                        Text('Time spent: ${_formatDuration(todo.elapsedTime)}'),
                      ],
                    ),
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _removeTodoItem(_todos.indexOf(todo));
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push<Map<String, String>>(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          ).then((result) {
            if (result != null) {
              final String title = result['title'] ?? '';
              final String category = result['category'] ?? 'Personal';
              setState(() {
                _addTodoItem(Todo(title: title, category: category));
                _currentView = 'To-Do List';
              });
            }
          });
        },
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  String _selectedCategory = 'Personal';
  final List<String> _categories = ['Personal', 'Work', 'Study', 'Health', 'Other'];

  void _addNewCategory() {
    final newCat = _newCategoryController.text.trim();
    if (newCat.isNotEmpty && !_categories.contains(newCat)) {
      setState(() {
        _categories.add(newCat);
        _selectedCategory = newCat;
        _newCategoryController.clear();
      });
    }
  }

  void _submitTask() {
    final title = _taskTitleController.text.trim();
    if (title.isNotEmpty) {
      Navigator.pop(context, {'title': title, 'category': _selectedCategory});
    }
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(onPressed: _submitTask, child: const Text('Add')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TASK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(hintText: 'Enter task title'),
            ),
            const SizedBox(height: 16.0),
            const Text('CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              items: _categories
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(hintText: 'Add new category'),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(onPressed: _addNewCategory, child: const Text('Add')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
