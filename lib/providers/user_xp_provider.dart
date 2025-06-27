import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_xp_model.dart';
import '../models/task_model.dart';

// Provider for UserXP
final userXpProvider = StateNotifierProvider<UserXpNotifier, UserXP>((ref) {
  return UserXpNotifier();
});

class UserXpNotifier extends StateNotifier<UserXP> {
  UserXpNotifier() : super(UserXP()) {
    _loadUserXP();
  }
  
  // Load user XP data from SharedPreferences
  Future<void> _loadUserXP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userXpJson = prefs.getString('user_xp');
      
      if (userXpJson != null) {
        final userXpMap = json.decode(userXpJson) as Map<String, dynamic>;
        state = UserXP.fromMap(userXpMap);
      }
    } catch (e) {
      debugPrint('Error loading user XP: $e');
    }
  }
  
  // Save user XP data to SharedPreferences
  Future<void> _saveUserXP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userXpJson = json.encode(state.toMap());
      await prefs.setString('user_xp', userXpJson);
    } catch (e) {
      debugPrint('Error saving user XP: $e');
    }
  }
  
  // Add XP from a completed task
  void addTaskXP(Task task) {
    if (!task.xpClaimed) {
      state.addXP(task.xpEarned);
      _saveUserXP();
    }
  }
  
  // Add custom XP amount
  void addXP(int amount) {
    state.addXP(amount);
    _saveUserXP();
  }
  
  // Reset daily XP (typically called at midnight)
  void resetDailyXP() {
    state = UserXP(
      totalXP: state.totalXP,
      currentStreak: state.currentStreak,
      longestStreak: state.longestStreak,
      lastActivity: state.lastActivity,
      dailyXP: state.dailyXP,
      dailyXPCap: state.dailyXPCap,
    );
    _saveUserXP();
  }
  
  // Update daily XP cap
  void updateDailyXPCap(int newCap) {
    state = UserXP(
      totalXP: state.totalXP,
      currentDayXP: state.currentDayXP,
      currentStreak: state.currentStreak,
      longestStreak: state.longestStreak,
      lastActivity: state.lastActivity,
      dailyXP: state.dailyXP,
      dailyXPCap: newCap,
    );
    _saveUserXP();
  }
  
  // Check if a level up occurred
  bool checkLevelUp(int previousXP) {
    final currentLevel = calculateLevel(state.totalXP);
    final previousLevel = calculateLevel(previousXP);
    return currentLevel > previousLevel;
  }
  
  // Calculate user level based on XP
  int calculateLevel(int xp) {
    // Simple level calculation: level = sqrt(xp / 100)
    // Level 1: 0-100 XP
    // Level 2: 101-400 XP
    // Level 3: 401-900 XP, etc.
    return math.sqrt(xp / 100).floor() + 1;
  }
  
  // Get current user level
  int get currentLevel => calculateLevel(state.totalXP);
  
  // Get XP needed for next level
  int get xpForNextLevel {
    final nextLevel = currentLevel + 1;
    return (nextLevel - 1) * (nextLevel - 1) * 100;
  }
  
  // Get progress to next level (0.0 to 1.0)
  double get nextLevelProgress {
    final currentLevelXP = (currentLevel - 1) * (currentLevel - 1) * 100;
    final nextLevelXP = xpForNextLevel;
    final xpRange = nextLevelXP - currentLevelXP;
    final userProgress = state.totalXP - currentLevelXP;
    
    return userProgress / xpRange;
  }
} 