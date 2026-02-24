import 'package:flutter/material.dart';
import '../models/streak_models.dart';

class StreakCardWidget extends StatelessWidget {
  const StreakCardWidget({
    super.key,
    required this.streak,
    required this.onTap,
  });

  final FriendStreak streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastSentAt = streak.lastSentAt;
    final hoursRemaining = lastSentAt == null
        ? 24.0
        : (24 - DateTime.now().difference(lastSentAt).inHours).toDouble();
    final clampedRemaining = hoursRemaining.clamp(0, 24).toDouble();
    final isUrgent = clampedRemaining <= 3;
    final progress = clampedRemaining / 24;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4EE), Color(0xFFF2F5FF), Color(0xFFEFF8F2)],
          ),
          boxShadow: [
            BoxShadow(
              color: isUrgent
                  ? const Color(0x55F05252)
                  : const Color(0x16000000),
              blurRadius: isUrgent ? 28 : 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: streak.pendingCount > 0
                      ? const Color(0xFFF2A9AE)
                      : const Color(0xFFD6DCE8),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFE9EDF7),
                child: Text(
                  streak.friendName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak.friendName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${streak.streakCount} Day Streak',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastSentAt == null
                        ? 'No snap sent yet'
                        : 'Last sent ${_timeAgo(lastSentAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFF667085)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFE5EAF3),
                    color: isUrgent
                        ? const Color(0xFFE45656)
                        : const Color(0xFF9AA8F0),
                  ),
                  Center(
                    child: Text(
                      '${clampedRemaining.round()}h',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours >= 24) return '${diff.inDays}d ago';
    if (diff.inMinutes >= 60) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
