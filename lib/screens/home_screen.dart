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
import '../services/google_auth_service.dart';
import '../services/google_calendar_service.dart';
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
  bool _isCalendarSyncing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load tasks on startup and check Google Calendar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGoogleCalendarStatus();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  // Check Google Calendar status and initialize if needed
  Future<void> _checkGoogleCalendarStatus() async {
    final googleAuthService = ref.read(googleAuthServiceProvider);
    await googleAuthService.init();
    
    // If already signed in, sync with Google Calendar
    if (googleAuthService.isSignedIn) {
      _syncWithGoogleCalendar();
    }
  }
  
  // Sync tasks with Google Calendar
  Future<void> _syncWithGoogleCalendar() async {
    setState(() {
      _isCalendarSyncing = true;
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
        _isCalendarSyncing = false;
      });
    }
  }
  
  // Sign in with Google
  Future<void> _signInWithGoogle() async {
    final googleAuthService = ref.read(googleAuthServiceProvider);
    
    try {
      final success = await googleAuthService.signIn();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in with Google')),
        );
        
        // Sync with Google Calendar
        _syncWithGoogleCalendar();
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in with Google')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in with Google: $e')),
        );
      }
    }
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
    final googleAuthService = ref.watch(googleAuthServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart TODO'),
        actions: [
          // Google Calendar sync button
          IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  googleAuthService.isSignedIn 
                      ? Icons.cloud_done 
                      : Icons.cloud_off,
                  color: googleAuthService.isSignedIn 
                      ? Colors.green 
                      : Colors.grey,
                ),
                if (_isCalendarSyncing)
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
            onPressed: googleAuthService.isSignedIn 
                ? _syncWithGoogleCalendar 
                : _signInWithGoogle,
            tooltip: googleAuthService.isSignedIn 
                ? 'Sync with Google Calendar' 
                : 'Sign in with Google',
          ),
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
                  onDateChanged: _changeDate,
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
          ],
        ),
      );
    }
    
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: AnimationDurations.medium,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: TaskCard(
                  task: task,
                  onTap: () => _onTaskTap(task),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 