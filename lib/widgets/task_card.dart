import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../config/theme.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback? onTap;
  final bool showActions;
  
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.showActions = true,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Format times
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    String timeString = '';
    if (task.startTime != null) {
      timeString = timeFormat.format(task.startTime!);
      
      if (task.endTime != null) {
        timeString += ' - ${timeFormat.format(task.endTime!)}';
      } else if (task.duration != null) {
        final endTime = task.startTime!.add(task.duration!);
        timeString += ' - ${timeFormat.format(endTime)}';
      }
    }
    
    // Format tracked time if any
    String trackedTimeString = '';
    final trackedDuration = task.calculateTotalTimerDuration();
    if (trackedDuration.inSeconds > 0) {
      final hours = trackedDuration.inHours;
      final minutes = trackedDuration.inMinutes.remainder(60);
      final seconds = trackedDuration.inSeconds.remainder(60);
      
      if (hours > 0) {
        trackedTimeString = '${hours}h ${minutes}m';
      } else if (minutes > 0) {
        trackedTimeString = '${minutes}m ${seconds}s';
      } else {
        trackedTimeString = '${seconds}s';
      }
    }
    
    // Priority color
    final priorityColor = TaskColors.getPriorityColor(task.priority.index);
    
    // Status indicator
    Widget statusIndicator;
    switch (task.status) {
      case TaskStatus.completed:
        statusIndicator = Icon(
          Icons.check_circle,
          color: Colors.green[700],
          size: 20,
        );
        break;
      case TaskStatus.inProgress:
        statusIndicator = Icon(
          Icons.play_circle_fill,
          color: Colors.blue[700],
          size: 20,
        );
        break;
      case TaskStatus.cancelled:
        statusIndicator = Icon(
          Icons.cancel,
          color: Colors.red[700],
          size: 20,
        );
        break;
      default:
        statusIndicator = Icon(
          Icons.circle_outlined,
          color: Colors.grey[600],
          size: 20,
        );
    }
    
    // AI indicator
    final aiIndicator = task.isAiGenerated
        ? const Tooltip(
            message: 'AI Generated',
            child: Icon(
              Icons.auto_awesome,
              color: Colors.amber,
              size: 16,
            ),
          )
        : const SizedBox.shrink();
    
    // XP indicator (if completed and XP earned)
    final xpIndicator = (task.status == TaskStatus.completed && task.xpEarned > 0)
        ? Tooltip(
            message: 'XP Earned: ${task.xpEarned}',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  '${task.xpEarned}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
    
    // Timer indicator
    final timerIndicator = task.timerStartedAt != null
        ? const Tooltip(
            message: 'Timer Running',
            child: Icon(
              Icons.timer,
              color: Colors.green,
              size: 16,
            ),
          )
        : const SizedBox.shrink();
    
    // Base card content
    final cardContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: textTheme.titleMedium?.copyWith(
                      decoration: task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.status == TaskStatus.completed
                          ? Colors.grey
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                aiIndicator,
                const SizedBox(width: 4),
                timerIndicator,
                const SizedBox(width: 4),
                xpIndicator,
                const SizedBox(width: 8),
                statusIndicator,
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  task.category,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (trackedTimeString.isNotEmpty) ...[
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trackedTimeString,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (timeString.isNotEmpty) ...[
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeString,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    
    // Return slidable if actions are enabled
    if (showActions) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Slidable(
          key: ValueKey(task.id),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              if (task.status != TaskStatus.inProgress || task.timerStartedAt == null)
                SlidableAction(
                  onPressed: (_) {
                    ref.read(tasksProvider.notifier).startTaskTimer(task.id);
                  },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.timer,
                  label: 'Start Timer',
                )
              else
                SlidableAction(
                  onPressed: (_) {
                    ref.read(tasksProvider.notifier).stopTaskTimer(task.id);
                  },
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  icon: Icons.timer_off,
                  label: 'Stop Timer',
                ),
              SlidableAction(
                onPressed: (_) {
                  ref.read(tasksProvider.notifier).completeTask(task.id);
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: Icons.check,
                label: 'Complete',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  ref.read(tasksProvider.notifier).deleteTask(task.id);
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            child: cardContent,
          ),
        ),
      );
    }
    
    // Return simple card if no actions
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        child: cardContent,
      ),
    );
  }
} 