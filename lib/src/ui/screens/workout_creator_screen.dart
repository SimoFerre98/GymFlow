import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';
import 'package:gymflow/src/ui/widgets/exercise_thumbnail.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';
/// Misure del mockup 2g Creazione scheda (telaio 1:1, nessuna conversione
/// px→dp — vedi `DESIGN-SPEC.md`).
const double _kTitleFontSize = 27;
const double _kCloseIconBoxSide = 38;
const double _kThumbnailSide = 44;
const double _kStatFontSize = 24;
const double _kCtaIconBoxSide = 42;
const double _kDuplicateIconBoxSide = 58;
const double _kQuickStartTileHeight = 66;
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
  /// Salva lo stato attuale del modulo come una scheda nuova e separata,
  /// senza toccare quella in modifica: l'icona "duplica" del mockup.
  Future<void> _duplicateWorkout() async {
    final loc = ref.read(localizationNotifierProvider);
    if (_exercises.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('User not logged in');
      final copy = WorkoutTemplate(
        id: '',
        userId: user.uid,
        name: '${_nameController.text.trim()} ${loc.t('duplicate_suffix')}',
        description: _descriptionController.text.trim(),
        exercises: _exercises,
        category: _selectedType,
        parentProgramId: widget.parentProgramId,
      );
      final service = FirestoreService();
      final savedId = await service.saveWorkout(copy);
      if (widget.parentProgramId != null) {
        await service.addWorkoutToProgram(widget.parentProgramId!, savedId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('workout_duplicated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.t('error_prefix')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _applyTemplate(WorkoutTemplate template) {
    setState(() {
      _nameController.text = template.name;
      _selectedType = template.category;
      _exercises
        ..clear()
        ..addAll(template.exercises);
    });
  }
  Future<void> _showExerciseConfigurationSheet({
    WorkoutTemplateExercise? existing,
    required Function(WorkoutTemplateExercise) onSave,
  }) async {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.shape.radiusLg)),
      ),
      builder: (ctx) => _ExerciseConfigurationSheet(
        existing: existing,
        onSave: onSave,
      ),
    );
  }
  void _addExercise() async {
    final loc = ref.read(localizationNotifierProvider);
    final backLabel = widget.workout == null
        ? loc.t('new_day')
        : loc.t('edit_day');
    final Exercise? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          isSelecting: true,
          backLabel: backLabel,
        ),
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
  /// Stima grezza in secondi: tempo di esecuzione per serie più il recupero
  /// impostato (o 60" di default), sommati su tutti gli esercizi. Non è una
  /// misura, è una stima dichiarata come tale nell'etichetta "stimata".
  int get _estimatedSeconds {
    var total = 0;
    for (final e in _exercises) {
      total += e.targetSets * ((e.restSeconds ?? 60) + 35);
    }
    return total;
  }
  int get _totalSets =>
      _exercises.fold(0, (sum, e) => sum + e.targetSets);
  /// Volume stimato in kg: serie × la prima cifra leggibile in `targetReps`
  /// (che può essere "10", "8-12" o "Cedimento") × il peso target, quando
  /// c'è. Nessun dato inventato: solo quello che l'utente ha già impostato.
  int get _estimatedVolume {
    var total = 0.0;
    for (final e in _exercises) {
      final weight = e.targetWeight;
      if (weight == null || weight <= 0) continue;
      final repsMatch = RegExp(r'\d+').firstMatch(e.targetReps);
      final reps = repsMatch == null ? 0 : int.parse(repsMatch.group(0)!);
      total += e.targetSets * reps * weight;
    }
    return total.round();
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: t.spacing.sm),
                      _buildHeader(context, loc, t, scheme),
                      SizedBox(height: t.spacing.lg),
                      _buildNameField(context, loc, t, scheme),
                      SizedBox(height: t.spacing.lg),
                      _buildCategorySelector(context, loc, t, scheme),
                      if (widget.workout == null) ...[
                        SizedBox(height: t.spacing.lg),
                        _buildQuickStart(context, loc, t, scheme),
                      ],
                      SizedBox(height: t.spacing.xl),
                      _buildExercisesHeader(context, loc, t, scheme),
                      SizedBox(height: t.spacing.xs),
                      _buildExercisesList(context, loc, t, scheme),
                      _buildAddExerciseCta(context, loc, t, scheme),
                      SizedBox(height: t.spacing.md),
                      _buildStatsTrio(context, loc, t, scheme),
                      SizedBox(height: t.spacing.md),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context, loc, t, scheme),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: _kCloseIconBoxSide,
            height: _kCloseIconBoxSide,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              border: Border.all(color: scheme.outline),
            ),
            child: Icon(Icons.close, size: t.sizing.iconMd, color: scheme.onSurface),
          ),
        ),
        SizedBox(width: t.spacing.md),
        Text(
          (widget.workout == null ? loc.t('new_day') : loc.t('edit_day'))
              .toUpperCase(),
          style: t.typography.headline?.copyWith(
            fontSize: _kTitleFontSize,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(width: t.spacing.md),
        Expanded(
          child: Container(
            height: 1,
            color: scheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
  Widget _buildNameField(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('day_name_hint').toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border(left: BorderSide(color: scheme.primary, width: 3)),
          ),
          child: TextFormField(
            controller: _nameController,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(t.spacing.md),
              suffixIcon: Icon(
                Icons.edit_outlined,
                size: t.sizing.iconSm,
                color: scheme.onSurfaceVariant,
              ),
            ),
            validator: (v) => v!.isEmpty ? loc.t('name_required') : null,
          ),
        ),
      ],
    );
  }
  Widget _buildCategorySelector(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('focus_category').toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        Wrap(
          spacing: t.spacing.sm,
          runSpacing: t.spacing.sm,
          children: ExerciseType.values.map((type) {
            final isSelected = _selectedType == type;
            return _FilterPill(
              label: type.name,
              selected: isSelected,
              onTap: () => setState(() => _selectedType = type),
            );
          }).toList(),
        ),
      ],
    );
  }
  Widget _buildQuickStart(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('quick_start_label').toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        StreamBuilder<List<WorkoutTemplate>>(
          stream: FirestoreService().getUserWorkouts(userId),
          builder: (context, snapshot) {
            final templates =
                (snapshot.data ?? const <WorkoutTemplate>[]).take(2).toList();
            return SizedBox(
              height: _kQuickStartTileHeight,
              child: Row(
                children: [
                  for (final template in templates) ...[
                    Expanded(
                      child: _QuickStartTile(
                        title: template.name,
                        subtitle:
                            '${template.exercises.length} ${loc.t('exercises_section').toLowerCase()} · ${template.category.name.toUpperCase()}',
                        onTap: () => _applyTemplate(template),
                      ),
                    ),
                    SizedBox(width: t.spacing.sm),
                  ],
                  Expanded(
                    child: _QuickStartTile(
                      title: loc.t('quick_start_blank'),
                      subtitle: loc.t('quick_start_blank_hint').toUpperCase(),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _buildExercisesHeader(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${loc.t('exercises_section').toUpperCase()} · ${_exercises.length}',
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_exercises.length > 1)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_vert, size: t.sizing.iconSm, color: scheme.primary),
              SizedBox(width: t.spacing.xs),
              Text(
                loc.t('drag_to_reorder').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.primary),
              ),
            ],
          ),
      ],
    );
  }
  Widget _buildExercisesList(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    if (_exercises.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.lg),
        child: Center(
          child: Text(
            loc.t('no_exercises_added'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ReorderableListView(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final item = _exercises.removeAt(oldIndex);
          _exercises.insert(newIndex, item);
        });
      },
      children: [
        for (int index = 0; index < _exercises.length; index++)
          Dismissible(
            key: ValueKey(_exercises[index]),
            direction: DismissDirection.endToStart,
            background: Container(
              color: scheme.error,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: t.spacing.md),
              child: Icon(Icons.delete, color: scheme.onError),
            ),
            onDismissed: (_) => setState(() => _exercises.removeAt(index)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outline)),
              ),
              child: InkWell(
                onTap: () {
                  _showExerciseConfigurationSheet(
                    existing: _exercises[index],
                    onSave: (updated) {
                      setState(() => _exercises[index] = updated);
                    },
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: EdgeInsets.only(right: t.spacing.sm),
                          child: Icon(
                            Icons.drag_handle,
                            size: t.sizing.iconSm,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ExerciseThumbnailById(
                        exerciseId: _exercises[index].exerciseId,
                        exerciseName: _exercises[index].exerciseName,
                        side: _kThumbnailSide,
                        onTap: (exercise) =>
                            ExerciseVideoSheet.show(context, exercise),
                      ),
                      SizedBox(width: t.spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _exercises[index].exerciseName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _exerciseSummary(_exercises[index]),
                              style: t.typography.eyebrow?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                            if (_exercises[index].notes != null &&
                                _exercises[index].notes!.isNotEmpty)
                              Text(
                                _exercises[index].notes!,
                                style: Theme.of(context).textTheme.bodySmall
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
                      Icon(
                        Icons.chevron_right,
                        size: t.sizing.iconSm,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  String _exerciseSummary(WorkoutTemplateExercise exercise) {
    final parts = <String>['${exercise.targetSets} × ${exercise.targetReps}'];
    if (exercise.targetWeight != null && exercise.targetWeight! > 0) {
      parts.add('${exercise.targetWeight} KG');
    }
    if (exercise.restSeconds != null) {
      parts.add('${exercise.restSeconds}"');
    }
    return parts.join(' · ');
  }
  Widget _buildAddExerciseCta(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: t.spacing.md),
      child: InkWell(
        onTap: _addExercise,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: t.spacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outline,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: t.sizing.iconSm, color: scheme.primary),
              SizedBox(width: t.spacing.sm),
              Text(
                loc.t('add_btn').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStatsTrio(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    final minutes = _estimatedSeconds ~/ 60;
    final stats = [
      (loc.t('estimated_duration_label'), "$minutes'"),
      (loc.t('total_sets_label'), '$_totalSets'),
      (loc.t('estimated_volume_label'), '$_estimatedVolume kg'),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i > 0 ? t.spacing.md : 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: i > 0
                    ? Border(left: BorderSide(color: scheme.outline))
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? t.spacing.md : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats[i].$1.toUpperCase(),
                      style: t.typography.eyebrow?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      stats[i].$2,
                      style: t.typography.headline?.copyWith(
                        fontSize: _kStatFontSize,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildBottomBar(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spacing.md,
        t.spacing.sm,
        t.spacing.md,
        t.spacing.md,
      ),
      child: Row(
        children: [
          if (widget.workout != null) ...[
            InkWell(
              onTap: _isLoading ? null : _duplicateWorkout,
              child: Container(
                width: _kDuplicateIconBoxSide,
                height: _kDuplicateIconBoxSide,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  border: Border.all(color: scheme.outline),
                ),
                child: Icon(
                  Icons.copy_outlined,
                  color: scheme.onSurface,
                  size: t.sizing.iconMd,
                ),
              ),
            ),
            SizedBox(width: t.spacing.sm),
          ],
          Expanded(
            child: InkWell(
              onTap: _isLoading ? null : _saveWorkout,
              child: Container(
                height: _kDuplicateIconBoxSide,
                padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
                color: scheme.primary,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.t('save_day_cta').toUpperCase(),
                        style: t.typography.title?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      SizedBox(
                        width: t.sizing.iconMd,
                        height: t.sizing.iconMd,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    else
                      Container(
                        width: _kCtaIconBoxSide,
                        height: _kCtaIconBoxSide,
                        alignment: Alignment.center,
                        color: scheme.onPrimary,
                        child: Icon(Icons.check, color: scheme.primary),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
/// Pillola di scelta della categoria: stessa forma usata altrove nella
/// redesign per un filtro a riga singola (libreria esercizi, dettaglio).
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.md,
          vertical: t.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          border: selected ? null : Border.all(color: scheme.outline),
        ),
        child: Text(
          label.toUpperCase(),
          style: t.typography.eyebrow?.copyWith(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
/// Tessera "parti da un modello": una scheda esistente dell'utente (dati
/// veri) o l'opzione vuota, mai un preset inventato.
class _QuickStartTile extends StatelessWidget {
  const _QuickStartTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(t.spacing.sm),
        decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: t.spacing.xs / 2),
            Text(
              subtitle,
              style: t.typography.eyebrow?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
class _ExerciseConfigurationSheet extends ConsumerStatefulWidget {
  final WorkoutTemplateExercise? existing;
  final Function(WorkoutTemplateExercise) onSave;
  const _ExerciseConfigurationSheet({
    required this.existing,
    required this.onSave,
  });
  @override
  ConsumerState<_ExerciseConfigurationSheet> createState() =>
      _ExerciseConfigurationSheetState();
}
class _ExerciseConfigurationSheetState
    extends ConsumerState<_ExerciseConfigurationSheet> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _distanceController;
  late final TextEditingController _durationController;
  late final TextEditingController _restController;
  late final TextEditingController _notesController;
  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final type = existing?.type ?? ExerciseType.strength;
    final isCardio = type == ExerciseType.cardio;
    _setsController = TextEditingController(
      text: existing?.targetSets.toString() ?? (isCardio ? '1' : '3'),
    );
    _repsController = TextEditingController(
      text: existing?.targetReps ?? '10',
    );
    _weightController = TextEditingController(
      text: existing?.targetWeight != null && existing!.targetWeight! > 0
          ? existing.targetWeight.toString()
          : '',
    );
    _distanceController = TextEditingController(
      text: existing?.targetDistance?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: existing?.targetDurationSeconds != null
          ? (existing!.targetDurationSeconds! / 60).toStringAsFixed(0)
          : '',
    );
    _restController = TextEditingController(
      text: existing?.restSeconds?.toString() ?? '90',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }
  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  /// Stessa etichetta-sopra-il-campo di `_buildNameField`, non la
  /// `labelText` di Material dentro il campo: con tre campi affiancati
  /// (serie/ripetizioni/peso) l'etichetta interna non aveva la larghezza per
  /// il testo intero e Flutter la troncava a due o tre lettere ("Se...",
  /// "Rip...", "P..." — non si capiva più cosa fosse cosa, segnalato
  /// dall'utente). Sopra il campo l'etichetta ha tutta la colonna per sé.
  Widget _buildSheetInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: t.sizing.iconSm, color: scheme.onSurfaceVariant),
            SizedBox(width: t.spacing.xs),
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        SizedBox(height: t.spacing.xs),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border(left: BorderSide(color: scheme.primary, width: 3)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: t.spacing.sm,
                vertical: t.spacing.sm,
              ),
            ),
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final existing = widget.existing;
    final type = existing?.type ?? ExerciseType.strength;
    final isCardio = type == ExerciseType.cardio;
    final isTimed =
        type == ExerciseType.timed || type == ExerciseType.isometric;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + t.spacing.lg,
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
                    borderRadius: t.shape.cornerXs,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        existing?.exerciseName ?? loc.t('new_exercise'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
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
                      controller: _distanceController,
                      label: loc.t('distance_km_label'),
                      icon: Icons.map_outlined,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: _buildSheetInput(
                      controller: _durationController,
                      label: loc.t('time_min_label'),
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
            ] else if (isTimed) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSheetInput(
                      controller: _setsController,
                      label: loc.t('sets_label'),
                      icon: Icons.repeat,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: _buildSheetInput(
                      controller: _durationController,
                      label: loc.t('duration_sec_label'),
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
                      controller: _setsController,
                      label: loc.t('sets_label'),
                      icon: Icons.repeat,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: _buildSheetInput(
                      controller: _repsController,
                      label: loc.t('reps_label'),
                      icon: Icons.numbers,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: _buildSheetInput(
                      controller: _weightController,
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
                    controller: _restController,
                    label: loc.t('rest_sec_label'),
                    icon: Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
            SizedBox(height: t.spacing.md),
            TextField(
              controller: _notesController,
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
                final sets = int.tryParse(_setsController.text) ??
                    (isCardio ? 1 : 3);
                final reps = _repsController.text.isNotEmpty
                    ? _repsController.text
                    : "10";
                final weight = double.tryParse(
                  _weightController.text.replaceAll(',', '.'),
                );
                final distance = double.tryParse(
                  _distanceController.text.replaceAll(',', '.'),
                );
                int? durationSeconds;
                if (_durationController.text.isNotEmpty) {
                  if (isTimed) {
                    durationSeconds = int.tryParse(_durationController.text);
                  } else {
                    final mins = double.tryParse(_durationController.text);
                    if (mins != null) durationSeconds = (mins * 60).toInt();
                  }
                }
                final rest = int.tryParse(_restController.text);
                final notes = _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim();
                final result = WorkoutTemplateExercise(
                  exerciseId: existing?.exerciseId ?? '',
                  exerciseName: existing?.exerciseName ?? '',
                  type: existing?.type ?? ExerciseType.strength,
                  targetSets: sets,
                  targetReps: reps,
                  targetWeight: weight,
                  targetDistance: distance,
                  targetDurationSeconds: durationSeconds,
                  restSeconds: rest,
                  notes: notes,
                );
                Navigator.of(context).pop();
                widget.onSave(result);
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
    );
  }
}
