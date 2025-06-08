import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;

  const CalendarScreen({super.key, required this.tasks});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Map<String, dynamic>> _getTasksForDay(DateTime day) {
    return widget.tasks.where((entry) {
      final DateTime date = entry['date'];
      return date.year == day.year &&
             date.month == day.month &&
             date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksForDay = _getTasksForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text("Calendar View")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tasks on ${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: tasksForDay.isEmpty
                ? const Center(child: Text("No tasks found."))
                : ListView.builder(
                    itemCount: tasksForDay.length,
                    itemBuilder: (context, index) {
                      final todo = tasksForDay[index]['todo'];
                      return ListTile(
                        title: Text(todo.title),
                        subtitle: Text(todo.isCompleted ? 'Completed' : 'Pending'),
                        trailing: Icon(
                          todo.isCompleted ? Icons.check_circle : Icons.pending,
                          color: todo.isCompleted ? Colors.green : Colors.orange,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
