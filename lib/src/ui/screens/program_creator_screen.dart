import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
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
const double _kTitleFontSize = 26;
const double _kIconBoxSide = 36;
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
  /// Elimina un giorno dal programma: prima non c'era alcun modo di farlo,
  /// solo spostarlo avanti e indietro (segnalato dall'utente).
  ///
  /// Scrive `workoutIds` per intero da `remainingWorkouts`, non toglie un
  /// solo id dalla lista di `currentProgram`: stessa ragione del riordino,
  /// risana un eventuale disallineamento invece di perpetuarlo. Cancella
  /// anche la scheda stessa — restare come giorno "orfano", ne' nel
  /// programma ne' altrove, non e' quello che l'utente chiede quando dice
  /// "elimina".
  Future<void> _deleteDay(
    WorkoutProgram currentProgram,
    List<WorkoutTemplate> remainingWorkouts,
    WorkoutTemplate removed,
  ) async {
    final loc = ref.read(localizationNotifierProvider);
    try {
      final updated = WorkoutProgram(
        id: currentProgram.id,
        userId: currentProgram.userId,
        name: currentProgram.name,
        description: currentProgram.description,
        workoutIds: remainingWorkouts.map((w) => w.id).toList(),
        isActive: currentProgram.isActive,
        createdAt: currentProgram.createdAt,
        startDate: currentProgram.startDate,
        endDate: currentProgram.endDate,
        color: currentProgram.color,
      );
      await FirestoreService().saveProgram(updated);
      await FirestoreService().deleteWorkout(removed.id);
      if (mounted) {
        ToastUtils.showInfo(context, loc.t('day_deleted'));
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(
          context,
          '${loc.t('program_save_error')}: $e',
        );
      }
    }
  }
  Future<bool> _confirmDeleteDay(WorkoutTemplate workout) async {
    final loc = ref.read(localizationNotifierProvider);
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('delete_day_title')),
        content: Text(
          '${loc.t('delete_day_body_prefix')} "${workout.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text(loc.t('delete')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('programs_tab')),
                  SizedBox(width: t.spacing.md),
                  Text(
                    (widget.program == null
                            ? loc.t('new_program')
                            : loc.t('edit_program'))
                        .toUpperCase(),
                    style: t.typography.headline?.copyWith(
                      fontSize: _kTitleFontSize,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                  SizedBox(width: t.spacing.md),
                  InkWell(
                    onTap: _isLoading ? null : _saveProgram,
                    child: Container(
                      width: _kIconBoxSide,
                      height: _kIconBoxSide,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Icon(Icons.check, size: 18, color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
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
                    _buildField(
                      controller: _nameController,
                      label: loc.t('program_name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? loc.t('name_required') : null,
                    ),
                    SizedBox(height: t.spacing.md),
                    _buildField(
                      controller: _descController,
                      label: loc.t('description_label'),
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
                            borderRadius: t.shape.cornerXs,
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
                              loc.t('date_range_label').toUpperCase(),
                              style: t.typography.eyebrow?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
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
                            decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
                            child: Center(
                              child: Text(loc.t('no_days_added')),
                            ),
                          )
                        else
                          ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            // Riordina `programWorkouts`, non
                            // `currentProgram.workoutIds` direttamente: sono
                            // due liste che possono avere lunghezze diverse
                            // (sopra, "trova orfani" ne aggiunge, un id
                            // spuntato ne toglie), e oldIndex/newIndex sono
                            // posizioni nella lista mostrata. Applicarli a
                            // un'altra lista, più corta, poteva far uscire
                            // dai limiti e far crashare l'app; scrivere
                            // sempre workoutIds da qui, per intero, risana
                            // anche l'eventuale disallineamento invece di
                            // perpetuarlo.
                            onReorderItem: (oldIndex, newIndex) async {
                              final reordered = List<WorkoutTemplate>.from(
                                programWorkouts,
                              );
                              final item = reordered.removeAt(oldIndex);
                              reordered.insert(newIndex, item);
                              final updated = WorkoutProgram(
                                id: currentProgram.id,
                                userId: currentProgram.userId,
                                name: currentProgram.name,
                                description: currentProgram.description,
                                workoutIds: reordered.map((w) => w.id).toList(),
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
                                Dismissible(
                                  key: ValueKey(workout.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => _confirmDeleteDay(workout),
                                  onDismissed: (_) => _deleteDay(
                                    currentProgram,
                                    programWorkouts.where((w) => w.id != workout.id).toList(),
                                    workout,
                                  ),
                                  background: Container(
                                    color: scheme.error,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(right: t.spacing.md),
                                    child: Icon(Icons.delete, color: scheme.onError),
                                  ),
                                  child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: scheme.outline)),
                                  ),
                                  child: InkWell(
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
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: t.sizing.thumbnailSm,
                                            height: t.sizing.thumbnailSm,
                                            alignment: Alignment.center,
                                            color: scheme.surfaceContainerHigh,
                                            child: Text(
                                              '${programWorkouts.indexOf(workout) + 1}',
                                              style: t.typography.metricSmall?.copyWith(color: scheme.onSurface),
                                            ),
                                          ),
                                          SizedBox(width: t.spacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  workout.name,
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  '${workout.exercises.length} ${loc.t('exercises_label')}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: scheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.drag_handle, color: scheme.onSurfaceVariant),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ),
                                ),
                            ],
                          ),
                        SizedBox(height: t.spacing.sm),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutCreatorScreen(
                                  parentProgramId: currentProgram.id,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: t.spacing.md),
                            decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: scheme.primary),
                                SizedBox(width: t.spacing.sm),
                                Text(
                                  loc.t('add_workout_day'),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
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
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border(left: BorderSide(color: scheme.primary, width: 3)),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(t.spacing.md),
              suffixIcon: maxLines == 1
                  ? Icon(Icons.edit_outlined, size: t.sizing.iconSm, color: scheme.onSurfaceVariant)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSection({required String title, required Widget child}) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        child,
      ],
    );
  }
}
