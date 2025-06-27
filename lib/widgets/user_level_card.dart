import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:confetti/confetti.dart';
import '../providers/user_xp_provider.dart';

class UserLevelCard extends ConsumerStatefulWidget {
  final bool showDetails;
  
  const UserLevelCard({
    Key? key,
    this.showDetails = true,
  }) : super(key: key);

  @override
  ConsumerState<UserLevelCard> createState() => _UserLevelCardState();
}

class _UserLevelCardState extends ConsumerState<UserLevelCard> {
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final userXP = ref.watch(userXpProvider);
    final level = ref.read(userXpProvider.notifier).currentLevel;
    final progress = ref.read(userXpProvider.notifier).nextLevelProgress;
    final theme = Theme.of(context);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level $level',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total XP: ${userXP.totalXP}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearPercentIndicator(
                  lineHeight: 16.0,
                  percent: progress,
                  center: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  barRadius: const Radius.circular(8),
                  progressColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  animation: true,
                  animationDuration: 1000,
                ),
                
                if (widget.showDetails) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        context,
                        'Current Streak',
                        '${userXP.currentStreak} days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        'Longest Streak',
                        '${userXP.longestStreak} days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                      _buildStatCard(
                        context,
                        'Daily XP',
                        '${userXP.currentDayXP}/${userXP.dailyXPCap}',
                        Icons.stars,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  // Call this method when the user levels up
  void celebrateUserLevelUp() {
    _confettiController.play();
  }
} 