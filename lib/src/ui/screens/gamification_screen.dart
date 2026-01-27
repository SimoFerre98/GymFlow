import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/models/badge_model.dart';
import 'package:gymflow/src/services/gamification_service.dart';

import 'package:gymflow/src/services/health_service.dart';
import 'package:health/health.dart';
import '../../core/providers/localization_provider.dart';
import '../widgets/app_drawer.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  int _monthlySteps = 0;
  double _monthlyCalories = 0;
  double _monthlyDistance = 0;
  bool _isLoading = true;

  final int _monthlyStepGoal = 180000;
  final int _monthlyCalorieGoal = 15000; // 500 kcal * 30 days
  final int _monthlyDistanceGoal = 50000; // 50km in meters

  @override
  void initState() {
    super.initState();
    _fetchMonthlyChallenges();
  }

  Future<void> _fetchMonthlyChallenges() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final healthService = HealthService();

    try {
      // 1. Steps
      final stepsData = await healthService.fetchHistoricalData(
        HealthDataType.STEPS,
        startOfMonth,
        now,
      );
      int stepsTotal = 0;
      stepsData.forEach((_, value) => stepsTotal += value.toInt());

      // 2. Calories
      final caloriesData = await healthService.fetchHistoricalData(
        HealthDataType.ACTIVE_ENERGY_BURNED,
        startOfMonth,
        now,
      );
      double caloriesTotal = 0;
      caloriesData.forEach((_, value) => caloriesTotal += value);

      // 3. Distance
      final distanceData = await healthService.fetchHistoricalData(
        HealthDataType.DISTANCE_DELTA,
        startOfMonth,
        now,
      );
      double distanceTotal = 0;
      distanceData.forEach((_, value) => distanceTotal += value);

      if (mounted) {
        setState(() {
          _monthlySteps = stepsTotal;
          _monthlyCalories = caloriesTotal;
          _monthlyDistance = distanceTotal;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching monthly challenges: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final loc = Provider.of<LocalizationProvider>(context);
    final userId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(loc.t('achievements_title')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().getUserProfileStream(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            // Avoid showing loading if just waiting for user profile, but good to have
            // If we just return indicator here, the whole page loads.
            // Let's assume user is loaded quickly.
          }
          final userProfile = userSnapshot.data;
          final friendCount = userProfile?.friends.length ?? 0;

          return StreamBuilder<List<WorkoutSession>>(
            stream: firestore.getUserSessions(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final sessions = snapshot.data ?? [];
              final unlockedBadges = GamificationService.getUnlockedBadges(
                sessions,
                friendCount: friendCount,
              );
              final unlockedIds = unlockedBadges.map((e) => e.id).toSet();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Challenge Section
                    _buildSectionHeader(loc.t('monthly_challenges')),
                    const SizedBox(height: 12),

                    // 1. Steps (Linear)
                    _buildStepChallengeCard(loc),
                    const SizedBox(height: 16),

                    // 2. Calories & Distance (Row)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCaloriesChallengeCard(loc)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDistanceChallengeCard(loc)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Achievements Section
                    _buildSectionHeader(loc.t('badges_section')),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: allBadges.length,
                      itemBuilder: (context, index) {
                        final badge = allBadges[index];
                        final isUnlocked = unlockedIds.contains(badge.id);
                        return _buildBadgeCard(context, badge, isUnlocked, loc);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildStepChallengeCard(LocalizationProvider loc) {
    final progress = (_monthlySteps / _monthlyStepGoal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_walk, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('step_master'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    loc.t('reach_steps_goal'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_monthlySteps / $_monthlyStepGoal',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _isLoading ? null : progress,
              minHeight: 8,
              backgroundColor: Colors.black.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesChallengeCard(LocalizationProvider loc) {
    final progress = (_monthlyCalories / _monthlyCalorieGoal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            loc.t('calorie_burn'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${loc.t('goal_label')} ${_monthlyCalorieGoal ~/ 1000}k kcal',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 4)
                    : CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orangeAccent,
                        ),
                      ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 20,
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_monthlyCalories.toInt()} kcal',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceChallengeCard(LocalizationProvider loc) {
    final progress = (_monthlyDistance / _monthlyDistanceGoal).clamp(0.0, 1.0);
    // Convert to km
    final currentKm = (_monthlyDistance / 1000).toStringAsFixed(1);
    final goalKm = _monthlyDistanceGoal ~/ 1000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.t('distance_label'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${loc.t('goal_label')} ${goalKm}km',
            style: TextStyle(color: Colors.teal[700], fontSize: 10),
          ),
          const SizedBox(height: 20),
          Text(
            '$currentKm km',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _isLoading ? null : progress,
              minHeight: 6,
              backgroundColor: Colors.teal.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: Colors.teal[800],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    BadgeModel badge,
    bool isUnlocked,
    LocalizationProvider loc,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: isUnlocked
            ? Border.all(color: Colors.amber.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: Icon(
              badge.icon,
              size: 28,
              color: isUnlocked ? Colors.amber[800] : Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              loc.t('badge_name_${badge.id}'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              loc.t('badge_desc_${badge.id}'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
