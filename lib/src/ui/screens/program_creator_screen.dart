import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/screens/workout_creator_screen.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

/// Altezza della fila di pastiglie colore: geometria di questa schermata.
const double _kAltezzaSelettoreColore = 50;

class ProgramCreatorScreen extends ConsumerStatefulWidget {
  final WorkoutProgram? program;
  const ProgramCreatorScreen({super.key, this.program});

  @override
  ConsumerState<ProgramCreatorScreen> createState() => _ProgramCreatorScreenState();
}

class _ProgramCreatorScreenState extends ConsumerState<ProgramCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedColor = AppPalette.defaultProgramColor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program?.name ?? '');
    _descController = TextEditingController(
      text: widget.program?.description ?? '',
    );
    _startDate = widget.program?.startDate;
    _endDate = widget.program?.endDate;
    _selectedColor = widget.program?.color ?? AppPalette.defaultProgramColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('User not logged in');

      final program = WorkoutProgram(
        id: widget.program?.id ?? '',
        userId: user.uid,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        workoutIds: widget.program?.workoutIds ?? [],
        isActive: widget.program?.isActive ?? true,
        createdAt: widget.program?.createdAt ?? DateTime.now(),
        startDate: _startDate,
        endDate: _endDate,
        color: _selectedColor,
      );

      await FirestoreService().saveProgram(program);

      if (mounted) {
        ToastUtils.showSuccess(context, ref.read(localizationNotifierProvider).t('program_saved_success'));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(
          context,
          '${ref.read(localizationNotifierProvider).t('program_save_error')}: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          widget.program == null
              ? loc.t('new_program')
              : loc.t('edit_program'),
        ),
        leading: BackPill(label: loc.t('programs_tab')),
        leadingWidth: BackPill.leadingWidth,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProgram,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(t.spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              _buildSection(
                title: loc.t('basic_info'),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                      labelText: loc.t('program_name'),
                        hintText: loc.t('program_name_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? loc.t('name_required') : null,
                    ),
                    SizedBox(height: t.spacing.md),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                      labelText: loc.t('description_label'),
                        hintText: loc.t('description_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: t.spacing.md),

              _buildSection(
                title: loc.t('color_label'),
                child: SizedBox(
                  height: _kAltezzaSelettoreColore,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: AppPalette.programColorPresets.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: t.sizing.thumbnailSm,
                          height: t.sizing.thumbnailSm,
                          margin: EdgeInsets.only(right: t.spacing.sm),
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: scheme.onSurface, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? t.elevation.level1(Color(color))
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: AppPalette.paper,
                                  size: t.sizing.iconMd,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: t.spacing.md),

              // Duration Card
              _buildSection(
                title: loc.t('duration_section'),
                child: InkWell(
                  onTap: _pickDateRange,
                  borderRadius: t.shape.cornerXs,
                  child: Container(
                    padding: EdgeInsets.all(t.spacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outline),
                      borderRadius: t.shape.cornerXs,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: scheme.primary),
                        SizedBox(width: t.spacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.t('date_range_label'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            SizedBox(height: t.spacing.xs),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                                  : loc.t('tap_to_select_dates'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: t.spacing.xl),

              // Days Section (Workouts)
              if (widget.program != null)
                StreamBuilder<
                  ({WorkoutProgram program, List<WorkoutTemplate> workouts})
                >(
                  stream: Rx.combineLatest2(
                    FirestoreService().getProgramStream(widget.program!.id),
                    FirestoreService().getUserWorkouts(
                      AuthService().currentUser!.uid,
                    ),
                    (program, workouts) =>
                        (program: program, workouts: workouts),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final currentProgram = snapshot.data!.program;
                    final allWorkouts = snapshot.data!.workouts;

                    final programWorkouts = <WorkoutTemplate>[];

                    final workoutMap = {for (var w in allWorkouts) w.id: w};

                    // 1. Get ordered workouts from explicit list
                    for (var id in currentProgram.workoutIds) {
                      if (workoutMap.containsKey(id)) {
                        programWorkouts.add(workoutMap[id]!);
                      }
                    }

                    // 2. Find orphans (workouts pointing to this program but not in list)
                    final linkedWorkouts = allWorkouts
                        .where((w) => w.parentProgramId == currentProgram.id)
                        .toList();
                    for (var w in linkedWorkouts) {
                      if (!programWorkouts.any((pw) => pw.id == w.id)) {
                        programWorkouts.add(w);
                        // Optional: Auto-repair could happen here or on reorder
                      }
                    }

                    return Column(
                      children: [
                        if (programWorkouts.isEmpty)
                          Container(
                            padding: EdgeInsets.all(t.spacing.lg),
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.outline),
                              borderRadius: t.shape.cornerSm,
                            ),
                            child: Center(
                              child: Text(loc.t('no_days_added')),
                            ),
                          )
                        else
                          ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onReorder: (oldIndex, newIndex) async {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final ids = List<String>.from(
                                currentProgram.workoutIds,
                              );
                              final item = ids.removeAt(oldIndex);
                              ids.insert(newIndex, item);

                              final updated = WorkoutProgram(
                                id: currentProgram.id,
                                userId: currentProgram.userId,
                                name: currentProgram.name,
                                description: currentProgram.description,
                                workoutIds: ids,
                                isActive: currentProgram.isActive,
                                createdAt: currentProgram.createdAt,
                                startDate: currentProgram.startDate,
                                endDate: currentProgram.endDate,
                                color: currentProgram.color,
                              );
                              await FirestoreService().saveProgram(updated);
                            },
                            children: [
                              for (final workout in programWorkouts)
                                Card(
                                  key: ValueKey(workout.id),
                                  margin: EdgeInsets.symmetric(
                                    vertical: t.spacing.xs,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: scheme.surfaceContainer,
                                      child: Text(
                                        '${programWorkouts.indexOf(workout) + 1}',
                                        style: TextStyle(color: scheme.onSurface),
                                      ),
                                    ),
                                    title: Text(workout.name),
                                    subtitle: Text(
                                      '${workout.exercises.length} Exercises',
                                    ),
                                    trailing: const Icon(Icons.drag_handle),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WorkoutCreatorScreen(
                                            workout: workout,
                                            parentProgramId: currentProgram.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        SizedBox(height: t.spacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutCreatorScreen(
                                    parentProgramId: currentProgram.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: Text(loc.t('add_workout_day')),
                          ),
                        ),
                      ],
                    );
                  },
                ),

              if (widget.program == null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: t.spacing.lg),
                    child: Text(
                      loc.t('save_program_first'),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: t.spacing.sm),
        child,
      ],
    );
  }
}

