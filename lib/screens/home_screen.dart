import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/user_xp_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/timeline_view.dart';
import '../widgets/user_level_card.dart';
import '../config/theme.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';
import '../calendar_view.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load tasks on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tasks will load automatically via provider
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _onTaskTap(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }
  
  void _addNewTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );
  }
  
  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final pendingTasks = ref.watch(pendingTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);
    final inProgressTasks = ref.watch(inProgressTasksProvider);
    final todayTasks = ref.watch(tasksByDateProvider(_selectedDate));
    final userXP = ref.watch(userXpProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart TODO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarScreen(
                    tasks: ref.read(tasksProvider).map((task) => {
                      'date': task.startTime ?? DateTime.now(),
                      'todo': task,
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: _currentIndex == 0
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Completed'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // User Level Card
          if (_currentIndex == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: UserLevelCard(showDetails: false),
            ),
          
          // Navigation tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(0, 'Tasks', Icons.check_circle_outline),
                _buildNavButton(1, 'Timeline', Icons.timeline),
                _buildNavButton(2, 'Journal', Icons.book),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                // Tasks tab
                TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending tasks
                    _buildTaskList(pendingTasks),
                    
                    // In progress tasks
                    _buildTaskList(inProgressTasks),
                    
                    // Completed tasks
                    _buildTaskList(completedTasks),
                  ],
                ),
                
                // Timeline tab
                TimelineView(
                  tasks: todayTasks,
                  date: _selectedDate,
                  onTaskTap: _onTaskTap,
                ),
                
                // Journal tab
                const JournalScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildNavButton(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: AnimationDurations.medium,
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: AnimationDurations.medium,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new task',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: AnimationDurations.medium,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: TaskCard(
                  task: tasks[index],
                  onTap: () => _onTaskTap(tasks[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 