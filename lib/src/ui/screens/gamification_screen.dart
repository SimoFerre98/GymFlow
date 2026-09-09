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
import '../../core/theme/immersivo_tokens.dart';
import '../../core/utils/statistics_helper.dart';
import '../widgets/timer_aurora.dart';
/// Lato del cerchio e dell'icona dentro una card di traguardo.
const double _kDiametroIconaBadge = 50;
const double _kLatoIconaBadge = 28;
/// 52px del mockup 2c: il numero della streak prende lo stesso posto che il
/// mockup dava a "2 400 punti" — non esiste un sistema a punti/livelli, e
/// mostrarne uno sarebbe un dato inventato, ma la resa (badge sopra, numero
/// enorme sotto) e la stessa.
const double _kStreakHeroFontSize = 52;
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
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      // Il bagliore ambientale del mockup 2c: le stesse masse della
      // schermata del tempo, dietro al contenuto invece che sotto un tema
      // spento.
      body: Stack(
        children: [
          const Positioned.fill(child: TimerAurora()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Raggiunta da un riquadro della Home (Parte 3), non da uno
                // spingimento sentito come tale: stesso trattamento senza
                // BackPill delle altre destinazioni raggiunte cosi.
                Padding(
                  padding: EdgeInsets.fromLTRB(t.spacing.lg, t.spacing.sm, t.spacing.lg, 0),
                  child: _buildHeader(context, loc, t, scheme),
                ),
                Expanded(child: _buildBody(context, loc, userId, firestore, t)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        Text(
          loc.t('achievements_title').toUpperCase(),
          style: t.typography.title?.copyWith(color: scheme.onSurface),
        ),
        SizedBox(width: t.spacing.md),
        Expanded(
          child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
  /// Il rimpiazzo reale di "LIVELLO 7 · 2 400 PUNTI" del mockup 2c: qui non
  /// esiste un sistema a punti/livelli, e mostrarne uno sarebbe un dato
  /// inventato. La streak e reale (stesso calcolo di [DashboardScreen] sugli
  /// stessi allenamenti), e prende la stessa resa — badge sopra, numero
  /// enorme sotto.
  Widget _buildStreakHero(BuildContext context, Localization loc, ImmersivoTokens t, int streak) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.lg, t.spacing.lg, t.spacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (streak > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: t.spacing.sm, vertical: t.spacing.xs),
              color: scheme.primary,
              child: Text(
                loc.t('gamification_streak_badge').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.onPrimary),
              ),
            ),
          SizedBox(height: t.spacing.sm),
          Text(
            '$streak\n${loc.t('days_label').toUpperCase()}',
            style: t.typography.display?.copyWith(
              fontSize: _kStreakHeroFontSize,
              height: 0.9,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBody(
    BuildContext context,
    Localization loc,
    String userId,
    dynamic firestore,
    ImmersivoTokens t,
  ) {
    return StreamBuilder<UserProfile?>(
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
              final streak = StatisticsHelper.calculateCurrentStreak(sessions);
              final unlockedBadges = GamificationService.getUnlockedBadges(
                sessions,
                friendCount: friendCount,
              );
              final unlockedIds = unlockedBadges.map((e) => e.id).toSet();
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakHero(context, loc, t, streak),
                    Padding(
                      padding: EdgeInsets.all(t.spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Le tre sfide del mese, nel linguaggio del mockup
                          // 2c: riga con numero, titolo, valore e un filetto
                          // sottile invece di tre card scollegate (una
                          // lineare, una ad anello).
                          _buildSectionHeader(
                            context,
                            loc.t('monthly_challenges'),
                            trailing: '3',
                          ),
                          SizedBox(height: t.spacing.sm),
                          _buildChallengeRow(
                            context,
                            loc,
                            numero: '01',
                            icona: Icons.directions_walk,
                            titolo: loc.t('step_master'),
                            valore: '$_monthlySteps / $_monthlyStepGoal',
                            frazione: (_monthlySteps / _monthlyStepGoal).clamp(0.0, 1.0),
                            colore: Theme.of(context).colorScheme.primary,
                          ),
                          _buildChallengeRow(
                            context,
                            loc,
                            numero: '02',
                            icona: Icons.local_fire_department,
                            titolo: loc.t('calorie_burn'),
                            valore:
                                '${_monthlyCalories.toInt()} / $_monthlyCalorieGoal kcal',
                            frazione:
                                (_monthlyCalories / _monthlyCalorieGoal).clamp(0.0, 1.0),
                            colore: Theme.of(context).colorScheme.tertiary,
                          ),
                          _buildChallengeRow(
                            context,
                            loc,
                            numero: '03',
                            icona: Icons.map_outlined,
                            titolo: loc.t('distance_label'),
                            valore:
                                '${(_monthlyDistance / 1000).toStringAsFixed(1)} / '
                                '${_monthlyDistanceGoal ~/ 1000} km',
                            frazione:
                                (_monthlyDistance / _monthlyDistanceGoal).clamp(0.0, 1.0),
                            colore: Theme.of(context).colorScheme.secondary,
                          ),
                          SizedBox(height: t.spacing.xl),
                          // Achievements Section
                          _buildSectionHeader(
                            context,
                            loc.t('badges_section'),
                            trailing: '${unlockedIds.length} / ${allBadges.length}',
                          ),
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
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
  }
  Widget _buildSectionHeader(BuildContext context, String title, {String? trailing}) {
    final scheme = Theme.of(context).colorScheme;
    if (trailing == null) {
      return Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          trailing,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
  /// Una sfida del mese nel linguaggio del mockup 2c: numero, icona, titolo,
  /// valore a destra, barra sottile — la stessa riga per tutte e tre, invece
  /// di una card lineare e due ad anello scollegate fra loro.
  Widget _buildChallengeRow(
    BuildContext context,
    Localization loc, {
    required String numero,
    required IconData icona,
    required String titolo,
    required String valore,
    required double frazione,
    required Color colore,
  }) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.md),
        child: Row(
          children: [
            Text(numero, style: t.typography.eyebrow?.copyWith(color: colore)),
            SizedBox(width: t.spacing.sm),
            Icon(icona, color: colore, size: t.sizing.iconSm),
            SizedBox(width: t.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titolo,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        valore,
                        style: t.typography.eyebrow?.copyWith(color: colore),
                      ),
                    ],
                  ),
                  SizedBox(height: t.spacing.xs),
                  SizedBox(
                    height: 5,
                    // `ColoredBox` qui non disegnava nulla — stesso difetto
                    // isolato e corretto in `statistics_screen.dart` durante
                    // la story Immersivo (2026-08-21): `Container` funziona.
                    child: Stack(
                      children: [
                        Container(
                          color: scheme.onSurface.withValues(alpha: 0.12),
                        ),
                        FractionallySizedBox(
                          widthFactor: _isLoading ? 0 : frazione,
                          child: Container(color: colore),
                        ),
                      ],
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
  Widget _buildBadgeCard(
    BuildContext context,
    BadgeModel badge,
    bool isUnlocked,
    Localization loc,
  ) {
    final t = context.immersivo;
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
              borderRadius: t.shape.cornerXs,
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
