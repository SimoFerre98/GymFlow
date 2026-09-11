import 'dart:collection';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';
import 'package:rxdart/rxdart.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:intl/intl.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import '../../core/providers/localization_provider.dart';
/// Misure del mockup 2f Calendario (telaio 1:1, nessuna conversione px→dp).
const double _kMonthTitleFontSize = 30;
const double _kNavIconBoxSide = 34;
const double _kWeekDayNumberFontSize = 19;
/// Il pallino che segnala un allenamento programmato nella cella del mese:
/// un riempimento pieno, non un filetto — un bordo sottile su una cella già
/// piccola si perdeva nello sfondo (segnalato dall'utente).
const double _kEventDotSide = 5;
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}
class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  // Combine sessions and schedules into one stream
  Stream<Map<DateTime, List<dynamic>>> _getCalendarEvents(String userId) {
    final firestore = ref.watch(firestoreServiceProvider);
    return Rx.combineLatest4(
      firestore.getUserSessions(userId),
      firestore.getUserScheduledWorkouts(userId),
      firestore.getSharedSessions(userId),
      firestore.getSharedScheduledWorkouts(userId),
      (
        List<WorkoutSession> mySessions,
        List<ScheduledWorkout> mySchedules,
        List<WorkoutSession> sharedSessions,
        List<ScheduledWorkout> sharedSchedules,
      ) {
        final Map<DateTime, List<dynamic>> events = LinkedHashMap(
          equals: _isSameDay,
          hashCode: (DateTime key) {
            return key.day * 1000000 + key.month * 10000 + key.year;
          },
        );
        void addEvents(List<dynamic> list) {
          for (var item in list) {
            DateTime date;
            if (item is WorkoutSession) {
              date = DateTime(
                item.startTime.year,
                item.startTime.month,
                item.startTime.day,
              );
            } else if (item is ScheduledWorkout) {
              date = DateTime(
                item.scheduledDate.year,
                item.scheduledDate.month,
                item.scheduledDate.day,
              );
            } else {
              continue;
            }
            if (events[date] == null) events[date] = [];
            events[date]!.add(item);
          }
        }
        addEvents(mySessions);
        addEvents(mySchedules);
        addEvents(sharedSessions); // Friend sessions
        addEvents(sharedSchedules); // Friend schedules
        return events;
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    if (userId == null) {
      return Scaffold(body: Center(child: Text(loc.t('login_required'))));
    }
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Map<DateTime, List<dynamic>>>(
        stream: _getCalendarEvents(userId),
        builder: (context, snapshot) {
          final eventsMap = snapshot.data ?? {};
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: t.spacing.md,
              right: t.spacing.md,
              top: t.spacing.sm,
              bottom: t.spacing.bottomInset + t.spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(context, t, scheme),
                SizedBox(height: t.spacing.sm),
                _buildWeekdayRow(context, loc, t, scheme),
                SizedBox(height: t.spacing.xs),
                _buildMonthGrid(context, loc, t, scheme, eventsMap, userId),
                SizedBox(height: t.spacing.sm),
                _buildLegend(context, loc, t, scheme),
                SizedBox(height: t.spacing.xl),
                _buildWeekSection(context, loc, t, scheme, eventsMap, userId),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
  Widget _buildMonthHeader(
    BuildContext context,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    final loc = ref.read(localizationNotifierProvider);
    final monthLabel = DateFormat(
      'MMMM',
      loc.locale.languageCode,
    ).format(_focusedMonth);
    return Row(
      children: [
        Text(
          monthLabel.toUpperCase(),
          style: t.typography.headline?.copyWith(
            fontSize: _kMonthTitleFontSize,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(width: t.spacing.xs),
        Padding(
          // Allinea la base dell'anno a quella del titolo, che ha una riga
          // (`height: 0.9` di Anton) piu bassa della sua stessa font size.
          padding: EdgeInsets.only(top: _kMonthTitleFontSize * 0.3),
          child: Text(
            '${_focusedMonth.year}',
            style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
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
        _MonthNavButton(
          icon: Icons.chevron_left,
          onTap: () => setState(() {
            _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month - 1,
            );
          }),
        ),
        SizedBox(width: t.spacing.sm),
        _MonthNavButton(
          icon: Icons.chevron_right,
          onTap: () => setState(() {
            _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
            );
          }),
        ),
      ],
    );
  }
  Widget _buildWeekdayRow(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    // 2024-01-01 e un lunedi qualunque, usato solo come ancora per i nomi dei
    // sette giorni della settimana: nessun evento vero legato a questa data.
    final aMonday = DateTime(2024, 1, 1);
    return Row(
      children: List.generate(7, (i) {
        final day = aMonday.add(Duration(days: i));
        final label = DateFormat(
          'EEE',
          loc.locale.languageCode,
        ).format(day).substring(0, 1);
        return Expanded(
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: t.typography.eyebrow?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }),
    );
  }
  List<DateTime> _monthGridDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final leading = (first.weekday - DateTime.monday) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
    return List.generate(
      totalCells,
      (i) => first.add(Duration(days: i - leading)),
    );
  }
  Widget _buildMonthGrid(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    Map<DateTime, List<dynamic>> eventsMap,
    String userId,
  ) {
    final days = _monthGridDays(_focusedMonth);
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    Widget cell(DateTime day) {
      final key = DateTime(day.year, day.month, day.day);
      final inMonth = day.month == _focusedMonth.month;
      final events = eventsMap[key] ?? const [];
      // `any` per tipo, non conteggio: un giorno con due allenamenti fatti
      // resta comunque "fatto", non "fatto due volte" — quello che deve
      // restare visibile è la combinazione dei tipi presenti, non quante
      // occorrenze di ciascuno (vedi il pallino sotto per lo scheduled).
      final hasSession = events.any((e) => e is WorkoutSession);
      final hasScheduled = events.any((e) => e is ScheduledWorkout);
      final isToday = key == todayKey;
      // Il riempimento segue solo "fatto o no": "oggi" era un riempimento a
      // se, quindi un allenamento fatto proprio oggi spariva sotto il colore
      // di "oggi" — ora "oggi" è un anello sul bordo, mai un colore che
      // sostituisce quello del giorno.
      final background = hasSession ? scheme.secondary : scheme.surfaceContainerHigh;
      final textColor = hasSession
          ? scheme.onSecondary
          : (inMonth
              ? scheme.onSurfaceVariant
              : scheme.onSurfaceVariant.withValues(alpha: 0.4));
      return Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: EdgeInsets.all(t.spacing.xs / 2),
            child: InkWell(
              onTap: () =>
                  _showScheduleDialog(context, userId, loc, initialDate: key),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  border: isToday ? Border.all(color: scheme.primary, width: 2) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: t.typography.eyebrow?.copyWith(color: textColor),
                    ),
                    if (hasScheduled)
                      Positioned(
                        bottom: t.spacing.xs / 2,
                        child: Container(
                          width: _kEventDotSide,
                          height: _kEventDotSide,
                          color: textColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var row = 0; row < days.length ~/ 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++) cell(days[row * 7 + col]),
            ],
          ),
      ],
    );
  }
  Widget _buildLegend(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    Widget swatch(Color color, {bool outlined = false}) => Container(
      width: t.spacing.sm,
      height: t.spacing.sm,
      decoration: BoxDecoration(
        color: outlined ? null : color,
        border: outlined ? Border.all(color: color) : null,
      ),
    );
    Widget item(Widget dot, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        SizedBox(width: t.spacing.xs),
        Text(
          label.toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
    return Row(
      children: [
        item(swatch(scheme.secondary), loc.t('calendar_legend_done')),
        SizedBox(width: t.spacing.md),
        item(swatch(scheme.primary, outlined: true), loc.t('calendar_legend_today')),
        SizedBox(width: t.spacing.md),
        item(swatch(scheme.onSurfaceVariant), loc.t('calendar_legend_planned')),
      ],
    );
  }
  Widget _buildWeekSection(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    Map<DateTime, List<dynamic>> eventsMap,
    String userId,
  ) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: (now.weekday - DateTime.monday) % 7));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    var done = 0;
    var total = 0;
    for (final day in weekDays) {
      final events = eventsMap[DateTime(day.year, day.month, day.day)] ?? const [];
      if (events.any((e) => e is WorkoutSession)) {
        done++;
        total++;
      } else if (events.any((e) => e is ScheduledWorkout)) {
        total++;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.t('calendar_this_week').toUpperCase(),
              style: t.typography.eyebrow?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (total > 0)
              Text(
                '$done / $total',
                style: t.typography.eyebrow?.copyWith(color: scheme.primary),
              ),
          ],
        ),
        for (final day in weekDays)
          _buildWeekRow(context, loc, t, scheme, eventsMap, userId, day),
      ],
    );
  }
  Widget _buildWeekRow(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    Map<DateTime, List<dynamic>> eventsMap,
    String userId,
    DateTime day,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    final events = eventsMap[key] ?? const [];
    final now = DateTime.now();
    final isToday = key == DateTime(now.year, now.month, now.day);
    final dayAbbrev = DateFormat(
      'EEE',
      loc.locale.languageCode,
    ).format(day).toUpperCase();
    if (events.isEmpty) {
      return _WeekRow(
        dayAbbrev: dayAbbrev,
        dayNumber: '${day.day}',
        numberColor: isToday ? scheme.primary : scheme.onSurfaceVariant,
        title: loc.t('calendar_free_day'),
        titleColor: scheme.onSurface,
        subtitle: loc.t('calendar_tap_to_plan'),
        subtitleColor: scheme.onSurfaceVariant,
        trailing: Icon(Icons.add, color: scheme.primary, size: t.sizing.iconSm),
        onTap: () => _showScheduleDialog(context, userId, loc, initialDate: key),
      );
    }
    final event = events.firstWhere(
      (e) => e is WorkoutSession,
      orElse: () => events.first,
    );
    final isSession = event is WorkoutSession;
    final ownerId = isSession
        ? (event).userId
        : (event as ScheduledWorkout).userId;
    final isMine = ownerId == userId;
    final title = isSession
        ? (event).workoutName
        : (event as ScheduledWorkout).workoutName;
    // Gli stessi tre ruoli gia usati nella vecchia vista a card: `primary`
    // (ambra) solo per l'azione da fare adesso, `onSurfaceVariant` per cio
    // che e concluso, `secondary` per un evento che non e una tua azione.
    if (!isMine) {
      final icon = isSession
          ? Icons.check_circle_outline
          : Icons.schedule_send;
      return _WeekRow(
        dayAbbrev: dayAbbrev,
        dayNumber: '${day.day}',
        numberColor: scheme.secondary,
        title: '$title · ${loc.t('friend_label')}',
        titleColor: scheme.onSurface,
        subtitle: isSession
            ? '${loc.t('completed_at')} ${DateFormat('HH:mm').format((event).startTime)}'
            : '${loc.t('scheduled_for')} ${DateFormat('HH:mm').format((event as ScheduledWorkout).scheduledDate)}',
        subtitleColor: scheme.onSurfaceVariant,
        trailing: Icon(icon, color: scheme.secondary, size: t.sizing.iconSm),
      );
    }
    if (isSession) {
      final minutes = event.durationSeconds ~/ 60;
      final volumeKg = _sessionVolume(event);
      return Dismissible(
        key: Key('session-${event.id}'),
        direction: DismissDirection.endToStart,
        background: _dismissBackground(t, scheme),
        confirmDismiss: (_) => _confirmDelete(context, loc, scheme),
        onDismissed: (_) => _deleteEvent(loc, event),
        child: _WeekRow(
          dayAbbrev: dayAbbrev,
          dayNumber: '${day.day}',
          numberColor: scheme.secondary,
          title: title,
          titleColor: scheme.onSurface,
          subtitle: '$minutes ${loc.t('duration_min_short')} · $volumeKg kg',
          subtitleColor: scheme.onSurfaceVariant,
          trailing: Icon(
            Icons.check,
            color: scheme.secondary,
            size: t.sizing.iconSm,
          ),
        ),
      );
    }
    final scheduled = event as ScheduledWorkout;
    if (isToday) {
      return Dismissible(
        key: Key('scheduled-${scheduled.id}'),
        direction: DismissDirection.endToStart,
        background: _dismissBackground(t, scheme),
        confirmDismiss: (_) => _confirmDelete(context, loc, scheme),
        onDismissed: (_) => _deleteEvent(loc, scheduled),
        child: _WeekRow(
          dayAbbrev: dayAbbrev,
          dayNumber: '${day.day}',
          numberColor: scheme.primary,
          title: '$title · ${loc.t('today_label')}',
          titleColor: scheme.primary,
          subtitle: '${loc.t('scheduled_for')} ${DateFormat('HH:mm').format(scheduled.scheduledDate)}',
          subtitleColor: scheme.primary,
          highlighted: true,
          trailing: InkWell(
            onTap: () => _startWorkout(scheduled),
            child: Container(
              width: t.sizing.minTouchTarget - t.spacing.md,
              height: t.sizing.minTouchTarget - t.spacing.md,
              alignment: Alignment.center,
              color: scheme.primary,
              child: Icon(
                Icons.play_arrow,
                color: scheme.onPrimary,
                size: t.sizing.iconSm,
              ),
            ),
          ),
        ),
      );
    }
    return Dismissible(
      key: Key('scheduled-${scheduled.id}'),
      direction: DismissDirection.endToStart,
      background: _dismissBackground(t, scheme),
      confirmDismiss: (_) => _confirmDelete(context, loc, scheme),
      onDismissed: (_) => _deleteEvent(loc, scheduled),
      child: _WeekRow(
        dayAbbrev: dayAbbrev,
        dayNumber: '${day.day}',
        numberColor: scheme.onSurfaceVariant,
        title: title,
        titleColor: scheme.onSurface,
        subtitle: '${loc.t('scheduled_for')} ${DateFormat('HH:mm').format(scheduled.scheduledDate)}',
        subtitleColor: scheme.onSurfaceVariant,
        trailing: InkWell(
          onLongPress: () => _addToDeviceCalendar(scheduled),
          child: Icon(
            Icons.schedule,
            color: scheme.onSurfaceVariant,
            size: t.sizing.iconSm,
          ),
        ),
      ),
    );
  }
  Widget _dismissBackground(ImmersivoTokens t, ColorScheme scheme) {
    return Container(
      color: scheme.error,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: t.spacing.md),
      child: Icon(Icons.delete, color: scheme.onError),
    );
  }
  Future<bool> _confirmDelete(
    BuildContext context,
    Localization loc,
    ColorScheme scheme,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('delete_event_title')),
        content: Text(loc.t('delete_event_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              loc.t('delete'),
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  void _deleteEvent(Localization loc, dynamic event) {
    final firestore = ref.read(firestoreServiceProvider);
    if (event is WorkoutSession) {
      firestore.deleteSession(event.id);
    } else if (event is ScheduledWorkout) {
      firestore.deleteScheduledWorkout(event.id);
    }
    ToastUtils.showInfo(context, loc.t('event_deleted'));
  }
  /// Volume totale della sessione in kg: stessa formula di
  /// `StatisticsHelper.calculateTotalVolume`, per una sola sessione.
  int _sessionVolume(WorkoutSession session) {
    double volume = 0;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (set.isCompleted && set.weight > 0 && set.reps > 0) {
          volume += set.weight * set.reps;
        }
      }
    }
    return volume.round();
  }
  void _addToDeviceCalendar(ScheduledWorkout schedule) {
    final loc = ref.read(localizationNotifierProvider);
    final event = Event(
      title: '${loc.t('workout_label')} ${schedule.workoutName}',
      description: loc.t('scheduled_using'),
      location: loc.t('gym_label'),
      startDate: schedule.scheduledDate,
      endDate: schedule.scheduledDate.add(const Duration(hours: 1)),
    );
    Add2Calendar.addEvent2Cal(event);
  }
  Future<void> _startWorkout(ScheduledWorkout schedule) async {
    final firestore = ref.read(firestoreServiceProvider);
    final workout = await firestore.getWorkout(schedule.workoutTemplateId);
    if (workout != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveSessionScreen(
            workout: workout,
            scheduledWorkoutId: schedule.id,
          ),
        ),
      );
    }
  }
  void _showScheduleDialog(
    BuildContext context,
    String userId,
    Localization loc, {
    DateTime? initialDate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final t = context.immersivo;
        final scheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: scheme.outline)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(t.spacing.md),
                child: Container(
                  width: t.sizing.thumbnailSm,
                  height: t.spacing.xs,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: t.spacing.md),
                child: Text(
                  loc.t('select_workout_schedule'),
                  style: t.typography.title?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<WorkoutTemplate>>(
                  stream: ref.read(firestoreServiceProvider).getUserWorkouts(userId),
                  builder: (context, workoutsSnapshot) {
                    if (!workoutsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return StreamBuilder<List<WorkoutProgram>>(
                      stream: ref.read(firestoreServiceProvider).getUserPrograms(userId),
                      builder: (context, programsSnapshot) {
                        // We don't block on loading programs, just show default if not ready
                        final programs = programsSnapshot.data ?? [];
                        final workouts = workoutsSnapshot.data!;
                        if (workouts.isEmpty) {
                          return Center(
                            child: Text(loc.t('no_workouts_create_first')),
                          );
                        }
                        // Map programId -> Program for fast lookup
                        final programMap = {for (var p in programs) p.id: p};
                        return ListView.separated(
                          padding: EdgeInsets.all(t.spacing.md),
                          itemCount: workouts.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: t.spacing.sm),
                          itemBuilder: (context, index) {
                            final workout = workouts[index];
                            final parentProgram =
                                workout.parentProgramId != null
                                ? programMap[workout.parentProgramId]
                                : null;
                            // Il colore della scheda e un dato scelto
                            // dall'utente, quindi resta suo. Il ripiego invece
                            // era una decisione visiva scritta a mano — il blu
                            // di Material — e diventa un ruolo.
                            final color = parentProgram != null
                                ? Color(parentProgram.color)
                                : scheme.secondary;
                            return InkWell(
                              onTap: () async {
                                final date =
                                    (initialDate ?? DateTime.now()).copyWith(
                                      hour: 12, // Default to noon
                                      minute: 0,
                                    );
                                final schedule = ScheduledWorkout(
                                  id: '',
                                  userId: userId,
                                  workoutTemplateId: workout.id,
                                  workoutName: workout.name,
                                  scheduledDate: date,
                                );
                                await ref.read(firestoreServiceProvider).scheduleWorkout(schedule);
                                // `mounted` e dello State del calendario, non
                                // di questo `context`: e quello dell'item
                                // dentro `itemBuilder`, un `BuildContext`
                                // diverso. `context.mounted` controlla quello
                                // giusto invece di un ramo dello stesso albero.
                                if (context.mounted) Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: EdgeInsets.all(t.spacing.md),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  border: Border.all(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.05,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(t.spacing.sm),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                      ),
                                      child: Icon(
                                        Icons.fitness_center,
                                        color: color,
                                      ),
                                    ),
                                    SizedBox(width: t.spacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workout.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: scheme.onSurface,
                                                ),
                                          ),
                                          if (parentProgram != null)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: t.spacing.xs,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: t.spacing.sm,
                                                    height: t.spacing.sm,
                                                    color: color,
                                                  ),
                                                  SizedBox(
                                                    width: t.spacing.xs,
                                                  ),
                                                  Text(
                                                    parentProgram.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: scheme
                                                              .onSurfaceVariant,
                                                        ),
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
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/// Pulsante quadrato di navigazione fra mesi: bordo sottile, nessun fondo.
class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: _kNavIconBoxSide,
        height: _kNavIconBoxSide,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
        child: Icon(icon, size: t.sizing.iconSm, color: scheme.onSurface),
      ),
    );
  }
}
/// Una riga della sezione "Questa settimana": colonna del giorno, titolo e
/// sottotitolo, azione a destra. Stessa forma per tutti gli stati (libero,
/// fatto, pianificato, di un amico) — cambiano solo i colori e l'icona.
class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.dayAbbrev,
    required this.dayNumber,
    required this.numberColor,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.subtitleColor,
    required this.trailing,
    this.onTap,
    this.highlighted = false,
  });
  final String dayAbbrev;
  final String dayNumber;
  final Color numberColor;
  final String title;
  final Color titleColor;
  final String subtitle;
  final Color subtitleColor;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted ? scheme.primary.withValues(alpha: 0.05) : null,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: t.sizing.thumbnailSm - t.spacing.sm,
                child: Column(
                  children: [
                    Text(
                      dayAbbrev,
                      style: t.typography.eyebrow?.copyWith(
                        color: numberColor,
                      ),
                    ),
                    Text(
                      dayNumber,
                      style: t.typography.headline?.copyWith(
                        fontSize: _kWeekDayNumberFontSize,
                        color: numberColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
