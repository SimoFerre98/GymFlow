import 'dart:collection';
import 'dart:ui';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';
import 'package:rxdart/rxdart.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Combine sessions and schedules into one stream
  Stream<Map<DateTime, List<dynamic>>> _getCalendarEvents(String userId) {
    return Rx.combineLatest2(
      _firestore.getUserSessions(userId),
      _firestore.getUserScheduledWorkouts(userId),
      (List<WorkoutSession> sessions, List<ScheduledWorkout> schedules) {
        final Map<DateTime, List<dynamic>> events = LinkedHashMap(
          equals: isSameDay,
          hashCode: (DateTime key) {
            return key.day * 1000000 + key.month * 10000 + key.year;
          },
        );

        for (var session in sessions) {
          final date = DateTime(
            session.startTime.year,
            session.startTime.month,
            session.startTime.day,
          );
          if (events[date] == null) events[date] = [];
          events[date]!.add(session);
        }

        for (var schedule in schedules) {
          final date = DateTime(
            schedule.scheduledDate.year,
            schedule.scheduledDate.month,
            schedule.scheduledDate.day,
          );
          if (events[date] == null) events[date] = [];
          events[date]!.add(schedule);
        }
        return events;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Login required')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showScheduleDialog(context, user.uid),
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
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<Map<DateTime, List<dynamic>>>(
            stream: _getCalendarEvents(user.uid),
            builder: (context, snapshot) {
              final eventsMap = snapshot.data ?? {};

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlassCalendar(eventsMap),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  _buildEventListSliver(eventsMap),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCalendar(Map<DateTime, List<dynamic>> eventsMap) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Adjusted margin
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonShowsNext: false,
              titleCentered: true,
              formatButtonTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventListSliver(Map<DateTime, List<dynamic>> eventsMap) {
    if (_selectedDay == null) {
      return const SliverFillRemaining(
        child: Center(child: Text('Select a day')),
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
                size: 64,
                color: Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'No workouts this day',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(
                  context,
                  _auth.currentUser!.uid,
                  initialDate: _selectedDay,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Schedule Workout'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 40), // Extra space
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = dailyEvents[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildEventCard(event),
        );
      }, childCount: dailyEvents.length),
    );
  }

  Widget _buildEventCard(dynamic event) {
    bool isCompleted = event is WorkoutSession;
    String id = isCompleted
        ? (event as WorkoutSession).id
        : (event as ScheduledWorkout).id;
    String title = isCompleted
        ? (event as WorkoutSession).workoutName
        : (event as ScheduledWorkout).workoutName;
    String subtitle = isCompleted
        ? 'Completed at ${DateFormat('HH:mm').format((event as WorkoutSession).startTime)}'
        : 'Scheduled for ${DateFormat('HH:mm').format((event as ScheduledWorkout).scheduledDate)}';
    Color glowColor = isCompleted ? Colors.greenAccent : Colors.orangeAccent;
    IconData icon = isCompleted ? Icons.check_circle : Icons.schedule;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Event?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (isCompleted) {
          _firestore.deleteSession(id);
        } else {
          _firestore.deleteScheduledWorkout(id);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: glowColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: glowColor.withOpacity(0.5)),
                ),
                child: Icon(icon, color: glowColor),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(subtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted)
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () =>
                          _addToDeviceCalendar(event as ScheduledWorkout),
                      tooltip: 'Sync to Calendar',
                    ),
                  if (!isCompleted)
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.blue,
                      ),
                      onPressed: () => _startWorkout(event as ScheduledWorkout),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addToDeviceCalendar(ScheduledWorkout schedule) {
    final event = Event(
      title: 'Workout: ${schedule.workoutName}',
      description: 'Scheduled using GymFlow',
      location: 'Gym',
      startDate: schedule.scheduledDate,
      endDate: schedule.scheduledDate.add(const Duration(hours: 1)),
    );

    Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _startWorkout(ScheduledWorkout schedule) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final workout = await firestore.getWorkout(schedule.workoutTemplateId);
    if (workout != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveSessionScreen(workout: workout),
        ),
      );
    }
  }

  void _showScheduleDialog(
    BuildContext context,
    String userId, {
    DateTime? initialDate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Select Workout to Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<WorkoutTemplate>>(
                  stream: _firestore.getUserWorkouts(userId),
                  builder: (context, workoutsSnapshot) {
                    if (!workoutsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder<List<WorkoutProgram>>(
                      stream: _firestore.getUserPrograms(userId),
                      builder: (context, programsSnapshot) {
                        // We don't block on loading programs, just show default if not ready
                        final programs = programsSnapshot.data ?? [];
                        final workouts = workoutsSnapshot.data!;

                        if (workouts.isEmpty) {
                          return const Center(
                            child: Text("No workouts found. Create one first!"),
                          );
                        }

                        // Map programId -> Program for fast lookup
                        final programMap = {for (var p in programs) p.id: p};

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: workouts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final workout = workouts[index];
                            final parentProgram =
                                workout.parentProgramId != null
                                ? programMap[workout.parentProgramId]
                                : null;

                            // Use program color if available, else blue default
                            final colorValue =
                                parentProgram?.color ?? 0xFF2196F3;
                            final color = Color(colorValue);

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
                                await _firestore.scheduleWorkout(schedule);
                                if (mounted) Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.fitness_center,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            workout.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (parentProgram != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    parentProgram.name,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
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
