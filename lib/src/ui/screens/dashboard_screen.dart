import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../../core/providers/firestore_provider.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/statistics_helper.dart';
import '../../models/workout_program.dart';
import '../../models/workout.dart'; // WorkoutTemplate
import 'active_session_screen.dart';
import '../widgets/ticker_marquee.dart';
import '../widgets/exercise_image.dart';
import '../../models/exercise.dart';
import '../../core/providers/exercise_provider.dart';
import '../../core/providers/active_session_provider.dart';
import '../../core/providers/goals_provider.dart';
import '../../models/session.dart';
import '../../models/user_goal.dart';
import 'connect_friend_screen.dart';
import 'gamification_screen.dart';
import 'goals_screen.dart';
import 'program_creator_screen.dart';
import 'program_list_screen.dart';
import 'statistics_screen.dart';
import 'time_tools_screen.dart';
/// Misure del mockup 1d Home. Il telaio del mockup e gia largo 384px quanto
/// il telefono (`DESIGN-SPEC.md`): non c'e conversione da fare, ma restano
/// misure di **questa** schermata e non voci della scala di spaziatura —
/// metterle fra i token la renderebbe disponibile a chiunque, che e il modo
/// in cui una misura di un disegno finisce per caso in un altro (vedi la
/// stessa nota in `time_dial.dart`).
const double _kLogoFontSize = 17;
const double _kTitleFontSize = 54;
const double _kCtaFontSize = 22;
const double _kCtaIconSide = 46;
const double _kMuscleDotSide = 5;
const double _kGoalTrackWidth = 56;
const double _kGoalTrackHeight = 5;
const double _kShortcutTileWidth = 84;
const double _kShortcutTileHeight = 92;
/// La Home del mockup Immersivo (`1d Home`): foto a piena larghezza che sfuma
/// nel fondo, titolo in Anton, striscia scorrevole, due righe numerate.
///
/// Non e piu una `SliverAppBar` con il saluto personale: quella era
/// l'intestazione della direzione precedente (Material 3 Expressive). Il
/// mockup non ha un saluto, ha il logo GYMFLOW — e la struttura, non solo il
/// colore, e cio che questa schermata deve replicare (vedi
/// `docs/design/README.md`, "rispettare il mock vuol dire rifare la
/// struttura").
class DashboardScreen extends riverpod.ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  riverpod.ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}
class _DashboardScreenState extends riverpod.ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final userId = ref.watch(currentUserIdProvider) ?? '';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _HomeBody(userId: userId, loc: loc),
      ),
    );
  }
}
class _HomeBody extends riverpod.ConsumerWidget {
  const _HomeBody({required this.userId, required this.loc});
  final String userId;
  final Localization loc;
  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
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
                final activeSession = ref.watch(activeSessionNotifierProvider);
                return _buildContent(
                  context,
                  ref,
                  activeProgram: activeProgram,
                  sessions: sessions,
                  workouts: workouts,
                  activeSession: activeSession,
                );
              },
            );
          },
        );
      },
    );
  }
  Widget _buildContent(
    BuildContext context,
    riverpod.WidgetRef ref, {
    required WorkoutProgram? activeProgram,
    required List<WorkoutSession> sessions,
    required List<WorkoutTemplate> workouts,
    required ActiveSessionState activeSession,
  }) {
    final t = context.immersivo;
    WorkoutTemplate? targetWorkout;
    WorkoutTemplate? nextWorkout;
    if (activeSession.isActive) {
      targetWorkout = activeSession.workout;
    } else if (activeProgram != null && activeProgram.workoutIds.isNotEmpty) {
      final programSet = activeProgram.workoutIds.toSet();
      final lastSession = sessions
          .where((s) => programSet.contains(s.workoutTemplateId))
          .firstOrNull;
      var targetIndex = 0;
      if (lastSession != null) {
        final lastIdx = activeProgram.workoutIds.indexOf(
          lastSession.workoutTemplateId,
        );
        if (lastIdx != -1) {
          targetIndex = (lastIdx + 1) % activeProgram.workoutIds.length;
        }
      }
      final targetId = activeProgram.workoutIds[targetIndex];
      targetWorkout =
          workouts.where((w) => w.id == targetId).firstOrNull ??
          workouts.firstOrNull;
      // "Prossima" del mockup: la scheda dopo quella di oggi nello stesso
      // ciclo — non inventata, e il passo successivo dello stesso calcolo.
      if (activeProgram.workoutIds.length > 1) {
        final nextIndex = (targetIndex + 1) % activeProgram.workoutIds.length;
        final nextId = activeProgram.workoutIds[nextIndex];
        nextWorkout = workouts.where((w) => w.id == nextId).firstOrNull;
      }
    } else {
      targetWorkout = workouts.firstOrNull;
    }
    if (targetWorkout == null) {
      return _EmptyHome(loc: loc);
    }
    final streak = StatisticsHelper.calculateCurrentStreak(sessions);
    final goals = ref.watch(userGoalsNotifierProvider);
    final bestGoal = goals
        .where((g) => !g.isAchieved)
        .sortedByProgressDesc()
        .firstOrNull;
    return Column(
      children: [
        Expanded(
          flex: 11,
          child: _HeroSection(
            workout: targetWorkout,
            streak: streak,
            isResuming: activeSession.isActive,
            loc: loc,
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveSessionScreen(
                    workout: targetWorkout!,
                    scheduledWorkoutId: activeSession.scheduledWorkoutId,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            t.spacing.lg,
            t.spacing.md,
            t.spacing.lg,
            0,
          ),
          child: TickerMarquee(text: _tickerText(sessions, goals)),
        ),
        Expanded(
          flex: 9,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.lg),
            children: [
              SizedBox(height: t.spacing.sm),
              if (nextWorkout != null)
                _NumberedRow(
                  number: '01',
                  title: '${loc.t('home_next_workout_label')} · ${nextWorkout.name}',
                  subtitle: '${nextWorkout.exercises.length} ${loc.t(nextWorkout.exercises.length == 1 ? 'home_exercise_one' : 'home_exercises')}',
                  trailing: Icon(
                    Icons.arrow_forward,
                    size: t.sizing.iconSm,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (bestGoal != null)
                _NumberedRow(
                  number: nextWorkout != null ? '02' : '01',
                  title: bestGoal.title,
                  subtitle:
                      '${(bestGoal.progressFraction * 100).round()}%'
                      '${bestGoal.deadline == null ? '' : ' · ${_daysLeftLabel(bestGoal.deadline!, loc)}'}',
                  trailing: SizedBox(
                    width: _kGoalTrackWidth,
                    height: _kGoalTrackHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: bestGoal.progressFraction,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
                  ),
                ),
              SizedBox(height: t.spacing.lg),
              _ShortcutRow(loc: loc),
              SizedBox(height: t.spacing.lg),
            ],
          ),
        ),
      ],
    );
  }
  String _daysLeftLabel(DateTime deadline, Localization loc) {
    final days = deadline.difference(DateTime.now()).inDays;
    return days <= 0
        ? loc.t('goals_achieved')
        : '$days ${loc.t('days_label').toLowerCase()}';
  }
  /// Solo dati che questa schermata gia interroga: volume e record personale
  /// del mockup non sono disponibili qui senza una nuova interrogazione, e
  /// una striscia che li mostrasse sarebbe un valore inventato.
  String _tickerText(List<WorkoutSession> sessions, List<UserGoal> goals) {
    final pezzi = <String>[
      loc.t('home_ticker_sessions').replaceFirst('%s', '${sessions.length}'),
      if (goals.isNotEmpty)
        loc
            .t('home_ticker_goals')
            .replaceFirst('%s', '${goals.where((g) => g.isAchieved).length}')
            .replaceFirst('%s', '${goals.length}'),
    ];
    return pezzi.join('   /   ').toUpperCase();
  }
}
extension _GoalSorting on Iterable<UserGoal> {
  List<UserGoal> sortedByProgressDesc() {
    final copy = toList();
    copy.sort((a, b) => b.progressFraction.compareTo(a.progressFraction));
    return copy;
  }
}
/// La foto a tutta larghezza che sfuma nel fondo, col titolo sopra —
/// `image-slot` del mockup: qui e la foto dell'esercizio, che gia mostra
/// sempre qualcosa (mai un vuoto) tramite la stessa catena di ripiego usata
/// in tutta l'app.
class _HeroSection extends riverpod.ConsumerWidget {
  const _HeroSection({
    required this.workout,
    required this.streak,
    required this.isResuming,
    required this.loc,
    required this.onAction,
  });
  final WorkoutTemplate workout;
  final int streak;
  final bool isResuming;
  final Localization loc;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final exercisesAsync = ref.watch(exercisesProvider);
    final allExercises = exercisesAsync.valueOrNull ?? [];
    Exercise? heroExercise;
    if (workout.exercises.isNotEmpty) {
      final firstId = workout.exercises.first.exerciseId;
      heroExercise = allExercises.where((e) => e.id == firstId).firstOrNull;
    }
    final muscleGroups = <String>{};
    for (final we in workout.exercises) {
      final ex = allExercises.where((e) => e.id == we.exerciseId).firstOrNull;
      if (ex != null && ex.musclesTargeted.isNotEmpty) {
        muscleGroups.add(ex.musclesTargeted.first);
      }
      if (muscleGroups.length >= 3) break;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (heroExercise != null)
          ExerciseImage(exercise: heroExercise, size: ExerciseImageSize.hero)
        else
          Container(color: scheme.surfaceContainer),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surfaceContainerLowest.withValues(alpha: 0.55),
                scheme.surfaceContainerLowest.withValues(alpha: 0.1),
                scheme.surfaceContainerLowest.withValues(alpha: 0.98),
              ],
              stops: const [0.0, 0.34, 0.92],
            ),
          ),
        ),
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                t.spacing.lg,
                t.spacing.sm,
                t.spacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'GYMFLOW',
                    style: t.typography.title?.copyWith(
                      fontSize: _kLogoFontSize,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: scheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  if (streak > 0) ...[
                    Icon(Icons.bolt, size: 12, color: scheme.primary),
                    SizedBox(width: t.spacing.xs),
                    Text(
                      '$streak',
                      style: t.typography.eyebrow?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    t.spacing.lg,
                    0,
                    t.spacing.lg,
                    t.spacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: t.spacing.sm + 3,
                          vertical: t.spacing.xs + 2,
                        ),
                        color: scheme.primary,
                        child: Text(
                          '${loc.t('home_today_badge_prefix')} · ${workout.exercises.length} '
                              '${loc.t(workout.exercises.length == 1 ? 'home_exercise_one' : 'home_exercises')}'
                          .toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      SizedBox(height: t.spacing.sm),
                      Text(
                        workout.name.toUpperCase(),
                        style: t.typography.display?.copyWith(
                          color: scheme.onSurface,
                          fontSize: _kTitleFontSize,
                        ),
                      ),
                      if (muscleGroups.isNotEmpty) ...[
                        SizedBox(height: t.spacing.sm),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: t.spacing.sm,
                          children: [
                            for (final m in muscleGroups) ...[
                              Text(
                                m,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                              ),
                              if (m != muscleGroups.last)
                                Container(
                                  width: _kMuscleDotSide,
                                  height: _kMuscleDotSide,
                                  color: scheme.tertiary,
                                ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                t.spacing.lg,
                0,
                t.spacing.lg,
                t.spacing.sm,
              ),
              child: InkWell(
                onTap: onAction,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    t.spacing.lg,
                    t.spacing.sm,
                    t.spacing.sm,
                    t.spacing.sm,
                  ),
                  color: scheme.primary,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc
                              .t(
                                isResuming
                                    ? 'home_resume_workout'
                                    : 'start_workout',
                              )
                              .toUpperCase(),
                          style: t.typography.headline?.copyWith(
                            fontSize: _kCtaFontSize,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: _kCtaIconSide,
                        height: _kCtaIconSide,
                        alignment: Alignment.center,
                        color: scheme.surfaceContainerLowest,
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
/// Una delle due righe numerate sotto la striscia: "01 Prossima", "02 Sfida
/// del mese" nel mockup.
class _NumberedRow extends StatelessWidget {
  const _NumberedRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });
  final String number;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: t.spacing.sm + 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(number, style: t.typography.eyebrow),
            ),
            SizedBox(width: t.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: t.spacing.sm),
            trailing,
          ],
        ),
      ),
    );
  }
}
/// Le 5 destinazioni che il cassetto teneva, ora riquadri raggiungibili dalla
/// Home invece che da un cassetto ad amburger. Riquadri a filo (`Border.all`,
/// nessun riempimento) per restare fedeli al linguaggio "solo filetti" della
/// Home — non `ExpressiveCard`, che qui darebbe una superficie piena che il
/// mockup 1d non disegna da nessuna parte in questa schermata.
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.loc});
  final Localization loc;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final destinazioni = <_Shortcut>[
      _Shortcut(
        icon: Icons.bar_chart_rounded,
        label: loc.t('data_tab'),
        builder: (_) => const StatisticsScreen(),
      ),
      _Shortcut(
        icon: Icons.view_list_rounded,
        label: loc.t('programs_tab'),
        builder: (_) => const ProgramListScreen(),
      ),
      _Shortcut(
        icon: Icons.emoji_events_outlined,
        label: loc.t('achievements'),
        builder: (_) => const GamificationScreen(),
      ),
      _Shortcut(
        icon: Icons.flag_outlined,
        label: loc.t('goals_title_short'),
        builder: (_) => const GoalsScreen(),
      ),
      _Shortcut(
        icon: Icons.timer_outlined,
        label: loc.t('stopwatch_menu'),
        builder: (_) => const TimeToolsScreen(),
      ),
      _Shortcut(
        icon: Icons.person_add_alt_1,
        label: loc.t('connect_friend'),
        builder: (_) => const ConnectFriendScreen(),
      ),
    ];
    return SizedBox(
      height: _kShortcutTileHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: destinazioni.length,
        separatorBuilder: (_, _) => SizedBox(width: t.spacing.sm),
        itemBuilder: (context, index) => _ShortcutTile(shortcut: destinazioni[index]),
      ),
    );
  }
}
class _Shortcut {
  const _Shortcut({required this.icon, required this.label, required this.builder});
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut});
  final _Shortcut shortcut;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: shortcut.builder),
      ),
      child: Container(
        width: _kShortcutTileWidth,
        padding: EdgeInsets.symmetric(vertical: t.spacing.sm, horizontal: t.spacing.xs),
        decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(shortcut.icon, size: t.sizing.iconMd, color: scheme.onSurfaceVariant),
            SizedBox(height: t.spacing.sm),
            Text(
              shortcut.label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.typography.eyebrow?.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
/// Senza una scheda a cui puntare non c'e foto, non c'e titolo: solo
/// l'invito a crearne una, con lo stesso linguaggio del pulsante d'azione.
class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.loc});
  final Localization loc;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.all(t.spacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'GYMFLOW',
                style: t.typography.title?.copyWith(color: scheme.onSurface),
              ),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Container(
                  height: 1,
                  color: scheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          SizedBox(height: t.spacing.xxl),
          Text(
            loc.t('home_no_active_program').toUpperCase(),
            style: t.typography.headline?.copyWith(color: scheme.onSurface),
          ),
          SizedBox(height: t.spacing.sm),
          Text(
            loc.t('home_create_program_prompt'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: t.spacing.lg),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgramCreatorScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                t.spacing.lg,
                t.spacing.sm,
                t.spacing.sm,
                t.spacing.sm,
              ),
              color: scheme.primary,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.t('home_create_program_action').toUpperCase(),
                      style: t.typography.headline?.copyWith(
                        fontSize: _kCtaFontSize,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: _kCtaIconSide,
                    height: _kCtaIconSide,
                    alignment: Alignment.center,
                    color: scheme.surfaceContainerLowest,
                    child: Icon(Icons.add, color: scheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
