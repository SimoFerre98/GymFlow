import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/badge_model.dart';
import 'package:gymflow/src/services/gamification_service.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final userId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),

      body: StreamBuilder<List<WorkoutSession>>(
        stream: firestore.getUserSessions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? [];
          final unlockedBadges = GamificationService.getUnlockedBadges(
            sessions,
          );
          final unlockedIds = unlockedBadges.map((e) => e.id).toSet();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isUnlocked = unlockedIds.contains(badge.id);

              return _buildBadgeCard(context, badge, isUnlocked);
            },
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    BadgeModel badge,
    bool isUnlocked,
  ) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? Colors.amber.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            border: Border.all(
              color: isUnlocked ? Colors.amber : Colors.grey,
              width: 2,
            ),
          ),
          child: Icon(
            badge.icon,
            size: 40,
            color: isUnlocked ? Colors.amber[800] : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isUnlocked ? null : Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          badge.description,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
