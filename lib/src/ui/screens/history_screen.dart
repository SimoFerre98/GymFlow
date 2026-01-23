import 'package:flutter/material.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const Center(child: Text('Login required'));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: FirestoreService().getUserSessions(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history yet. Go lift!'));
          }

          final sessions = snapshot.data!;
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final date = DateFormat.yMMMd().add_jm().format(
                session.startTime,
              );
              final duration = session.endTime != null
                  ? session.endTime!.difference(session.startTime)
                  : Duration.zero;
              final durationStr = "${duration.inMinutes} min";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(session.workoutName),
                  subtitle: Text('$date • $durationStr'),
                  children: [
                    ...session.exercises.map(
                      (e) => ListTile(
                        title: Text(e.exerciseName),
                        subtitle: Text('${e.sets.length} sets completed'),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
