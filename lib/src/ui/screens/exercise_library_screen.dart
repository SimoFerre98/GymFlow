import 'package:flutter/material.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  final bool isSelecting; // If true, allows returning the selected exercise
  const ExerciseLibraryScreen({super.key, this.isSelecting = false});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Exercise',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Exercise>>(
              stream: _firestore.getExercises(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No exercises found. Add one!'),
                  );
                }

                final exercises = snapshot.data!.where((e) {
                  return e.name.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.2),
                          child: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        title: Text(exercise.name),
                        subtitle: Text(exercise.type.name.toUpperCase()),
                        onTap: () {
                          if (widget.isSelecting) {
                            Navigator.pop(context, exercise);
                          } else {
                            // TODO: Show exercise details
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open dialog to add custom exercise
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
