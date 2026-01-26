import 'package:flutter/material.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';

class WorkoutCreatorScreen extends StatefulWidget {
  final WorkoutTemplate? workout; // If provided, we are editing
  final String? parentProgramId;
  const WorkoutCreatorScreen({super.key, this.workout, this.parentProgramId});

  @override
  State<WorkoutCreatorScreen> createState() => _WorkoutCreatorScreenState();
}

class _WorkoutCreatorScreenState extends State<WorkoutCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<WorkoutTemplateExercise> _exercises = [];
  ExerciseType _selectedType = ExerciseType.strength; // Main focus
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

      final workoutId = widget.workout?.id ?? '';
      final workout = WorkoutTemplate(
        id: workoutId,
        userId: user.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        exercises: _exercises,
        category: _selectedType,
        parentProgramId: widget.parentProgramId,
      );

      final service = FirestoreService();
      final savedId = await service.saveWorkout(workout);

      // Ensure linkage exists (idempotent arrayUnion)
      if (widget.parentProgramId != null) {
        await FirestoreService().addWorkoutToProgram(
          widget.parentProgramId!,
          savedId,
        );
      }

      if (mounted) Navigator.of(context).pop();
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

  // Custom Filter Chip Widget for Category Selection
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Focus Category',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ExerciseType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(type.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type;
                });
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.3),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _showEditExerciseDialog({
    WorkoutTemplateExercise? existing,
    required Function(WorkoutTemplateExercise) onSave,
  }) async {
    final setsController = TextEditingController(
      text: existing?.targetSets.toString() ?? '3',
    );
    final repsController = TextEditingController(
      text: existing?.targetReps ?? '10',
    );
    final weightController = TextEditingController(
      text: existing?.targetWeight?.toString() ?? '',
    );
    final distanceController = TextEditingController(
      text: existing?.targetDistance?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: existing?.targetDurationSeconds != null
          ? (existing!.targetDurationSeconds! / 60).toStringAsFixed(0)
          : '',
    );
    final restController = TextEditingController(
      text: existing?.restSeconds?.toString() ?? '90',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');

    final type = existing?.type ?? ExerciseType.strength;
    final isCardio = type == ExerciseType.cardio;
    final isTimed =
        type == ExerciseType.timed || type == ExerciseType.isometric;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Targets' : 'Set Targets'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: setsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isCardio ? 'Intervals (Optional)' : 'Sets',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!isCardio && !isTimed)
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        decoration: const InputDecoration(
                          labelText: 'Reps (e.g. 8-12)',
                        ),
                      ),
                    ),
                  if (isCardio || isTimed)
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)', // Simple min input
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isCardio)
                    Expanded(
                      child: TextField(
                        controller: distanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Distance (km)',
                        ),
                      ),
                    ),
                  if (!isCardio && !isTimed)
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                        ),
                      ),
                    ),
                  if (isCardio) const SizedBox(width: 16),
                  if (!isCardio && !isTimed) const SizedBox(width: 16),

                  Expanded(
                    child: TextField(
                      controller: restController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rest (sec)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Cue (Optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text) ?? 3;
              final reps = repsController.text.isNotEmpty
                  ? repsController.text
                  : "10";
              final weight = double.tryParse(
                weightController.text.replaceAll(',', '.'),
              );
              final distance = double.tryParse(
                distanceController.text.replaceAll(',', '.'),
              );
              final durationMins = double.tryParse(durationController.text);
              final durationSeconds = durationMins != null
                  ? (durationMins * 60).toInt()
                  : null;

              final rest = int.tryParse(restController.text);
              final notes = notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim();

              // We need to construct the object. If 'existing' is provided, we use its ID/Name.
              // But 'onSave' might be cleaner to handle the logic.
              // Actually, simpler to return the values or object.

              if (existing != null) {
                onSave(
                  WorkoutTemplateExercise(
                    exerciseId: existing.exerciseId,
                    exerciseName: existing.exerciseName,
                    type: existing.type, // IMPORTANT: Maintain type
                    targetSets: sets,
                    targetReps: reps,
                    targetWeight: weight,
                    targetDistance: distance,
                    targetDurationSeconds: durationSeconds,
                    restSeconds: rest,
                    notes: notes,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addExercise() async {
    final Exercise? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseLibraryScreen(isSelecting: true),
      ),
    );

    if (result != null && mounted) {
      // Create a temporary object to hold ID/Name
      final temp = WorkoutTemplateExercise(
        exerciseId: result.id,
        exerciseName: result.name,
        type: result.type,
        targetSets: 3,
        targetReps: "10",
      );

      // Show dialog to customize immediately
      await _showEditExerciseDialog(
        existing: temp,
        onSave: (newExercise) {
          setState(() {
            _exercises.add(newExercise);
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout == null ? 'New Day' : 'Edit Day'),
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
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Day Name (e.g. Push Day)',
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exercises',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _exercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No exercises added yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView(
                      buildDefaultDragHandles:
                          false, // Hide default handles outside card
                      padding: const EdgeInsets.only(bottom: 80),
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _exercises.removeAt(oldIndex);
                          _exercises.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int index = 0; index < _exercises.length; index++)
                          Card(
                            key: ValueKey(_exercises[index]),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 16,
                                right: 8,
                                top: 4,
                                bottom: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                _exercises[index].exerciseName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_exercises[index].targetSets} x ${_exercises[index].targetReps}'
                                      '${_exercises[index].targetWeight != null && _exercises[index].targetWeight! > 0 ? " @ ${_exercises[index].targetWeight}kg" : ""}',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_exercises[index].restSeconds != null)
                                      Text(
                                        'Rest: ${_exercises[index].restSeconds}s',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (_exercises[index].notes != null &&
                                        _exercises[index].notes!.isNotEmpty)
                                      Text(
                                        'Note: ${_exercises[index].notes}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _exercises.removeAt(index),
                                      );
                                    },
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showEditExerciseDialog(
                                  existing: _exercises[index],
                                  onSave: (updated) {
                                    setState(() {
                                      _exercises[index] = updated;
                                    });
                                  },
                                );
                              },
                            ),
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
