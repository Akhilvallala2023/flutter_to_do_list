import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  AddTaskScreenState createState() => AddTaskScreenState();
}

class AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  String _selectedCategory = 'Personal';
  final List<String> _categories = [
    'Personal',
    'Work',
    'Study',
    'Health',
    'Other',
  ];

  @override
  void dispose() {
    _taskTitleController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _addNewCategory() {
    final newCategory = _newCategoryController.text.trim();
    if (newCategory.isNotEmpty && !_categories.contains(newCategory)) {
      setState(() {
        _categories.add(newCategory);
        _selectedCategory = newCategory;
        _newCategoryController.clear();
      });
    }
  }

  void _addTask() {
    final taskTitle = _taskTitleController.text.trim();
    if (taskTitle.isNotEmpty) {
      Navigator.pop(context, {
        'title': taskTitle,
        'category': _selectedCategory,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        actions: [TextButton(onPressed: _addTask, child: const Text('Add'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TASK',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(hintText: 'Enter task title'),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'CATEGORY',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items:
                  _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      hintText: 'Add new category',
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _addNewCategory,
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
