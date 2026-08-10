import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';
import '../../core/providers/firestore_provider.dart';
import '../../core/providers/live_metrics_provider.dart';
import '../../models/session.dart';
import '../../core/utils/statistics_helper.dart';
import '../widgets/charts/activity_chart.dart';
import '../widgets/charts/body_measurements_chart.dart';
import '../widgets/app_drawer.dart';
import '../widgets/expressive_card.dart';
import '../../core/theme/expressive_tokens.dart';
import 'package:health/health.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'health_detail_screen.dart';
import '../../models/workout_program.dart';
import '../../models/workout.dart'; // WorkoutTemplate
import 'active_session_screen.dart';
import 'workout_summary_screen.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/exercise_row.dart';
import '../../models/exercise.dart';
import '../../core/providers/exercise_provider.dart';

class DashboardScreen extends riverpod.ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  riverpod.ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends riverpod.ConsumerState<DashboardScreen> {
  Future<Map<String, dynamic>>? _healthDataFuture;

  @override
  void initState() {
    super.initState();
    // _loadProfile();
    _healthDataFuture = _initAndFetchHealth();
  }

  Future<Map<String, dynamic>> _initAndFetchHealth() async {
    if (kIsWeb) return {};
    try {
      final health = ref.read(healthServiceProvider);
      await health.configure();
      return await health.fetchDailySummary();
    } catch (e) {
      debugPrint('Health Load Error: $e');
      rethrow;
    }
  }

  Future<void> _refreshHealthData() async {
    setState(() {
      _healthDataFuture = ref.read(healthServiceProvider).fetchDailySummary();
    });
    try {
      await _healthDataFuture;
    } catch (_) {}
    // Also refresh sessions
    // ref.refresh(dashboardSessionsProvider); // Stream auto-updates, but we could force sync if needed
  }

  int _currentView = 0; // 0 = Dashboard, 1 = History

  @override
  Widget build(BuildContext context) {
    // Legacy provider
    final loc = ref.watch(localizationNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? loc.t('athlete');
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final sessionsAsync = ref.watch(dashboardSessionsProvider);
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: null,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(
                  left: t.spacing.lg,
                  bottom: t.spacing.lg,
                ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      loc.t('welcome_back'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userName,
                      style: t.typography.titleEmphasized?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Styled Quick Start Button
                Padding(
                  padding: EdgeInsets.only(right: t.spacing.md),
                  child: Center(
                    child: InkWell(
                      onTap: () => _showQuickStartMenu(context, userId, loc),
                      borderRadius: t.shape.cornerFull,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: t.spacing.md,
                          vertical: t.spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          // `primary` e non `primaryColor`: quel campo precede
                          // Material 3 e il tema non lo imposta.
                          color: scheme.primary,
                          // I pulsanti d'azione del mockup hanno il raggio pieno.
                          borderRadius: t.shape.cornerFull,
                          boxShadow: t.elevation.level1(scheme.primary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              // Il testo sopra l'ambra: nel tema chiaro non e
                              // bianco, e `onPrimary` lo sa.
                              color: scheme.onPrimary,
                              size: t.spacing.lg,
                            ),
                            SizedBox(width: t.spacing.xs),
                            Text(
                              loc.t('quick_start'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshHealthData,
          child: CustomScrollView(
            slivers: [
              // HERO BLOCK (Nuovo)
              SliverToBoxAdapter(
                child: _buildHomeHeroBlock(context, userId, loc),
              ),

              // TOGGLE (Pill)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: t.spacing.md),
                    child: Container(
                      // La larghezza fissa e una scelta di impaginazione che
                      // precede il design system, non un valore da token: resta
                      // com'e, e la meta dentro dipende da lei.
                      width: 300,
                      height: t.sizing.minTouchTarget,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: t.shape.cornerFull,
                        boxShadow: t.elevation.level1(scheme.shadow),
                      ),
                      child: Stack(
                        children: [
                          // Animated Background Pill
                          AnimatedAlign(
                            alignment: _currentView == 0
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Container(
                              width: 150, // meta della larghezza fissa sopra
                              height: t.sizing.minTouchTarget,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: t.shape.cornerFull,
                              ),
                            ),
                          ),
                          // Text Labels
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _currentView = 0),
                                  behavior: HitTestBehavior.translucent,
                                  child: Center(
                                    child: Text(
                                      loc.t('dashboard_title'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _currentView == 0
                                            ? scheme.onPrimary
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _currentView = 1),
                                  behavior: HitTestBehavior.translucent,
                                  child: Center(
                                    child: Text(
                                      loc.t('history_tab'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _currentView == 1
                                            ? scheme.onPrimary
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // CONTENT
              if (_currentView == 0) ...[
                // DASHBOARD VIEW (Stats + Charts)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(t.spacing.lg),
                    child: sessionsAsync.when(
                      data: (sessions) {
                        final streak = StatisticsHelper.calculateCurrentStreak(
                          sessions,
                        );
                        final volume = StatisticsHelper.calculateTotalVolume(
                          sessions,
                        );
                        // Convert volume to tons/kg string
                        final volumeStr = volume > 1000
                            ? '${(volume / 1000).toStringAsFixed(1)}t'
                            : '${volume}kg';

                        return Column(
                          children: [
                            // Row 1: Workouts & Streak
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    loc.t('workouts_label'),
                                    '${sessions.length}',
                                    Icons.fitness_center,
                                    scheme.secondary,
                                  ),
                                ),
                                SizedBox(width: t.spacing.md),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    loc.t('streak_label'),
                                    '$streak',
                                    Icons.local_fire_department,
                                    scheme.secondary,
                                    suffix: loc.t('days_label'),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: t.spacing.md),
                            // Row 2: Volume & RPE
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    loc.t('volume_label'),
                                    volumeStr,
                                    Icons.layers,
                                    scheme.secondary,
                                  ),
                                ),
                                SizedBox(width: t.spacing.md),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    loc.t('rpe_label'),
                                    StatisticsHelper.calculateAverageRPE(
                                      sessions,
                                    ).toStringAsFixed(1),
                                    Icons.star_half,
                                    // Lo sforzo percepito e un dato vitale, e il
                                    // salmone e il ruolo che la palette riserva
                                    // a quelli. Le altre tre tessere sono
                                    // conteggi: nessuna e un'azione, quindi
                                    // nessuna porta l'ambra.
                                    scheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: t.spacing.md),

                            _buildHealthSection(loc),
                            SizedBox(height: t.spacing.md),
                            RepaintBoundary(
                              child: ExpressiveCard(
                                title: loc.t('workout_activity_chart'),
                                child: SizedBox(
                                  height: 200,
                                  child: ActivityChart(sessions: sessions),
                                ),
                              ),
                            ),
                            SizedBox(height: t.spacing.md),
                            RepaintBoundary(
                              child: ExpressiveCard(
                                title: loc.t('body_progress_chart'),
                                child: BodyMeasurementsChart(userId: userId),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                  ),
                ),
              ] else ...[
                // HISTORY VIEW
                sessionsAsync.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(t.spacing.xxl),
                            child: Text(loc.t('no_workouts_history')),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final session = sessions[index];
                        final isToday =
                            DateTime.now()
                                    .difference(session.startTime)
                                    .inDays ==
                                0 &&
                            session.startTime.day == DateTime.now().day;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: _buildHistoryItem(
                            context,
                            session,
                            isToday,
                            loc,
                          ),
                        );
                      }, childCount: sessions.length),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
              ],

              SliverPadding(
                padding: EdgeInsets.only(bottom: t.spacing.bottomInset),
              ),
            ],
          ),
        ),
      ),
      drawer: const AppDrawer(),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WorkoutSession session,
    bool isToday,
    Localization loc,
  ) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerLg,
        boxShadow: t.elevation.level2(scheme.shadow),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkoutSummaryScreen(session: session),
              ),
            );
          },
          borderRadius: t.shape.cornerLg,
          child: Padding(
            padding: EdgeInsets.all(t.spacing.lg),
            child: Row(
              children: [
                // Date Badge
                Container(
                  width: t.sizing.thumbnailMd,
                  height: t.sizing.thumbnailMd,
                  decoration: BoxDecoration(
                    // Oggi porta l'ambra perche e la giornata su cui stai
                    // agendo; le altre restano una superficie neutra.
                    color: isToday
                        ? scheme.primary.withValues(alpha: 0.1)
                        : scheme.surfaceContainerHighest,
                    borderRadius: t.shape.cornerMd,
                    border: isToday
                        ? Border.all(
                            color: scheme.primary.withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(session.startTime),
                        style: t.typography.metricSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isToday ? scheme.primary : scheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM',
                        ).format(session.startTime).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: t.spacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.workoutName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: t.spacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: t.spacing.md,
                            color: scheme.onSurfaceVariant,
                          ),
                          SizedBox(width: t.spacing.xs),
                          Text(
                            DateFormat('HH:mm').format(session.startTime),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (session.durationSeconds > 0) ...[
                            SizedBox(width: t.spacing.sm),
                            Icon(
                              Icons.timer_outlined,
                              size: t.spacing.md,
                              color: scheme.onSurfaceVariant,
                            ),
                            SizedBox(width: t.spacing.xs),
                            Text(
                              '${session.durationSeconds ~/ 60} min',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(t.spacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: t.spacing.xl, color: color),
          ),
          SizedBox(height: t.spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                // I numeri del mockout sono monospaziati con cifre tabulari,
                // cosi non ballano quando cambiano.
                style: t.typography.metricMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (suffix != null)
                Text(
                  ' $suffix',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHealthSection(Localization loc) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _healthDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        final data = snapshot.data ?? {};
        final steps = data['steps'] ?? 0;
        final calories = data['calories'] ?? 0;
        final t = context.expressive;
        final scheme = Theme.of(context).colorScheme;

        return Row(
          children: [
            Expanded(
              child: ExpressiveCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.STEPS,
                        title: loc.t('steps_label'),
                        baseColor: scheme.secondary,
                        unit: 'steps',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  context,
                  loc.t('steps_label'),
                  '$steps',
                  Icons.directions_walk,
                  scheme.secondary,
                ),
              ),
            ),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: ExpressiveCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.ACTIVE_ENERGY_BURNED,
                        title: loc.t('active_cal_label'),
                        baseColor: scheme.tertiary,
                        unit: 'kcal',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  context,
                  loc.t('active_cal_label'),
                  '${calories.toInt()}',
                  Icons.local_fire_department,
                  // Le calorie sono un dato vitale come il battito: salmone.
                  // Il rosso che c'era qui e il ruolo dell'errore.
                  scheme.tertiary,
                  suffix: ' kcal',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        SizedBox(height: t.spacing.sm),
        Text(
          value + (suffix ?? ''),
          style: t.typography.metricSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeHeroBlock(BuildContext context, String userId, Localization loc) {
    return StreamBuilder<List<WorkoutProgram>>(
      stream: ref.watch(firestoreServiceProvider).getUserPrograms(userId),
      builder: (context, programSnap) {
        final programs = programSnap.data ?? [];
        final activeProgram = programs.where((p) => p.isActive).firstOrNull;

        if (activeProgram == null) {
          return Padding(
            padding: EdgeInsets.only(
              left: context.expressive.spacing.lg,
              right: context.expressive.spacing.lg,
              top: context.expressive.spacing.lg,
            ),
            child: HomeHeroCard(
              hasActiveProgram: false,
              onAction: () {},
              locInProgress: loc.t('home_in_progress'),
              formattedDay: '',
              locResume: loc.t('home_resume_workout'),
              locNoActive: loc.t('home_no_active_program'),
              locCreatePrompt: loc.t('home_create_program_prompt'),
              locCreateAction: loc.t('home_create_program_action'),
              locMin: loc.t('home_min'),
              locExercises: loc.t('home_exercises'),
            ),
          );
        }

        return StreamBuilder<List<WorkoutTemplate>>(
          stream: ref.watch(firestoreServiceProvider).getUserWorkouts(userId),
          builder: (context, workoutSnap) {
            final workouts = workoutSnap.data ?? [];
            final currentWorkoutId = activeProgram.workoutIds.firstOrNull;
            final currentWorkout = workouts.where((w) => w.id == currentWorkoutId).firstOrNull;

            return Padding(
              padding: EdgeInsets.only(
                left: context.expressive.spacing.lg,
                right: context.expressive.spacing.lg,
                top: context.expressive.spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeroCard(
                    hasActiveProgram: true,
                    programName: activeProgram.name,
                    workoutName: currentWorkout?.name ?? '',
                    // ⚠️ Giorno, avanzamento e durata **non si passano**, perche
                    // non sappiamo calcolarli: il «3 / 5», il «72%» e i «45 min»
                    // erano i numeri d'esempio del mockup scritti a mano, cioe un
                    // avanzamento finto mostrato a ogni utente, sempre lo stesso.
                    //
                    // «A che punto sono dentro la scheda» e US-063, che dipende
                    // da US-059: finche non c'e, la card mostra cio che sappiamo
                    // — quale allenamento e di oggi, quanti esercizi, e l'azione
                    // per iniziarlo — e tace sul resto. Un numero inventato e
                    // peggio di un numero assente.
                    totalDays: activeProgram.workoutIds.length,
                    exerciseCount: currentWorkout?.exercises.length ?? 0,
                    onAction: () {
                      if (currentWorkout != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveSessionScreen(
                              workout: currentWorkout,
                            ),
                          ),
                        );
                      }
                    },
                    locInProgress: loc.t('home_in_progress'),
                    // Vuoto, e la card lo omette: il «3» era scritto a mano.
                    formattedDay: '',
                    locResume: loc.t('home_resume_workout'),
                    locNoActive: loc.t('home_no_active_program'),
                    locCreatePrompt: loc.t('home_create_program_prompt'),
                    locCreateAction: loc.t('home_create_program_action'),
                    locMin: loc.t('home_min'),
                    locExercises: loc.t('home_exercises'),
                  ),
                  SizedBox(height: context.expressive.spacing.xl),
                  Text(
                    loc.t('home_today_in_workout'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.expressive.spacing.md),
                  if (currentWorkout != null) ..._buildExercisesList(context, currentWorkout),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildExercisesList(BuildContext context, WorkoutTemplate workout) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final allExercises = exercisesAsync.valueOrNull ?? [];
    
    return workout.exercises.map((we) {
      final ex = allExercises.firstWhere(
        (e) => e.id == we.exerciseId,
        orElse: () => Exercise(
          id: we.exerciseId,
          name: we.exerciseName,
          description: '',
          type: ExerciseType.strength,
          musclesTargeted: [],
        ),
      );

      final metaText = '${we.targetSets} × ${we.targetReps} · ${we.targetWeight} kg';
      final gruppo = ex.musclesTargeted.isNotEmpty
          ? ex.musclesTargeted.first
          : null;

      return Padding(
        padding: EdgeInsets.only(bottom: context.expressive.spacing.sm),
        child: ExerciseRow(
          exercise: ex,
          // `labelSmall` e non `fontSize: 8.5`: quel numero erano i pixel del
          // mockup, che in dp sono 11,6. Il ruolo segue anche la dimensione di
          // testo scelta nelle impostazioni di sistema.
          subtitle: Text(
            metaText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          // Se il gruppo muscolare non c'e, la pillola **non si mostra**. Prima
          // il ripiego era la stringa `'Forza'` scritta a mano: inventava un
          // dato che non abbiamo, e in inglese non sarebbe stata tradotta.
          trailing: gruppo == null ? null : HomeMetaPill(testo: gruppo),
        ),
      );
    }).toList();
  }

  void _showQuickStartMenu(
    BuildContext context,
    String userId,
    Localization loc,
  ) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(t.shape.radiusXl),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(t.spacing.xl),
              child: Text(
                loc.t('start_workout'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<WorkoutProgram>>(
                stream: ref.watch(firestoreServiceProvider).getUserPrograms(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(loc.t('no_programs_found')),
                    );
                  }

                  // Filter for active or show all
                  final programs = snapshot.data!;
                  final activePrograms = programs
                      .where((p) => p.isActive)
                      .toList();
                  final displayPrograms = activePrograms.isNotEmpty
                      ? activePrograms
                      : programs;

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: t.spacing.xl),
                    itemCount: displayPrograms.length,
                    itemBuilder: (context, index) {
                      final program = displayPrograms[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: t.spacing.sm,
                            ),
                            child: Text(
                              program.name.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...program.workoutIds.asMap().entries.map((entry) {
                            return StreamBuilder<List<WorkoutTemplate>>(
                              stream: ref.watch(firestoreServiceProvider).getUserWorkouts(
                                userId,
                              ),
                              builder: (context, wSnapshot) {
                                if (!wSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final templates = wSnapshot.data!
                                    .where(
                                      (w) => program.workoutIds.contains(w.id),
                                    )
                                    .toList();

                                return Column(
                                  children: templates
                                      .map(
                                        (template) => Card(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              template.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${template.exercises.length} ${loc.t('exercises_suffix')}',
                                            ),
                                            trailing: Icon(
                                              Icons.play_circle_fill,
                                              // Avviare l'allenamento e
                                              // l'azione: ambra, non blu.
                                              color: scheme.primary,
                                              size: t.spacing.xxl,
                                            ),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ActiveSessionScreen(
                                                        workout: template,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
