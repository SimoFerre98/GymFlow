import 'dart:collection';
import 'dart:ui';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';
import 'package:rxdart/rxdart.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:intl/intl.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import '../../core/providers/localization_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

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
          equals: isSameDay,
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

    if (userId == null) {
      return Scaffold(body: Center(child: Text(loc.t('login_required'))));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.t('calendar_title')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showScheduleDialog(context, userId, loc),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<Map<DateTime, List<dynamic>>>(
            stream: _getCalendarEvents(userId),
            builder: (context, snapshot) {
              final eventsMap = snapshot.data ?? {};

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlassCalendar(eventsMap),
                        SizedBox(height: context.expressive.spacing.md),
                      ],
                    ),
                  ),
                  _buildEventListSliver(eventsMap, loc),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: context.expressive.spacing.lg,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCalendar(Map<DateTime, List<dynamic>> eventsMap) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: t.spacing.sm,
      ),
      decoration: BoxDecoration(
        // `surfaceContainerHigh` e non `cardColor`: quel campo precede
        // Material 3, il tema non lo imposta, e il mockup vuole le superfici
        // due gradini sopra lo sfondo.
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: t.shape.cornerLg,
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
        // L'ombra viene dal design system e segue il tema, invece di essere
        // nera per sempre.
        boxShadow: t.elevation.level2(scheme.shadow),
      ),
      child: ClipRRect(
        borderRadius: t.shape.cornerLg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              return eventsMap[DateTime(day.year, day.month, day.day)] ?? [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                // Il giorno scelto e l'elemento che galleggia sopra la
                // griglia: e il livello che il design system riserva a questo.
                boxShadow: t.elevation.level3(scheme.primary),
              ),
              // Il pallino dice «qui c'e qualcosa», non «fai questo»: resta
              // fuori dall'ambra, che significa solo azione.
              markerDecoration: BoxDecoration(
                color: scheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonShowsNext: false,
              titleCentered: true,
              formatButtonTextStyle: TextStyle(color: scheme.onSurface),
              titleTextStyle:
                  t.typography.titleEmphasized?.copyWith(
                    color: scheme.onSurface,
                  ) ??
                  TextStyle(color: scheme.onSurface),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: scheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventListSliver(
    Map<DateTime, List<dynamic>> eventsMap,
    Localization loc,
  ) {
    if (_selectedDay == null) {
      return SliverFillRemaining(
        child: Center(child: Text(loc.t('select_day'))),
      );
    }

    final dateKey = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final dailyEvents = eventsMap[dateKey] ?? [];

    if (dailyEvents.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available,
                size: context.expressive.sizing.thumbnailLg,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: context.expressive.spacing.md),
              Text(
                loc.t('no_workouts_day'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.expressive.spacing.md),
              ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(
                  context,
                  ref.read(currentUserIdProvider)!,
                  loc,
                  initialDate: _selectedDay,
                ),
                icon: const Icon(Icons.add),
                label: Text(loc.t('schedule_workout_btn')),
                style: ElevatedButton.styleFrom(
                  // I pulsanti d'azione del mockup hanno il raggio pieno.
                  shape: RoundedRectangleBorder(
                    borderRadius: context.expressive.shape.cornerFull,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.expressive.spacing.xl,
                    vertical: context.expressive.spacing.sm,
                  ),
                ),
              ),
              SizedBox(height: context.expressive.spacing.xxl),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = dailyEvents[index];
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.expressive.spacing.md,
          ),
          child: _buildEventCard(event, loc),
        );
      }, childCount: dailyEvents.length),
    );
  }

  Widget _buildEventCard(dynamic event, Localization loc) {
    bool isCompleted = event is WorkoutSession;
    String id = isCompleted
        ? (event).id
        : (event as ScheduledWorkout).id;
    String ownerId = isCompleted
        ? (event).userId
        : (event as ScheduledWorkout).userId;
    String title = isCompleted
        ? (event).workoutName
        : (event as ScheduledWorkout).workoutName;

    // Use locale for time format? Usually HH:mm is standard but maybe?
    // loc.locale.languageCode could be used but DateFormat('HH:mm') is fine.

    String subtitle = isCompleted
        ? '${loc.t('completed_at')} ${DateFormat('HH:mm').format((event).startTime)}'
        : '${loc.t('scheduled_for')} ${DateFormat('HH:mm').format((event as ScheduledWorkout).scheduledDate)}';

    bool isMine = ownerId == ref.read(currentUserIdProvider);

    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    // I tre stati di un evento portavano viola, verde e arancione acceso,
    // nessuno dei quali e in palette. Il criterio con cui sono stati riportati
    // sui ruoli:
    //
    // - **da fare, tuo** -> `primary` ambra, perche l'ambra significa una cosa
    //   sola: cosa fare adesso, ed e esattamente questo;
    // - **fatto, tuo** -> `onSurfaceVariant`, perche cio che e concluso deve
    //   arretrare invece di chiedere attenzione;
    // - **di un amico** -> `secondary` indigo, perche non e una tua azione.
    //
    // Il salmone resta fuori: la palette lo riserva ai dati vitali, e un
    // evento in calendario non lo e. US-064 potra rivedere questa scala quando
    // distinguera i tipi di allenamento.
    Color accent;
    IconData icon;

    if (!isMine) {
      accent = scheme.secondary;
      icon = isCompleted ? Icons.check_circle_outline : Icons.schedule_send;
      subtitle += ' ${loc.t('friend_label')}';
    } else {
      accent = isCompleted ? scheme.onSurfaceVariant : scheme.primary;
      icon = isCompleted ? Icons.check_circle : Icons.schedule;
    }

    Widget cardContent = Container(
      margin: EdgeInsets.symmetric(vertical: t.spacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: t.shape.cornerLg,
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: t.elevation.level1(accent),
      ),
      child: ClipRRect(
        borderRadius: t.shape.cornerLg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ListTile(
            contentPadding: EdgeInsets.all(t.spacing.md),
            leading: Container(
              padding: EdgeInsets.all(t.spacing.sm),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: accent),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            subtitle: Text(subtitle),
            trailing: isMine
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCompleted)
                        IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () => _addToDeviceCalendar(event),
                          tooltip: loc.t('sync_calendar'),
                        ),
                      if (!isCompleted)
                        IconButton(
                          // Avviare l'allenamento e l'azione principale della
                          // riga: ambra, non il blu che c'era qui.
                          icon: Icon(
                            Icons.play_circle_fill,
                            color: scheme.primary,
                          ),
                          onPressed: () => _startWorkout(event),
                        ),
                    ],
                  )
                : null, // No actions for friends
          ),
        ),
      ),
    );

    if (!isMine) {
      return cardContent; // Cannot dismiss/delete friend events
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(vertical: t.spacing.sm),
        decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: 0.8),
          borderRadius: t.shape.cornerMd,
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: t.spacing.lg),
        child: Icon(Icons.delete, color: scheme.onError),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
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
      },
      onDismissed: (_) {
        final firestore = ref.read(firestoreServiceProvider);
        if (isCompleted) {
          firestore.deleteSession(id);
        } else {
          firestore.deleteScheduledWorkout(id);
        }
        ToastUtils.showInfo(context, loc.t('event_deleted'));
      },
      child: cardContent,
    );
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
        final t = context.expressive;
        final scheme = Theme.of(context).colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(t.shape.radiusLg),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(t.spacing.md),
                child: Container(
                  width: t.sizing.thumbnailSm,
                  height: t.spacing.xs,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant,
                    borderRadius: t.shape.cornerXs,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: t.spacing.md),
                child: Text(
                  loc.t('select_workout_schedule'),
                  style: t.typography.titleEmphasized?.copyWith(
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
                                    (initialDate ??
                                            _selectedDay ??
                                            DateTime.now())
                                        .copyWith(
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
                                  borderRadius: t.shape.cornerMd,
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
                                        shape: BoxShape.circle,
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
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
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
