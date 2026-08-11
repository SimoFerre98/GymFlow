import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';
import 'package:gymflow/src/ui/widgets/exercise_thumbnail.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';

class WorkoutCreatorScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate? workout; // If provided, we are editing
  final String? parentProgramId;
  const WorkoutCreatorScreen({super.key, this.workout, this.parentProgramId});

  @override
  ConsumerState<WorkoutCreatorScreen> createState() => _WorkoutCreatorScreenState();
}

class _WorkoutCreatorScreenState extends ConsumerState<WorkoutCreatorScreen> {
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(localizationNotifierProvider).t('add_at_least_one_exercise'))),
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
        ).showSnackBar(SnackBar(content: Text('${ref.read(localizationNotifierProvider).t('error_prefix')}: $e')));
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
        Text(
          ref.watch(localizationNotifierProvider).t('focus_category'),
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
              ).colorScheme.primary.withValues(alpha: 0.3),
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

  Future<void> _showExerciseConfigurationSheet({
    WorkoutTemplateExercise? existing,
    required Function(WorkoutTemplateExercise) onSave,
  }) async {
    // Defaults based on Type
    // If existing, use values. Else, defaults.
    // However, 'type' comes from 'existing'. When adding new, we pass a temp object with correct type.
    // `read` e non `watch`: questo non e un `build`, e il foglio vive il tempo
    // di una configurazione.
    final loc = ref.read(localizationNotifierProvider);

    final type = existing?.type ?? ExerciseType.strength;
    final isCardio = type == ExerciseType.cardio;
    final isTimed =
        type == ExerciseType.timed || type == ExerciseType.isometric;

    // Controllers
    final setsController = TextEditingController(
      text: existing?.targetSets.toString() ?? (isCardio ? '1' : '3'),
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCardio ? Icons.directions_run : Icons.fitness_center,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCardio
                              ? loc.t('configure_cardio')
                              : loc.t('configure_strength'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          existing?.exerciseName ?? loc.t('new_exercise'),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dynamic Fields
              if (isCardio) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildSheetInput(
                        controller: distanceController,
                        label: loc.t('distance_km_label'),
                        icon: Icons.map_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSheetInput(
                        controller: durationController,
                        label: loc.t('time_min_label'),
                        icon: Icons.timer_outlined,
                      ),
                    ),
                  ],
                ),
                // Hidden Sets input but maybe advanced toggle? For now, imply 1 set or keep hidden.
                // We kept setsController default to 1.
              ] else if (isTimed) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildSheetInput(
                        controller: setsController,
                        label: loc.t('sets_label'),
                        icon: Icons.repeat,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSheetInput(
                        controller: durationController,
                        label: loc.t('duration_sec_label'),
                        // Plan said min/sec. Let's assume min for consistency with cardio or sec for holds.
                        // Usually isometric is seconds. Let's label sec.
                        icon: Icons.timer,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Strength default
                Row(
                  children: [
                    Expanded(
                      child: _buildSheetInput(
                        controller: setsController,
                        label: loc.t('sets_label'),
                        icon: Icons.repeat,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSheetInput(
                        controller: repsController,
                        label: loc.t('reps_label'),
                        icon: Icons.numbers,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSheetInput(
                        controller: weightController,
                        label: loc.t('weight_kg_label'),
                        icon: Icons.fitness_center_outlined,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Common Fields
              Row(
                children: [
                  Expanded(
                    child: _buildSheetInput(
                      controller: restController,
                      label: loc.t('rest_sec_label'),
                      icon: Icons.hourglass_empty,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: loc.t('notes_optional'),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  final sets =
                      int.tryParse(setsController.text) ?? (isCardio ? 1 : 3);
                  final reps = repsController.text.isNotEmpty
                      ? repsController.text
                      : "10";
                  final weight = double.tryParse(
                    weightController.text.replaceAll(',', '.'),
                  );
                  final distance = double.tryParse(
                    distanceController.text.replaceAll(',', '.'),
                  );

                  // Handle Duration
                  int? durationSeconds;
                  if (durationController.text.isNotEmpty) {
                    // For Timed/Isometric, maybe interpret as seconds if labeled sec
                    if (isTimed) {
                      durationSeconds = int.tryParse(durationController.text);
                    } else {
                      // Cardio usually minutes
                      final mins = double.tryParse(durationController.text);
                      if (mins != null) durationSeconds = (mins * 60).toInt();
                    }
                  }

                  final rest = int.tryParse(restController.text);
                  final notes = notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim();

                  if (existing != null) {
                    onSave(
                      WorkoutTemplateExercise(
                        exerciseId: existing.exerciseId,
                        exerciseName: existing.exerciseName,
                        type: existing.type,
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  loc.t('save_exercise'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Il bottom sheet Ã¨ chiuso: nessun widget usa piÃ¹ questi controller.
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    distanceController.dispose();
    durationController.dispose();
    restController.dispose();
    notesController.dispose();
  }

  Widget _buildSheetInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
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
      // Determine initial sets based on type
      final isCardio = result.type == ExerciseType.cardio;

      // Create a temporary object to hold ID/Name
      final temp = WorkoutTemplateExercise(
        exerciseId: result.id,
        exerciseName: result.name,
        type: result.type,
        targetSets: isCardio ? 1 : 3, // Default 1 for Cardio
        targetReps: isCardio ? "" : "10",
      );

      // Show sheet to customize immediately
      await _showExerciseConfigurationSheet(
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
    final loc = ref.watch(localizationNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workout == null ? loc.t('new_day') : loc.t('edit_day'),
        ),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                      labelText: loc.t('day_name_hint'),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? loc.t('name_required') : null,
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
                    loc.t('exercises_section'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: Text(loc.t('add_btn')),
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
                            loc.t('no_exercises_added'),
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
                              // Al posto del numero d'ordine: in una lista
                              // riordinabile la posizione e l'ordine, e la
                              // maniglia di trascinamento resta in coda.
                              leading: ExerciseThumbnailById(
                                exerciseId: _exercises[index].exerciseId,
                                exerciseName: _exercises[index].exerciseName,
                                onTap: (exercise) =>
                                    ExerciseVideoSheet.show(context, exercise),
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
                                        '${loc.t('rest_label')}: ${_exercises[index].restSeconds}s',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (_exercises[index].notes != null &&
                                        _exercises[index].notes!.isNotEmpty)
                                      Text(
                                        '${loc.t('note_label')}: ${_exercises[index].notes}',
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
                                _showExerciseConfigurationSheet(
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


