import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:uuid/uuid.dart';
import 'package:gymflow/src/core/providers/personal_best_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/exercise_thumbnail.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';
import 'package:gymflow/src/ui/widgets/live_metrics_panel.dart';
import 'package:gymflow/src/ui/widgets/set_editor_sheet.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/screens/workout_summary_screen.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate workout;
  final String? scheduledWorkoutId;

  const ActiveSessionScreen({
    super.key,
    required this.workout,
    this.scheduledWorkoutId,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
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

    // Initialize with template values
    _sessionExercises = widget.workout.exercises.map((e) {
      return WorkoutExercise(
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        type: e.type,
        sets: List.generate(e.targetSets, (index) {
          // Parse target reps (handle "8-12" => 8)
          int startReps = 0;
          final repsStr = e.targetReps.replaceAll(
            RegExp(r'[^0-9-]'),
            '',
          ); // remove non-numeric except dash
          if (repsStr.contains('-')) {
            startReps = int.tryParse(repsStr.split('-')[0]) ?? 0;
          } else {
            startReps = int.tryParse(repsStr) ?? 0;
          }

          return WorkoutSet(
            weight: e.targetWeight ?? 0,
            reps: startReps,
            distance: e.targetDistance,
            durationSeconds: e.targetDurationSeconds,
          );
        }),
        notes: e.notes,
      );
    }).toList();

    // Try to load last session data
    _loadLastSessionData();
  }

  Future<void> _loadLastSessionData() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final lastSession = await FirestoreService().getLastSession(
      user.uid,
      widget.workout.id,
    );

    if (lastSession != null && mounted) {
      setState(() {
        for (var i = 0; i < _sessionExercises.length; i++) {
          final currentEx = _sessionExercises[i];
          // Find matching exercise in last session
          final lastEx = lastSession.exercises.firstWhere(
            (e) => e.exerciseId == currentEx.exerciseId,
            orElse: () =>
                WorkoutExercise(exerciseId: '', exerciseName: '', sets: []),
          );

          if (lastEx.sets.isNotEmpty) {
            // Update weights/reps but keep isCompleted false
            // We try to match set counts, or take the last set's weight if we have more sets now
            for (var j = 0; j < currentEx.sets.length; j++) {
              if (j < lastEx.sets.length) {
                currentEx.sets[j].weight = lastEx.sets[j].weight;
                currentEx.sets[j].reps = lastEx.sets[j].reps;
              } else {
                // If we have more sets now, use the last set's weight of prev session
                currentEx.sets[j].weight = lastEx.sets.last.weight;
                currentEx.sets[j].reps = lastEx.sets.last.reps;
              }
            }
          }
        }
      });

      final loc = ref.read(localizationNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('weights_loaded_msg')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    final loc = ref.read(localizationNotifierProvider);

    // Ask user for date/time
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('finish_workout_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.t('finish_workout_body')),
            const SizedBox(height: 16),
            ListTile(
              title: Text(loc.t('date_label')),
              subtitle: Text(selectedDate!.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate!,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  selectedDate = picked;
                  // Force rebuild of dialog? No, simple way: close and reopen or use StatefulBuilder.
                  // For simplicity in this iteration, we just use current date if not complex.
                  // Correct approach: Use StatefulBuilder inside Dialog.
                  // But to keep it simple, let's just use the current time logic or build a smarter dialog.
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('save')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show date picker to confirm/change date
    // Actually, let's just show the picker directly if they want to "Backdate" vs "Save Now"
    // Better UX: Show ActionSheet: "Finish Now" or "Choose Date"

    // final action = await showModalBottomSheet<String>(...);
    // This is getting complex. Let's simplify:
    // Just show a DateTime picker if they long-press "FINISH"? No, discovery issue.

    // Let's go with a simple date picker dialog step.
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: loc.t('confirm_date'),
    );

    if (pickedDate == null) return; // User cancelled

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: loc.t('confirm_end_time'),
    );

    if (pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Calculate start time based on duration (duration matches expected stopwatch)
    final startTime = finalDateTime.subtract(_stopwatch.elapsed);

    setState(() => _isSaving = true);

    final session = WorkoutSession(
      id: const Uuid().v4(),
      userId: user.uid,
      workoutTemplateId: widget.workout.id,
      workoutName: widget.workout.name,
      startTime: startTime,
      endTime: finalDateTime,
      exercises: _sessionExercises,
      workoutType: widget.workout.category.name,
    );

    // Fire and forget save
    final service = FirestoreService();
    await service.saveSession(session);

    // If this was a scheduled workout, remove the schedule now that it's done
    if (widget.scheduledWorkoutId != null) {
      await service.deleteScheduledWorkout(widget.scheduledWorkoutId!);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WorkoutSummaryScreen(session: session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expressive = context.expressive;
    final loc = ref.watch(localizationNotifierProvider);

    // Tiene vivi i massimi storici per tutta la durata della schermata.
    // `personalBestsProvider` e autoDispose e legge le sessioni da uno stream
    // di Isar: la sola `ref.read` all'apertura del foglio della serie lo
    // creerebbe da freddo e otterrebbe una mappa vuota, perche lo stream non ha
    // ancora emetto. Funzionerebbe soltanto per il caso fortunato in cui la
    // dashboard, restando montata sotto, lo tiene gia caldo.
    ref.watch(personalBestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workout.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  child: Text(
                    loc.t('finish_btn'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      // Il pannello sta in fondo e fuori dalla lista, non ne e il primo
      // elemento: dentro il ListView verrebbe smontato scorrendo, e con lui
      // morirebbe il provider autoDispose che tiene la finestra recente delle
      // sparkline. Ancorato qui riserva la propria altezza, quindi non copre
      // mai l'ultimo esercizio: un pannello sovrapposto renderebbe irrag-
      // giungibile il suo pulsante «Add Set». La sovrapposizione alla foto
      // dell'esercizio del mockup arriva con la foto stessa, in US-062.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(expressive.spacing.sm),
          child: LiveMetricsPanel(formattedTime: _formattedTime),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(
          left: expressive.spacing.sm,
          right: expressive.spacing.sm,
          top: expressive.spacing.sm,
          bottom: expressive.spacing.md,
        ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ExerciseThumbnailById(
                        exerciseId: exercise.exerciseId,
                        exerciseName: exercise.exerciseName,
                        // Il foglio non smonta questa schermata: alla chiusura
                        // la sessione e dov'era e il cronometro non ha smesso.
                        onTap: (resolved) =>
                            ExerciseVideoSheet.show(context, resolved),
                      ),
                      SizedBox(width: context.expressive.spacing.md),
                      Expanded(
                        child: Text(
                          exercise.exerciseName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          // Confirm deletion
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(loc.t('remove_exercise_title')),
                              content: Text(
                                loc.t('remove_exercise_body'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(loc.t('cancel')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _sessionExercises.removeAt(index);
                                    });
                                  },
                                  child: Text(
                                    loc.t('remove_btn'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Dynamic Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: _buildExerciseTable(exercise, context, loc),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(loc.t('add_set')),
                    onPressed: () {
                      setState(() {
                        // Add set with appropriate defaults based on type?
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

  // Helper to build the table based on type
  Widget _buildExerciseTable(
    WorkoutExercise exercise,
    BuildContext context,
    Localization loc,
  ) {
    switch (exercise.type) {
      case ExerciseType.cardio:
        return _buildCardioTable(exercise, loc);
      case ExerciseType.timed:
      case ExerciseType.isometric:
        return _buildDurationTable(exercise, loc);
      case ExerciseType.bodyweight:
        return _buildStrengthTable(exercise, loc, showWeight: false);
      case ExerciseType.strength:
      default:
        return _buildStrengthTable(exercise, loc, showWeight: true);
    }
  }

  Widget _buildStrengthTable(
    WorkoutExercise exercise,
    Localization loc, {
    required bool showWeight,
  }) {
    return Table(
      columnWidths: {
        0: const FlexColumnWidth(1), // Set #
        if (showWeight) 1: const FlexColumnWidth(2), // Weight
        2: const FlexColumnWidth(2), // Reps
        3: const FlexColumnWidth(1), // Check
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const Center(
              child: Text('#', style: TextStyle(color: Colors.grey)),
            ),
            if (showWeight)
              const Center(
                child: Text('Kg', style: TextStyle(color: Colors.grey)),
              ),
            Center(
              child: Text(loc.t('reps_label'), style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(),
          ],
        ),
        ...exercise.sets.asMap().entries.map((entry) {
          final setIndex = entry.key;
          final set = entry.value;
          return TableRow(
            children: [
              Center(child: Text('${setIndex + 1}')),
              // I tre valori si impostano nel foglio, con i cursori: con le
              // mani sudate fra due serie, tre campi numerici larghi poche
              // decine di pixel costavano piu tempo di quanto ne facessero
              // risparmiare (US-046).
              if (showWeight)
                _SetValueCell(
                  text: _formatWeight(set.weight),
                  onTap: () => _editSet(exercise, setIndex, showWeight: true),
                ),
              _SetValueCell(
                text: '${set.reps}',
                onTap: () => _editSet(exercise, setIndex, showWeight: showWeight),
              ),
              Checkbox(
                value: set.isCompleted,
                onChanged: (val) =>
                    setState(() => set.isCompleted = val ?? false),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static String _formatWeight(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }

  /// Apre il foglio dei cursori per una serie.
  ///
  /// Il valore di partenza viene dalla serie precedente **dello stesso
  /// esercizio in questa sessione**: e l'informazione piu vicina a quella che
  /// il criterio chiede, e non richiede di leggere lo storico.
  Future<void> _editSet(
    WorkoutExercise exercise,
    int setIndex, {
    required bool showWeight,
  }) async {
    final set = exercise.sets[setIndex];
    final personalBests = ref.read(personalBestsProvider);
    final personalBest = personalBests[exercise.exerciseId];
    final result = await SetEditorSheet.show(
      context,
      set: set,
      setNumber: setIndex + 1,
      exerciseName: exercise.exerciseName,
      exerciseId: exercise.exerciseId,
      personalBest: personalBest,
      previous: setIndex > 0 ? exercise.sets[setIndex - 1] : null,
      showWeight: showWeight,
    );
    if (result == null) return;

    setState(() {
      set.weight = result.weight;
      set.reps = result.reps;
      set.rpe = result.rpe;
    });
  }

  Widget _buildCardioTable(WorkoutExercise exercise, Localization loc) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2), // Distance
        2: FlexColumnWidth(2), // Time
        3: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const Center(
              child: Text('#', style: TextStyle(color: Colors.grey)),
            ),
            const Center(
              child: Text('Km', style: TextStyle(color: Colors.grey)),
            ),
            Center(
              child: Text(loc.t('time_min_label'), style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(),
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
                  initialValue: (set.distance ?? 0).toString(),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0',
                  ),
                  onChanged: (val) => set.distance =
                      double.tryParse(val.replaceAll(',', '.')) ?? 0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  // We might store seconds but show minutes for edit
                  initialValue: ((set.durationSeconds ?? 0) / 60)
                      .toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0',
                  ),
                  onChanged: (val) {
                    final min = int.tryParse(val) ?? 0;
                    set.durationSeconds = min * 60;
                  },
                ),
              ),
              Checkbox(
                value: set.isCompleted,
                onChanged: (val) =>
                    setState(() => set.isCompleted = val ?? false),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDurationTable(WorkoutExercise exercise, Localization loc) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(3), // Time
        2: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const Center(
              child: Text('#', style: TextStyle(color: Colors.grey)),
            ),
            Center(
              child: Text(
                loc.t('duration_sec_label'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: (set.durationSeconds ?? 0).toString(),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          suffixText: 's',
                        ),
                        onChanged: (val) =>
                            set.durationSeconds = int.tryParse(val) ?? 0,
                      ),
                    ),
                    // Optional Timer Button?
                    IconButton(
                      icon: const Icon(
                        Icons.timer_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        // Start a mini timer? For now just visual.
                        ToastUtils.showInfo(
                          context,
                          loc.t('timer_started_msg'),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: set.isCompleted,
                onChanged: (val) =>
                    setState(() => set.isCompleted = val ?? false),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

/// Un valore della serie in tabella: si legge, e toccandolo si apre il foglio.
///
/// Non e piu un campo di testo, ma resta alto quanto serve a essere toccato
/// senza mirare.
class _SetValueCell extends StatelessWidget {
  const _SetValueCell({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    return InkWell(
      onTap: onTap,
      borderRadius: t.shape.cornerSm,
      child: Container(
        height: t.sizing.minTouchTarget,
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: t.spacing.xs),
        child: Text(text, style: t.typography.metricSmall),
      ),
    );
  }
}
