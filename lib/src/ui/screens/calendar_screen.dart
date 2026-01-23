import 'package:flutter/material.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: FirestoreService().getUserSessions(user?.uid ?? ''),
        builder: (context, snapshot) {
          // Process sessions into a map for the calendar
          // Simple visualization: List of sessions
          List<WorkoutSession> sessions = snapshot.data ?? [];

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
                  return sessions
                      .where((s) => isSameDay(s.startTime, day))
                      .toList();
                },
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Divider(),
              Expanded(child: _buildSessionList(sessions)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionList(List<WorkoutSession> allSessions) {
    if (_selectedDay == null) return const Center(child: Text('Select a day'));

    final dailySessions = allSessions
        .where((s) => isSameDay(s.startTime, _selectedDay))
        .toList();

    if (dailySessions.isEmpty)
      return const Center(child: Text('No workouts on this day'));

    return ListView.builder(
      itemCount: dailySessions.length,
      itemBuilder: (context, index) {
        final session = dailySessions[index];
        return ListTile(
          leading: const Icon(Icons.fitness_center),
          title: Text(session.workoutName),
          subtitle: Text('${session.exercises.length} Exercises'),
        );
      },
    );
  }
}
