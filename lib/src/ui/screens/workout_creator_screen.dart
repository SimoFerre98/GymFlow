import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
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
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.watch(localizationNotifierProvider).t('focus_category'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: t.spacing.sm),
        Wrap(
          spacing: t.spacing.sm,
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
              backgroundColor: scheme.surfaceContainerHigh,
              selectedColor: scheme.primary.withValues(alpha: 0.3),
              checkmarkColor: scheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: t.shape.cornerFull,
                side: BorderSide(
                  color: isSelected ? scheme.primary : Colors.transparent,
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
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

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
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.shape.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + t.spacing.lg,
          left: t.spacing.lg,
          right: t.spacing.lg,
          top: t.spacing.lg,
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
                    padding: EdgeInsets.all(t.spacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCardio ? Icons.directions_run : Icons.fitness_center,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
              SizedBox(height: t.spacing.xl),

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
                    SizedBox(width: t.spacing.md),
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
                    SizedBox(width: t.spacing.md),
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
                    SizedBox(width: t.spacing.md),
                    Expanded(
                      child: _buildSheetInput(
                        controller: repsController,
                        label: loc.t('reps_label'),
                        icon: Icons.numbers,
                      ),
                    ),
                    SizedBox(width: t.spacing.md),
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

              SizedBox(height: t.spacing.md),

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
              SizedBox(height: t.spacing.md),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: loc.t('notes_optional'),
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: t.shape.cornerSm,
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              SizedBox(height: t.spacing.xl),

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
                  padding: EdgeInsets.symmetric(vertical: t.spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: t.shape.cornerSm,
                  ),
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                child: Text(
                  loc.t('save_exercise'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Il bottom sheet è chiuso: nessun widget usa più questi controller.
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
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: t.sizing.iconSm),
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: t.shape.cornerSm,
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
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
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
              padding: EdgeInsets.all(t.spacing.md),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(t.shape.radiusLg),
                ),
                boxShadow: t.elevation.level2(scheme.shadow),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: loc.t('day_name_hint'),
                      filled: true,
                      fillColor: scheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: t.shape.cornerSm,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? loc.t('name_required') : null,
                  ),
                  SizedBox(height: t.spacing.md),
                  _buildCategorySelector(),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                t.spacing.md,
                t.spacing.xl,
                t.spacing.md,
                t.spacing.sm,
              ),
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
                        borderRadius: t.shape.cornerFull,
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
                            size: t.sizing.thumbnailSm,
                            color: scheme.onSurfaceVariant,
                          ),
                          SizedBox(height: t.spacing.md),
                          Text(
                            loc.t('no_exercises_added'),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView(
                      buildDefaultDragHandles:
                          false, // Hide default handles outside card
                      padding: EdgeInsets.only(bottom: t.spacing.bottomInset),
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
                            margin: EdgeInsets.symmetric(
                              horizontal: t.spacing.md,
                              vertical: t.spacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: t.shape.cornerMd,
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.only(
                                left: t.spacing.md,
                                right: t.spacing.sm,
                                top: t.spacing.xs,
                                bottom: t.spacing.xs,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onSurface,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: t.spacing.xs),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_exercises[index].targetSets} x ${_exercises[index].targetReps}'
                                      '${_exercises[index].targetWeight != null && _exercises[index].targetWeight! > 0 ? " @ ${_exercises[index].targetWeight}kg" : ""}',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_exercises[index].restSeconds != null)
                                      Text(
                                        '${loc.t('rest_label')}: ${_exercises[index].restSeconds}s',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    if (_exercises[index].notes != null &&
                                        _exercises[index].notes!.isNotEmpty)
                                      Text(
                                        '${loc.t('note_label')}: ${_exercises[index].notes}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
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
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: AppPalette.danger,
                                      size: t.sizing.iconMd,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _exercises.removeAt(index),
                                      );
                                    },
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Padding(
                                      padding: EdgeInsets.all(t.spacing.sm),
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: scheme.onSurfaceVariant,
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


