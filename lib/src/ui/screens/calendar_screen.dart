import 'dart:collection';
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

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();

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
    if (user == null)
      return const Scaffold(body: Center(child: Text('Login required')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () => _showScheduleDialog(context, user.uid),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<Map<DateTime, List<dynamic>>>(
        stream: _getCalendarEvents(user.uid),
        builder: (context, snapshot) {
          final eventsMap = snapshot.data ?? {};

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) {
                  return eventsMap[DateTime(day.year, day.month, day.day)] ??
                      [];
                },
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Divider(),
              Expanded(child: _buildEventList(eventsMap)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(Map<DateTime, List<dynamic>> eventsMap) {
    if (_selectedDay == null) return const Center(child: Text('Select a day'));

    // Normalize date for map lookup
    final dateKey = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final dailyEvents = eventsMap[dateKey] ?? [];

    if (dailyEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No workouts regarding this day'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showScheduleDialog(
                context,
                _auth.currentUser!.uid,
                initialDate: _selectedDay,
              ),
              child: const Text('Schedule Workout'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: dailyEvents.length,
      itemBuilder: (context, index) {
        final event = dailyEvents[index];

        if (event is WorkoutSession) {
          return Dismissible(
            key: Key('session_${event.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm"),
                    content: const Text(
                      "Are you sure you want to delete this completed session?",
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _firestore.deleteSession(event.id);
            },
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(event.workoutName),
              subtitle: const Text('Completed'),
            ),
          );
        } else if (event is ScheduledWorkout) {
          return Dismissible(
            key: Key(event.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Delete Schedule?"),
                    content: const Text(
                      "Remove this scheduled workout from calendar?",
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _firestore.deleteScheduledWorkout(event.id);
            },
            child: ListTile(
              leading: const Icon(Icons.schedule, color: Colors.orange),
              title: Text(event.workoutName),
              subtitle: const Text('Scheduled'),
              trailing: const Icon(Icons.play_arrow),
              onTap: () async {
                final firestore = Provider.of<FirestoreService>(
                  context,
                  listen: false,
                );
                final workoutWithId = await firestore.getWorkout(
                  event.workoutTemplateId,
                );

                if (workoutWithId != null && context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ActiveSessionScreen(workout: workoutWithId),
                    ),
                  );
                  // Optional: Delete schedule after completing?
                  // For now, let's leave it or maybe ask user.
                  // Ideally if they save the session, we might want to remove the schedule or mark it done.
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Workout template not found'),
                    ),
                  );
                }
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showScheduleDialog(
    BuildContext context,
    String userId, {
    DateTime? initialDate,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<List<WorkoutTemplate>>(
          stream: _firestore.getUserWorkouts(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final workouts = snapshot.data!;

            return ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return ListTile(
                  title: Text(workout.name),
                  onTap: () async {
                    // Schedule for selected day or today
                    final date = (initialDate ?? _selectedDay ?? DateTime.now())
                        .copyWith(
                          hour: 12,
                          minute: 0,
                          second: 0,
                          millisecond: 0,
                          microsecond: 0,
                        );

                    final schedule = ScheduledWorkout(
                      id: '',
                      userId: userId,
                      workoutTemplateId: workout.id,
                      workoutName: workout.name,
                      scheduledDate: date,
                    );
                    await _firestore.scheduleWorkout(schedule);
                    if (mounted) Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
