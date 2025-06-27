import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/task_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/user_xp_provider.dart';
import 'screens/home_screen.dart';
import 'config/theme.dart';
import 'services/storage_service.dart';
import 'services/ai_service.dart';
import 'services/google_calendar_service.dart';
import 'services/supabase_service.dart';

// Providers for services
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    openRouterApiKey: const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: 'YOUR_OPENROUTER_API_KEY'),
    openAiApiKey: const String.fromEnvironment('OPENAI_API_KEY', defaultValue: 'YOUR_OPENAI_API_KEY'),
  );
});

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await StorageService.initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeProvider);
    
    // Initialize Google Calendar service
    ref.read(googleCalendarServiceProvider).initialize();
    
    return MaterialApp(
      title: 'Smart TODO',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const HomeScreen(),
    );
  }
}
