import 'package:flutter/material.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/workout_creator_screen.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GymFlow')),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<WorkoutTemplate>>(
        stream: FirestoreService().getUserWorkouts(
          AuthService().currentUser?.uid ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No workouts yet. Create one!'));
          }

          final workouts = snapshot.data!;
          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(workout.name),
                  subtitle: Text(
                    '${workout.exercises.length} Exercises • ${workout.category.name}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveSessionScreen(workout: workout),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutCreatorScreen(workout: workout),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Workout'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutCreatorScreen()),
          );
        },
      ),
    );
  }
}
