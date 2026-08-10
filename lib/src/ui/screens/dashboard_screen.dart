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

class DashboardScreen extends riverpod.ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  riverpod.ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
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
              // flexibleSpace ospita il layout espanso (che dissolve in uscita).
              // Usiamo LayoutBuilder come suggerito per nascondere il titolo espanso 
              // quando compresso, per evitare sovrapposizioni o scaling errati.
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompressed = constraints.maxHeight <= kToolbarHeight + MediaQuery.paddingOf(context).top + 1.0;
                  
                  return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(
                      left: t.spacing.lg,
                      bottom: t.spacing.lg,
                    ),
                    // Nascondiamo il blocco a due righe quando la barra è compressa.
                    // Material gestirà la comparsa del `title` della SliverAppBar.
                    title: isCompressed 
                        ? const SizedBox.shrink()
                        : Column(
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
