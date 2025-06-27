// Settings Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/preferences_provider.dart';
import '../config/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance section
          ListTile(
            title: const Text('Appearance'),
            subtitle: const Text('Theme and visual preferences'),
            leading: const Icon(Icons.palette),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(preferencesProvider.notifier).toggleDarkMode();
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          
          // AI Features section
          ListTile(
            title: const Text('AI Features'),
            subtitle: const Text('Smart suggestions and analysis'),
            leading: const Icon(Icons.auto_awesome),
          ),
          SwitchListTile(
            title: const Text('AI Suggestions'),
            subtitle: const Text('Get smart task recommendations'),
            value: true,
            onChanged: (value) {
              // Toggle AI suggestions
            },
            secondary: const Icon(Icons.lightbulb),
          ),
          const Divider(),
          
          // About section
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Smart TODO App v1.0.0'),
            leading: const Icon(Icons.info),
          ),
        ],
      ),
    );
  }
} 