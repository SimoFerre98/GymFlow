import 'package:flutter/material.dart';
import 'package:gymflow/src/models/user_profile.dart';

class FriendDetailScreen extends StatelessWidget {
  final UserProfile friend;

  const FriendDetailScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(friend.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: friend.photoUrl != null
                  ? NetworkImage(friend.photoUrl!)
                  : null,
              child: friend.photoUrl == null
                  ? Text(
                      friend.displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 48),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              friend.displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (friend.gymName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Gym: ${friend.gymName}',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
            const SizedBox(height: 32),
            _buildStatCard(
              context,
              'Streak',
              '${friend.streakDays} Days',
              Icons.local_fire_department,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            // We could show more stats here if we fetch them (e.g. monthly steps)
            // For now, just profile info
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
