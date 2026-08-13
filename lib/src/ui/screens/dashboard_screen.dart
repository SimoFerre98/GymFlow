import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../../core/providers/firestore_provider.dart';
import '../widgets/app_drawer.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/workout_program.dart';
import '../../models/workout.dart'; // WorkoutTemplate
import 'active_session_screen.dart';
import 'statistics_screen.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/exercise_row.dart';
import '../../models/exercise.dart';
import '../../core/providers/exercise_provider.dart';
import '../../core/providers/active_session_provider.dart';
import '../../models/session.dart';

class DashboardScreen extends riverpod.ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  riverpod.ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

/// Ritaglia lo spazio flessibile alla porzione **sotto** le icone della barra.
///
/// Serve perche il titolo di `FlexibleSpaceBar` sale insieme al fondo della
/// barra mentre si scorre, e a un certo punto si trova nella fascia dove stanno
/// il cassetto e le azioni. Ritagliare li significa che quel pezzo non viene
/// disegnato affatto, invece di finire sopra un'icona.
class _SottoLeIcone extends CustomClipper<Rect> {
  const _SottoLeIcone(this.fascia);

  /// L'altezza della barra quando e tutta compressa: sopra questa linea
  /// stanno le icone.
  final double fascia;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, fascia.clamp(0, size.height), size.width, size.height);

  @override
  bool shouldReclip(_SottoLeIcone oldClipper) => oldClipper.fascia != fascia;
}

class _DashboardScreenState extends riverpod.ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Legacy provider
    final loc = ref.watch(localizationNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? loc.t('athlete');
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              // Il titolo della SliverAppBar viene mostrato automaticamente da 
              // Material quando la barra è compressa, ed è già impaginato
              // correttamente fra il cassetto e le azioni.
              title: Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Utilizziamo lo stesso stile previsto per il nome, adattato
                style: t.typography.titleEmphasized?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              // Lo spazio flessibile viene **ritagliato** sotto la fascia che
              // occupano le icone.
              //
              // `FlexibleSpaceBar` tiene il proprio titolo a distanza fissa dal
              // **fondo** della barra: mentre la barra si accorcia il titolo sale
              // con lei e passa sopra il cassetto e le azioni. Misurato su
              // `main`: bastano **24 px** di scorrimento sugli 88 di corsa perche
              // il saluto arrivi a `top = 34` e copra l'hamburger, e a 32 px e
              // gia incastrato a `top = 1`.
              //
              // Per questo non basta nasconderlo a barra compressa — la
              // sovrapposizione accade molto prima — e non basta dissolverlo,
              // perche sparirebbe al primo tocco di scorrimento. Il ritaglio
              // invece non sposta niente: a riposo il blocco resta esattamente
              // dov'e sempre stato, con l'ingrandimento che `FlexibleSpaceBar`
              // gli applica, e mentre si scorre viene mangiato dall'alto invece
              // di essere disegnato sopra le icone.
              flexibleSpace: Builder(
                builder: (context) {
                  final impostazioni = context
                      .dependOnInheritedWidgetOfExactType<
                        FlexibleSpaceBarSettings
                      >();
                  // L'altezza della barra da compressa, presa da chi la calcola
                  // invece che riscritta a mano: `kToolbarHeight` sarebbe
                  // sbagliata di otto dp, perche la variante `large` si comprime
                  // a 64 e non ai 56 della toolbar.
                  final fasciaCompressa =
                      impostazioni?.minExtent ??
                      kToolbarHeight + MediaQuery.paddingOf(context).top;

                  return ClipRect(
                    clipper: _SottoLeIcone(fasciaCompressa),
                    child: FlexibleSpaceBar(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.typography.titleEmphasized?.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                    ),
                  );
                },
              ),
              actions: [
                // Navigazione verso Statistiche (richiesta da US-095)
                IconButton(
                  icon: Icon(Icons.bar_chart, color: scheme.onSurfaceVariant),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                    );
                  },
                ),
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
        body: CustomScrollView(
          slivers: [
            // HERO BLOCK (Nuovo)
            SliverToBoxAdapter(
              child: _buildHomeHeroBlock(context, userId, loc),
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: t.spacing.bottomInset),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
    );
  }



  Widget _buildHomeHeroBlock(BuildContext context, String userId, Localization loc) {
    final activeSession = ref.watch(activeSessionNotifierProvider);
    final firestore = ref.watch(firestoreServiceProvider);

    return StreamBuilder<List<WorkoutProgram>>(
      stream: firestore.getUserPrograms(userId),
      builder: (context, programSnap) {
        final programs = programSnap.data ?? [];
        final activeProgram = programs.where((p) => p.isActive).firstOrNull;

        return StreamBuilder<List<WorkoutSession>>(
          stream: firestore.getUserSessions(userId),
          builder: (context, sessionSnap) {
            final sessions = sessionSnap.data ?? [];

            return StreamBuilder<List<WorkoutTemplate>>(
              stream: firestore.getUserWorkouts(userId),
              builder: (context, workoutSnap) {
                final workouts = workoutSnap.data ?? [];

                WorkoutTemplate? targetWorkout;
                int currentDay = 1;
                int totalDays = 1;

                if (activeSession.isActive) {
                  targetWorkout = activeSession.workout;
                } else if (activeProgram != null && activeProgram.workoutIds.isNotEmpty) {
                  totalDays = activeProgram.workoutIds.length;
                  final programSet = activeProgram.workoutIds.toSet();
                  final lastSession = sessions
                      .where((s) => programSet.contains(s.workoutTemplateId))
                      .firstOrNull;

                  int nextIndex = 0;
                  if (lastSession != null) {
                    final lastIdx = activeProgram.workoutIds.indexOf(lastSession.workoutTemplateId);
                    if (lastIdx != -1) {
                      nextIndex = (lastIdx + 1) % activeProgram.workoutIds.length;
                    }
                  }
                  currentDay = nextIndex + 1;
                  final targetId = activeProgram.workoutIds[nextIndex];
                  targetWorkout = workouts.where((w) => w.id == targetId).firstOrNull ?? workouts.firstOrNull;
                } else {
                  targetWorkout = workouts.firstOrNull;
                }

                if (targetWorkout == null && !activeSession.isActive) {
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
                      locExerciseOne: loc.t('home_exercise_one'),
                    ),
                  );
                }

                final formattedDayStr = activeProgram != null
                    ? loc
                        .t('home_day_of')
                        .replaceFirst('%s', '$currentDay')
                        .replaceFirst('%s', '$totalDays')
                    : '';

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
                        programName: activeProgram?.name ?? targetWorkout?.name ?? loc.t('workout_label'),
                        workoutName: targetWorkout?.name ?? '',
                        currentDay: currentDay,
                        totalDays: totalDays,
                        exerciseCount: activeSession.isActive
                            ? activeSession.sessionExercises.length
                            : (targetWorkout?.exercises.length ?? 0),
                        onAction: () {
                          if (targetWorkout != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActiveSessionScreen(
                                  workout: targetWorkout!,
                                  scheduledWorkoutId: activeSession.scheduledWorkoutId,
                                ),
                              ),
                            );
                          }
                        },
                        locInProgress: activeSession.isActive
                            ? loc.t('home_in_progress')
                            : loc.t('home_active_program_tag'),
                        formattedDay: formattedDayStr,
                        locResume: activeSession.isActive
                            ? loc.t('home_resume_workout')
                            : loc.t('start_workout'),
                        locNoActive: loc.t('home_no_active_program'),
                        locCreatePrompt: loc.t('home_create_program_prompt'),
                        locCreateAction: loc.t('home_create_program_action'),
                        locMin: loc.t('home_min'),
                        locExercises: loc.t('home_exercises'),
                        locExerciseOne: loc.t('home_exercise_one'),
                      ),
                      SizedBox(height: context.expressive.spacing.xl),
                      Text(
                        loc.t('home_today_in_workout'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.expressive.spacing.md),
                      if (targetWorkout != null) ..._buildExercisesList(context, targetWorkout),
                    ],
                  ),
                );
              },
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

      // Il carico compare **solo se c'e**. Prima l'interpolazione lo mostrava
      // com'era, e sulla home si leggeva «3 × 10 · null kg»: un `null` sotto gli
      // occhi dell'utente, che e la versione peggiore del dato inventato —
      // non finge nemmeno di essere un numero.
      final carico = we.targetWeight;
      final metaText = carico == null
          ? '${we.targetSets} × ${we.targetReps}'
          : '${we.targetSets} × ${we.targetReps} · $carico kg';
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
