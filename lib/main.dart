import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/task_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/user_xp_provider.dart';
import 'screens/home_screen.dart';
import 'config/theme.dart';
import 'services/storage_service.dart';
import 'services/google_auth_service.dart';
import 'services/google_calendar_service.dart';
import 'services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Provider to track app initialization status
final appInitializationProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
    // Continue without .env file
  }
  
  // Initialize Hive for local storage
  await StorageService.initialize();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // Initialize all services
  Future<void> _initializeServices() async {
    try {
      // Initialize Google Auth service
      final googleAuthService = ref.read(googleAuthServiceProvider);
      await googleAuthService.init();
      
      // Initialize Google Calendar service
      if (googleAuthService.isSignedIn) {
        final calendarService = ref.read(googleCalendarServiceProvider);
        await calendarService.init();
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
    } finally {
      // Mark initialization as complete
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        ref.read(appInitializationProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Smart TODO',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: _isInitializing 
          ? const _LoadingScreen() 
          : const HomeScreen(),
    );
  }
}

// Simple loading screen
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline, 
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart TODO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
