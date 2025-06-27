import 'package:intl/intl.dart';
import 'dart:math' as math;

class UserXP {
  int totalXP;
  int currentDayXP;
  int currentStreak;
  int longestStreak;
  DateTime lastActivity;
  Map<String, int> dailyXP;
  int dailyXPCap;
  
  UserXP({
    this.totalXP = 0,
    this.currentDayXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastActivity,
    Map<String, int>? dailyXP,
    this.dailyXPCap = 110,
  }) : 
    lastActivity = lastActivity ?? DateTime.now(),
    dailyXP = dailyXP ?? {};
  
  // Add XP to the user's total and update streaks
  void addXP(int amount) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastActivityDate = DateFormat('yyyy-MM-dd').format(lastActivity);
    
    // Update total XP
    totalXP += amount;
    
    // Update daily XP
    if (!dailyXP.containsKey(today)) {
      dailyXP[today] = 0;
    }
    
    // Apply daily cap
    int remainingDailyXP = dailyXPCap - (dailyXP[today] ?? 0);
    int cappedAmount = amount > remainingDailyXP ? remainingDailyXP : amount;
    
    dailyXP[today] = (dailyXP[today] ?? 0) + cappedAmount;
    currentDayXP = dailyXP[today] ?? 0;
    
    // Update streak
    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1))
    );
    
    if (today != lastActivityDate) {
      if (lastActivityDate == yesterday) {
        // Consecutive day, increase streak
        currentStreak++;
      } else {
        // Streak broken
        currentStreak = 1;
      }
      
      // Update longest streak if needed
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }
    
    // Update last activity
    lastActivity = DateTime.now();
  }
  
  // Check if the user has reached the daily XP cap
  bool isDailyCapReached() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return (dailyXP[today] ?? 0) >= dailyXPCap;
  }
  
  // Get remaining XP for today
  int getRemainingDailyXP() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return dailyXPCap - (dailyXP[today] ?? 0);
  }
  
  // Get progress towards daily XP cap (0.0 to 1.0)
  double getDailyProgress() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return (dailyXP[today] ?? 0) / dailyXPCap;
  }
  
  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'totalXP': totalXP,
      'currentDayXP': currentDayXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'dailyXP': dailyXP,
      'dailyXPCap': dailyXPCap,
    };
  }
  
  // Create from Map
  factory UserXP.fromMap(Map<String, dynamic> map) {
    return UserXP(
      totalXP: map['totalXP'] ?? 0,
      currentDayXP: map['currentDayXP'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActivity: map['lastActivity'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActivity']) 
          : DateTime.now(),
      dailyXP: map['dailyXP'] != null 
          ? Map<String, int>.from(map['dailyXP']) 
          : {},
      dailyXPCap: map['dailyXPCap'] ?? 110,
    );
  }
} 