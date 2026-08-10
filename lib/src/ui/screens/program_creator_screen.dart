import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/screens/workout_creator_screen.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

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
  int _selectedColor = 0xFF2196F3;
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
    _selectedColor = widget.program?.color ?? 0xFF2196F3;
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
        ToastUtils.showError(context, 'Error saving program: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program == null ? 'New Program' : 'Edit Program'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProgram,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              _buildSection(
                title: 'Basic Info',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                      labelText: loc.t('program_name'),
                        hintText: loc.t('program_name_hint'),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? loc.t('name_required') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                      labelText: loc.t('description_label'),
                        hintText: loc.t('description_hint'),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: 'Color',
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        [
                          0xFFF44336, // Red
                          0xFFE91E63, // Pink
                          0xFF9C27B0, // Purple
                          0xFF2196F3, // Blue
                          0xFF00BCD4, // Cyan
                          0xFF4CAF50, // Green
                          0xFFFFEB3B, // Yellow
                          0xFFFF9800, // Orange
                          0xFF795548, // Brown
                          0xFF607D8B, // Blue Grey
                        ].map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: Color(color).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Duration Card
              _buildSection(
                title: 'Duration',
                child: InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.blue),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start - End Date',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                                  : loc.t('tap_to_select_dates'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('No days added yet'),
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
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withValues(alpha: 0.2),
                                      child: Text(
                                        '${programWorkouts.indexOf(workout) + 1}',
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
                        const SizedBox(height: 12),
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
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Save program to add workout days.',
                      style: TextStyle(color: Colors.grey),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

