import 'package:flutter/material.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';

class WorkoutCreatorScreen extends StatefulWidget {
  final WorkoutTemplate? workout; // If provided, we are editing
  const WorkoutCreatorScreen({super.key, this.workout});

  @override
  State<WorkoutCreatorScreen> createState() => _WorkoutCreatorScreenState();
}

class _WorkoutCreatorScreenState extends State<WorkoutCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<WorkoutTemplateExercise> _exercises = [];
  ExerciseType _selectedType = ExerciseType.strength;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _descriptionController.text = widget.workout!.description ?? '';
      _exercises.addAll(widget.workout!.exercises);
      _selectedType = widget.workout!.category;
    }
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('User not logged in');

      final workout = WorkoutTemplate(
        id: widget.workout?.id ?? '',
        userId: user.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        exercises: _exercises,
        category: _selectedType,
      );

      await FirestoreService().saveWorkout(workout);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addExercise() async {
    final Exercise? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseLibraryScreen(isSelecting: true),
      ),
    );

    if (result != null) {
      setState(() {
        _exercises.add(
          WorkoutTemplateExercise(
            exerciseId: result.id,
            exerciseName: result.name,
            targetSets: 3, // Default
            targetReps: "10",
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout == null ? 'New Workout' : 'Edit Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveWorkout,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Workout Name',
                    ),
                    validator: (v) => v!.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExerciseType>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ExerciseType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exercises',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: _addExercise,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                children: [
                  for (int index = 0; index < _exercises.length; index++)
                    ListTile(
                      key: ValueKey(_exercises[index]),
                      title: Text(_exercises[index].exerciseName),
                      subtitle: Text(
                        '${_exercises[index].targetSets} Sets x ${_exercises[index].targetReps} Reps',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _exercises.removeAt(index));
                        },
                      ),
                      onTap: () {
                        // TODO: Edit Targets (Sets/Reps)
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
