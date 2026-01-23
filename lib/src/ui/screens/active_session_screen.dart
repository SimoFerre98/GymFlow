import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class ActiveSessionScreen extends StatefulWidget {
  final WorkoutTemplate workout;
  const ActiveSessionScreen({super.key, required this.workout});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _formattedTime = "00:00:00";

  // We clone the exercises to track progress without modifying the template immediately
  // Ideally, use a deep copy or map to a new Session object state
  late List<WorkoutExercise> _sessionExercises;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _formattedTime = _formatTime(_stopwatch.elapsedMilliseconds);
        });
      }
    });

    // Create a copy of exercises for this session
    // Note: detailed deep copy logic might be needed for production
    _sessionExercises = widget.workout.exercises.map((e) {
      return WorkoutExercise(
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        sets: e.sets
            .map(
              (s) => WorkoutSet(
                weight: s.weight,
                reps: s.reps,
                isCompleted: false,
              ),
            )
            .toList(),
      );
    }).toList();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int milliseconds) {
    var secs = milliseconds ~/ 1000;
    var hours = (secs ~/ 3600).toString().padLeft(2, '0');
    var minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
    var seconds = (secs % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  bool _isSaving = false;

  Future<void> _finishWorkout() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final session = WorkoutSession(
      id: const Uuid().v4(),
      userId: user.uid,
      workoutTemplateId: widget.workout.id,
      workoutName: widget.workout.name,
      startTime: DateTime.now().subtract(_stopwatch.elapsed),
      endTime: DateTime.now(),
      exercises: _sessionExercises,
      workoutType: widget.workout.category.name,
    );

    // Fire and forget save
    FirestoreService().saveSession(session).ignore();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Great job! Workout saved. 💪')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Active Session', style: TextStyle(fontSize: 12)),
            Text(
              _formattedTime,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _finishWorkout,
                  child: const Text(
                    'FINISH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _sessionExercises.length,
        itemBuilder: (context, index) {
          final exercise = _sessionExercises[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1), // Set #
                    1: FlexColumnWidth(2), // Weight
                    2: FlexColumnWidth(2), // Reps
                    3: FlexColumnWidth(1), // Check
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    const TableRow(
                      children: [
                        Center(
                          child: Text(
                            '#',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Kg',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Reps',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        SizedBox(),
                      ],
                    ),
                    ...exercise.sets.asMap().entries.map((entry) {
                      final setIndex = entry.key;
                      final set = entry.value;
                      return TableRow(
                        children: [
                          Center(child: Text('${setIndex + 1}')),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              initialValue: set.weight.toString(),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                              onChanged: (val) => set.weight =
                                  double.tryParse(val) ?? set.weight,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              initialValue: set.reps.toString(),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                              onChanged: (val) =>
                                  set.reps = int.tryParse(val) ?? set.reps,
                            ),
                          ),
                          Checkbox(
                            value: set.isCompleted,
                            onChanged: (val) {
                              setState(() {
                                set.isCompleted = val ?? false;
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                    onPressed: () {
                      setState(() {
                        exercise.sets.add(WorkoutSet(weight: 0, reps: 0));
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
