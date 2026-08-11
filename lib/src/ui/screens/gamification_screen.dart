import 'package:flutter/material.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/models/badge_model.dart';
import 'package:gymflow/src/services/gamification_service.dart';

import 'package:gymflow/src/services/health_service.dart';
import 'package:health/health.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/expressive_tokens.dart';
import '../widgets/app_drawer.dart';

/// Lato del cerchio di avanzamento delle calorie: geometria di questa
/// card, non una misura condivisa.
const double _kDiametroAnelloCalorie = 80;

/// Lato del cerchio e dell'icona dentro una card di traguardo.
const double _kDiametroIconaBadge = 50;
const double _kLatoIconaBadge = 28;

class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({super.key});

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen> {
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
      debugPrint('Error fetching monthly challenges: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.read(firestoreServiceProvider);
    final loc = ref.watch(localizationNotifierProvider);
    final userId = AuthService().currentUser?.uid ?? '';
    final t = context.expressive;

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
                padding: EdgeInsets.all(t.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Challenge Section
                    _buildSectionHeader(context, loc.t('monthly_challenges')),
                    SizedBox(height: t.spacing.sm),

                    // 1. Steps (Linear)
                    _buildStepChallengeCard(loc),
                    SizedBox(height: t.spacing.md),

                    // 2. Calories & Distance (Row)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildCaloriesChallengeCard(loc)),
                          SizedBox(width: t.spacing.sm),
                          Expanded(child: _buildDistanceChallengeCard(loc)),
                        ],
                      ),
                    ),
                    SizedBox(height: t.spacing.xxl),

                    // Achievements Section
                    _buildSectionHeader(context, loc.t('badges_section')),
                    SizedBox(height: t.spacing.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: t.spacing.sm,
                        mainAxisSpacing: t.spacing.sm,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildStepChallengeCard(Localization loc) {
    final t = context.expressive;
    final progress = (_monthlySteps / _monthlyStepGoal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();
    // Il testo sopra questa card e sempre indigo900, non bianco: e la tinta
    // che vince il contrasto contro categoryBlue, verificato con la stessa
    // formula WCAG usata per le fette della torta dei tipi di allenamento.
    const inchiostro = AppPalette.indigo900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(t.spacing.lg),
      decoration: BoxDecoration(
        color: AppPalette.categoryBlue,
        borderRadius: t.shape.cornerLg,
        boxShadow: t.elevation.level2(AppPalette.categoryBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(t.spacing.sm),
                decoration: BoxDecoration(
                  color: inchiostro.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_walk, color: inchiostro),
              ),
              SizedBox(width: t.spacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('step_master'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: inchiostro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    loc.t('reach_steps_goal'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: inchiostro.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: t.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_monthlySteps / $_monthlyStepGoal',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: inchiostro,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: inchiostro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: t.spacing.sm),
          ClipRRect(
            borderRadius: t.shape.cornerSm,
            child: LinearProgressIndicator(
              value: _isLoading ? null : progress,
              minHeight: t.spacing.sm,
              backgroundColor: inchiostro.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(inchiostro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesChallengeCard(Localization loc) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final progress = (_monthlyCalories / _monthlyCalorieGoal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerLg,
        boxShadow: t.elevation.level2(AppPalette.categoryOrange),
        border: Border.all(color: AppPalette.categoryOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            loc.t('calorie_burn'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            '${loc.t('goal_label')} ${_monthlyCalorieGoal ~/ 1000}k kcal',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: t.spacing.md),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: _kDiametroAnelloCalorie,
                width: _kDiametroAnelloCalorie,
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 4)
                    : CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: AppPalette.categoryOrange.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppPalette.categoryOrange,
                        ),
                      ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppPalette.categoryOrange,
                    size: t.sizing.iconMd,
                  ),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: t.spacing.sm),
          Text(
            '${_monthlyCalories.toInt()} kcal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceChallengeCard(Localization loc) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final progress = (_monthlyDistance / _monthlyDistanceGoal).clamp(0.0, 1.0);
    // Convert to km
    final currentKm = (_monthlyDistance / 1000).toStringAsFixed(1);
    final goalKm = _monthlyDistanceGoal ~/ 1000;

    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: AppPalette.categoryAqua.withValues(alpha: 0.1),
        borderRadius: t.shape.cornerLg,
        border: Border.all(color: AppPalette.categoryAqua.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: AppPalette.categoryAqua,
                size: t.sizing.iconMd,
              ),
              SizedBox(width: t.spacing.sm),
              Expanded(
                child: Text(
                  loc.t('distance_label'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: t.spacing.xs),
          Text(
            '${loc.t('goal_label')} ${goalKm}km',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: t.spacing.lg),
          Text(
            '$currentKm km',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: t.spacing.sm),
          ClipRRect(
            borderRadius: t.shape.cornerXs,
            child: LinearProgressIndicator(
              value: _isLoading ? null : progress,
              minHeight: 6,
              backgroundColor: AppPalette.categoryAqua.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppPalette.categoryAqua,
              ),
            ),
          ),
          SizedBox(height: t.spacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
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
    Localization loc,
  ) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerMd,
        boxShadow: t.elevation.level1(scheme.shadow),
        border: isUnlocked
            ? Border.all(color: AppPalette.success.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _kDiametroIconaBadge,
            height: _kDiametroIconaBadge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? AppPalette.success.withValues(alpha: 0.15)
                  : scheme.onSurface.withValues(alpha: 0.08),
            ),
            child: Icon(
              badge.icon,
              size: _kLatoIconaBadge,
              color: isUnlocked
                  ? AppPalette.success
                  : scheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          SizedBox(height: t.spacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.xs),
            child: Text(
              loc.t('badge_name_${badge.id}'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          SizedBox(height: t.spacing.xs),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.xs),
            child: Text(
              loc.t('badge_desc_${badge.id}'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
