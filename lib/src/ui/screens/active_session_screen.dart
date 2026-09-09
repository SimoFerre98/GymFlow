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
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/ui/widgets/exercise_image.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';
import 'package:gymflow/src/ui/widgets/live_metrics_panel.dart';
import 'package:gymflow/src/ui/widgets/set_editor_sheet.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/screens/workout_summary_screen.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/core/providers/timer_settings_provider.dart';
import 'package:gymflow/src/core/providers/active_session_provider.dart';
const double _kTitleFontSize = 22;
/// Avvia il conto alla rovescia sui secondi di una serie a tempo.
///
/// Restituisce `true` se il timer e partito. Chi chiama mostra la conferma solo
/// in quel caso.
///
/// **Sta fuori dalla schermata perche la schermata non si monta in un test**:
/// istanzia `FirestoreService` nel proprio `State`, che e il debito di US-008.
/// Lasciata dentro `onPressed`, questa logica poteva essere provata solo
/// riscrivendola nel test — e un test che riscrive cio che deve controllare non
/// controlla niente: resta verde qualunque cosa succeda al pulsante.
///
/// Le due decisioni che il piano chiedeva di prendere e dichiarare:
///
/// - **Secondi assenti o a zero: non parte niente, e in silenzio.** Il campo
///   accanto non ricostruisce la riga quando cambia (`onChanged` scrive nel
///   modello senza `setState`), quindi un pulsante disattivato mostrerebbe lo
///   stato di prima invece di quello vero: meglio nessuna reazione di una
///   reazione sbagliata.
/// - **Timer gia in corsa: si lascia scorrere.** E la protezione voluta di
///   `setTimerDuration`, che rifiuta di cambiare durata mentre il tempo scorre:
///   qui viene rispettata, non aggirata. Un timer **in pausa** invece non e in
///   corsa, e viene sostituito da questa serie.
bool startSetTimer(TimerNotifier notifier, int? seconds) {
  if (seconds == null || seconds <= 0) return false;
  if (notifier.isTimerRunning) return false;
  notifier.setTimerDuration(Duration(seconds: seconds));
  notifier.toggleTimer();
  return true;
}
/// Come si chiude un allenamento: adesso, in un altro momento, o non si chiude.
enum _FineAllenamento { adesso, altraData, annulla }
enum _ExitAction { discard, keepActive }
/// Un esercizio e finito quando **tutte** le sue serie sono spuntate.
///
/// Un esercizio senza serie non e finito: non e stato fatto niente, e mostrarlo
/// come concluso sarebbe una bugia comoda.
///
/// Sta fuori dalla schermata perche `ActiveSessionScreen` non si monta in un
/// test — istanzia `FirestoreService` nel proprio `State`, che e il debito di
/// US-008 — e una regola che decide cosa l'utente vede segnato come fatto merita
/// di essere provata davvero.
bool esercizioFinito(WorkoutExercise esercizio) {
  if (esercizio.sets.isEmpty) return false;
  return esercizio.sets.every((serie) => serie.isCompleted);
}
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
  late Timer _timer;
  String _formattedTime = "00:00:00";
  // We clone the exercises to track progress without modifying the template immediately
  // Ideally, use a deep copy or map to a new Session object state
  late List<WorkoutExercise> _sessionExercises;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeSessionNotifierProvider.notifier).startOrResumeSession(
            widget.workout,
            scheduledWorkoutId: widget.scheduledWorkoutId,
          );
      final sessionState = ref.read(activeSessionNotifierProvider);
      if (mounted) {
        setState(() {
          _sessionExercises = sessionState.sessionExercises;
          _updateElapsedDisplay();
        });
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateElapsedDisplay();
      }
    });
    // Initialize with template values as fallback before post frame
    _sessionExercises = widget.workout.exercises.map((e) {
      return WorkoutExercise(
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        type: e.type,
        sets: e.plannedSets.map((planned) {
          final startReps = planned.kind == PlannedSetKind.toFailure
              ? 10
              : (planned.reps ?? 10);
          final rawWeight = planned.weight ?? e.targetWeight ?? 0.0;
          // Strada A: perSide raddoppia il peso alla nascita della sessione
          final effectiveWeight =
              planned.perSide ? rawWeight * 2.0 : rawWeight;
          return WorkoutSet(
            weight: effectiveWeight,
            reps: startReps,
            distance: e.targetDistance,
            durationSeconds: e.targetDurationSeconds,
          );
        }).toList(),
        notes: e.notes,
      );
    }).toList();
    // Try to load last session data
    _loadLastSessionData();
  }
  void _updateElapsedDisplay() {
    final activeSession = ref.read(activeSessionNotifierProvider);
    final elapsed = activeSession.elapsedDuration;
    setState(() {
      _formattedTime = _formatTime(elapsed.inMilliseconds);
    });
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
    // Una domanda sola, e la risposta piu probabile e gia pronta.
    //
    // Prima erano tre: un dialogo con un selettore di data che **non faceva
    // niente** — il commento nel codice lo ammetteva, il valore scelto veniva
    // scartato perche il dialogo non si ricostruiva — poi un secondo selettore
    // di data, poi uno dell'ora. L'utente rispondeva due volte alla stessa
    // domanda prima di vedere il riepilogo, e l'ora finiva in una variabile
    // che nessuno leggeva (uno dei diciassette avvisi dell'analyzer).
    //
    // Adesso: l'allenamento finisce **adesso**, che e il caso di gran lunga
    // piu frequente e si deduce senza chiedere. Chi sta registrando un
    // allenamento di ieri tocca «altra data» e allora — e solo allora — gli
    // vengono chiesti data e ora, una volta ciascuna.
    final scelta = await showDialog<_FineAllenamento>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('finish_workout_title')),
        content: Text(loc.t('finish_workout_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _FineAllenamento.annulla),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _FineAllenamento.altraData),
            child: Text(loc.t('finish_other_date')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _FineAllenamento.adesso),
            child: Text(loc.t('finish_now')),
          ),
        ],
      ),
    );
    if (scelta == null || scelta == _FineAllenamento.annulla) return;
    DateTime finalDateTime = DateTime.now();
    if (scelta == _FineAllenamento.altraData) {
      if (!mounted) return;
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        helpText: loc.t('confirm_date'),
      );
      if (pickedDate == null) return;
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        helpText: loc.t('confirm_end_time'),
      );
      if (pickedTime == null) return;
      finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }
    final activeSession = ref.read(activeSessionNotifierProvider);
    final elapsed = activeSession.elapsedDuration;
    final startTime = finalDateTime.subtract(elapsed);
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
    try {
      final service = FirestoreService();
      await service.saveSession(session);
      // If this was a scheduled workout, remove the schedule now that it's done
      if (widget.scheduledWorkoutId != null) {
        await service.deleteScheduledWorkout(widget.scheduledWorkoutId!);
      }
    } finally {
      ref.read(activeSessionNotifierProvider.notifier).endSession();
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WorkoutSummaryScreen(session: session),
        ),
      );
    }
  }
  Future<void> _confirmExitSession(BuildContext context) async {
    final loc = ref.read(localizationNotifierProvider);
    final navigator = Navigator.of(context);
    final action = await showDialog<_ExitAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('workout_in_progress_title')),
        content: Text(loc.t('workout_in_progress_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.discard),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.t('discard_workout')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.keepActive),
            child: Text(loc.t('keep_in_background')),
          ),
        ],
      ),
    );
    if (action == _ExitAction.discard) {
      ref.read(activeSessionNotifierProvider.notifier).endSession();
      navigator.pop();
    } else if (action == _ExitAction.keepActive) {
      navigator.pop();
    }
  }
  @override
  Widget build(BuildContext context) {
    final expressive = context.immersivo;
    final loc = ref.watch(localizationNotifierProvider);
    // Tiene vivi i massimi storici per tutta la durata della schermata.
    // `personalBestsProvider` e autoDispose e legge le sessioni da uno stream
    // di Isar: la sola `ref.read` all'apertura del foglio della serie lo
    // creerebbe da freddo e otterrebbe una mappa vuota, perche lo stream non ha
    // ancora emetto. Funzionerebbe soltanto per il caso fortunato in cui la
    // dashboard, restando montata sotto, lo tiene gia caldo.
    ref.watch(personalBestsProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmExitSession(context);
        }
      },
      child: Scaffold(
        // Il pannello sta in fondo e fuori dalla lista, non ne e il primo
        // elemento: dentro il ListView verrebbe smontato scorrendo, e con lui
        // morirebbe il provider autoDispose che tiene la finestra recente delle
        // sparkline. Ancorato qui riserva la propria altezza, quindi non copre
        // mai l'ultimo esercizio.
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(expressive.spacing.sm),
            child: LiveMetricsPanel(formattedTime: _formattedTime),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  expressive.spacing.md,
                  expressive.spacing.sm,
                  expressive.spacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    BackPill(
                      label: loc.t('cancel'),
                      onTap: () => _confirmExitSession(context),
                    ),
                    SizedBox(width: expressive.spacing.md),
                    Expanded(
                      child: Text(
                        widget.workout.name.toUpperCase(),
                        style: expressive.typography.headline?.copyWith(
                          fontSize: _kTitleFontSize,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: expressive.spacing.md),
                    _isSaving
                        ? SizedBox(
                            width: expressive.sizing.iconMd,
                            height: expressive.sizing.iconMd,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onSurface,
                              strokeWidth: 2,
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
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    left: expressive.spacing.sm,
                    right: expressive.spacing.sm,
                    top: expressive.spacing.sm,
                    bottom: expressive.spacing.md,
                  ),
                  itemCount: _sessionExercises.length,
                  itemBuilder: (context, index) {
            final exercise = _sessionExercises[index];
            return Padding(
              padding: EdgeInsets.all(expressive.spacing.sm),
              child: _ExerciseSessionCard(
                exercise: exercise,
                index: index,
                total: _sessionExercises.length,
                finito: esercizioFinito(exercise),
                onTapPhoto: (resolved) =>
                    ExerciseVideoSheet.show(context, resolved),
                onDelete: () => _confirmRemove(context, loc, index),
                onAddSet: () => setState(() {
                  exercise.sets.add(WorkoutSet(weight: 0, reps: 0));
                }),
                onSetTap: (setIndex) =>
                    _openSetEditor(exercise, setIndex),
                onSetToggled: (set, value) =>
                    _onSetCompleted(exercise, set, value),
                onStartSetTimer: (seconds) {
                  final avviato = startSetTimer(
                    ref.read(timerNotifierProvider.notifier),
                    seconds,
                  );
                  if (!avviato) return;
                  ToastUtils.showInfo(context, loc.t('timer_started_msg'));
                },
                loc: loc,
              ),
            );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _confirmRemove(BuildContext context, Localization loc, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('remove_exercise_title')),
        content: Text(loc.t('remove_exercise_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _sessionExercises.removeAt(index));
            },
            child: Text(
              loc.t('remove_btn'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
  void _onSetCompleted(
    WorkoutExercise exercise,
    WorkoutSet set,
    bool isCompleted,
  ) {
    setState(() => set.isCompleted = isCompleted);
    if (!isCompleted) return;
    final timerSettings = ref.read(timerSettingsNotifierProvider);
    if (!timerSettings.autoRestEnabled) return;
    WorkoutTemplateExercise? templateExercise;
    for (final e in widget.workout.exercises) {
      if (e.exerciseId == exercise.exerciseId) {
        templateExercise = e;
        break;
      }
    }
    int? perSetRest;
    final currentSetIndex = exercise.sets.indexOf(set);
    if (currentSetIndex >= 0 &&
        templateExercise != null &&
        currentSetIndex < templateExercise.plannedSets.length) {
      perSetRest = templateExercise.plannedSets[currentSetIndex].restSeconds;
    }
    final restSeconds = perSetRest ??
        ((templateExercise?.restSeconds != null &&
                templateExercise!.restSeconds! > 0)
            ? templateExercise.restSeconds!
            : timerSettings.restSecondsForReps(set.reps));
    if (restSeconds > 0) {
      final timerNotifier = ref.read(timerNotifierProvider.notifier);
      timerNotifier.startTimerWithDuration(Duration(seconds: restSeconds));
    }
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
  /// Il riquadro della serie apre l'editor giusto per il tipo di esercizio.
  ///
  /// `SetEditorSheet` sa solo di peso/ripetizioni/sforzo: cardio e le serie a
  /// tempo hanno campi che non gli appartengono (distanza, durata), ed erano
  /// editabili in linea nella tabella di prima. Qui restano editabili allo
  /// stesso modo, in un dialogo invece che in una cella — il riquadro del
  /// mockup e troppo piccolo per un campo di testo dentro.
  Future<void> _openSetEditor(WorkoutExercise exercise, int setIndex) {
    switch (exercise.type) {
      case ExerciseType.cardio:
        return _editCardioSet(exercise, setIndex);
      case ExerciseType.timed:
      case ExerciseType.isometric:
        return _editDurationSet(exercise, setIndex);
      case ExerciseType.bodyweight:
        return _editSet(exercise, setIndex, showWeight: false);
      case ExerciseType.strength:
        return _editSet(exercise, setIndex, showWeight: true);
    }
  }
  Future<void> _editCardioSet(WorkoutExercise exercise, int setIndex) async {
    final set = exercise.sets[setIndex];
    final loc = ref.read(localizationNotifierProvider);
    final distanceController = TextEditingController(
      text: (set.distance ?? 0).toString(),
    );
    final minutesController = TextEditingController(
      text: ((set.durationSeconds ?? 0) / 60).toStringAsFixed(0),
    );
    final salvato = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${loc.t('exercise_label_short')} ${setIndex + 1}'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Km'),
              ),
            ),
            SizedBox(width: context.immersivo.spacing.md),
            Expanded(
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.t('time_min_label')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('save')),
          ),
        ],
      ),
    );
    distanceController.dispose();
    minutesController.dispose();
    if (salvato != true) return;
    setState(() {
      set.distance =
          double.tryParse(distanceController.text.replaceAll(',', '.')) ?? 0;
      set.durationSeconds =
          (int.tryParse(minutesController.text) ?? 0) * 60;
    });
  }
  Future<void> _editDurationSet(WorkoutExercise exercise, int setIndex) async {
    final set = exercise.sets[setIndex];
    final loc = ref.read(localizationNotifierProvider);
    final secondsController = TextEditingController(
      text: (set.durationSeconds ?? 0).toString(),
    );
    final salvato = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${loc.t('exercise_label_short')} ${setIndex + 1}'),
        content: TextField(
          controller: secondsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: loc.t('duration_sec_label')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('save')),
          ),
        ],
      ),
    );
    secondsController.dispose();
    if (salvato != true) return;
    setState(() {
      set.durationSeconds = int.tryParse(secondsController.text) ?? 0;
    });
  }
}
/// Formatta un peso come lo fa il resto dell'app: intero se e intero, una
/// cifra decimale altrimenti, virgola invece di punto.
/// 26 — misura del titolo dell'esercizio in testata: fra le voci di
/// `typography.headline` non ce n'e una che stia bene sopra una foto larga
/// quanto la card, ne troppo grande ne troppo piccola.
const double _kExerciseTitleFontSize = 26;
String _formatWeight(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}
/// Il valore mostrato in un riquadro serie, secondo il tipo di esercizio —
/// stessa logica di dispaccio di prima (`_buildExerciseTable`), letta qui
/// perche il riquadro del mockup e uno solo, non piu una tabella diversa per
/// tipo.
String _valoreSerie(ExerciseType type, WorkoutSet set, {required bool showWeight}) {
  switch (type) {
    case ExerciseType.cardio:
      final km = (set.distance ?? 0).toStringAsFixed(1).replaceAll('.', ',');
      final min = ((set.durationSeconds ?? 0) / 60).toStringAsFixed(0);
      return '$km km · $min\'';
    case ExerciseType.timed:
    case ExerciseType.isometric:
      return '${set.durationSeconds ?? 0}s';
    case ExerciseType.bodyweight:
      return '${set.reps}';
    case ExerciseType.strength:
      return showWeight
          ? '${_formatWeight(set.weight)}×${set.reps}'
          : '${set.reps}';
  }
}
/// L'esercizio dentro la sessione, nel linguaggio del mockup 1d: foto in
/// testata che sfuma nel fondo, eyebrow "SERIE completate/totali", un
/// riquadro per serie (fatta/ora/da fare) invece della tabella di prima.
///
/// Resta una lista di **tutti** gli esercizi, modificabile liberamente — il
/// mockup ne mostra uno alla volta, ma qui si e scelto di non perdere la
/// visione d'insieme dell'allenamento: solo il linguaggio visivo cambia.
class _ExerciseSessionCard extends ConsumerWidget {
  const _ExerciseSessionCard({
    required this.exercise,
    required this.index,
    required this.total,
    required this.finito,
    required this.onTapPhoto,
    required this.onDelete,
    required this.onAddSet,
    required this.onSetTap,
    required this.onSetToggled,
    required this.onStartSetTimer,
    required this.loc,
  });
  final WorkoutExercise exercise;
  final int index;
  final int total;
  final bool finito;
  final void Function(Exercise resolved) onTapPhoto;
  final VoidCallback onDelete;
  final VoidCallback onAddSet;
  final void Function(int setIndex) onSetTap;
  final void Function(WorkoutSet set, bool value) onSetToggled;
  final void Function(int? seconds) onStartSetTimer;
  final Localization loc;
  static const double _kHeroHeight = 150;
  bool get _showWeight => exercise.type == ExerciseType.strength;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final resolved = ref.watch(
      exerciseIndexProvider.select((idx) => idx[exercise.exerciseId]),
    );
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _kHeroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (resolved != null)
                  GestureDetector(
                    onTap: () => onTapPhoto(resolved),
                    child: ExerciseImage(
                      exercise: resolved,
                      size: ExerciseImageSize.hero,
                    ),
                  )
                else
                  Container(color: scheme.surfaceContainer),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surfaceContainerLowest.withValues(alpha: 0.15),
                        scheme.surfaceContainerLowest.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: t.spacing.md,
                  right: t.spacing.md,
                  bottom: t.spacing.sm,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${loc.t('exercise_label_short')} ${index + 1} / $total',
                              style: t.typography.eyebrow?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                            Text(
                              exercise.exerciseName.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.typography.headline?.copyWith(
                                fontSize: _kExerciseTitleFontSize,
                                color: scheme.onSurface,
                                decoration: finito
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (finito)
                        Icon(
                          Icons.check_circle,
                          color: scheme.onSurfaceVariant,
                          semanticLabel: loc.t('exercise_done'),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: t.spacing.sm,
                  right: t.spacing.sm,
                  child: InkWell(
                    onTap: onDelete,
                    child: Container(
                      width: t.sizing.iconLg + t.spacing.xs,
                      height: t.sizing.iconLg + t.spacing.xs,
                      alignment: Alignment.center,
                      color: scheme.surfaceContainerLowest.withValues(
                        alpha: 0.7,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: t.sizing.iconMd,
                        color: scheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.t('sets_label').toUpperCase(), style: t.typography.eyebrow),
                    Text(
                      '${exercise.sets.where((s) => s.isCompleted).length} / '
                          '${exercise.sets.length}',
                      style: t.typography.eyebrow,
                    ),
                  ],
                ),
                SizedBox(height: t.spacing.sm),
                Wrap(
                  spacing: t.spacing.sm,
                  runSpacing: t.spacing.sm,
                  children: [
                    for (var i = 0; i < exercise.sets.length; i++)
                      _SetBox(
                        setNumber: i + 1,
                        set: exercise.sets[i],
                        value: _valoreSerie(
                          exercise.type,
                          exercise.sets[i],
                          showWeight: _showWeight,
                        ),
                        loc: loc,
                        onTap: () => onSetTap(i),
                        onToggle: (value) =>
                            onSetToggled(exercise.sets[i], value),
                        onStartTimer:
                            exercise.type == ExerciseType.timed ||
                                    exercise.type == ExerciseType.isometric
                                ? () => onStartSetTimer(
                                      exercise.sets[i].durationSeconds,
                                    )
                                : null,
                      ),
                  ],
                ),
                SizedBox(height: t.spacing.xs),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(loc.t('add_set')),
                  onPressed: onAddSet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
/// Un riquadro serie: fatta (bordo verde bosco), in corso (fondo pieno
/// accento), da fare (bordo tratteggiato) — mockup 1d Sessione attiva.
/// Toccarlo apre il foglio dei cursori; il segno di spunta in un angolo
/// segna la serie come fatta senza aprire nient'altro.
class _SetBox extends StatelessWidget {
  const _SetBox({
    required this.setNumber,
    required this.set,
    required this.value,
    required this.loc,
    required this.onTap,
    required this.onToggle,
    this.onStartTimer,
  });
  final int setNumber;
  final WorkoutSet set;
  final String value;
  final Localization loc;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onStartTimer;
  static const double _kBoxWidth = 78;
  static const double _kBoxHeight = 56;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final done = set.isCompleted;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: _kBoxWidth,
        height: _kBoxHeight,
        padding: EdgeInsets.symmetric(horizontal: t.spacing.xs),
        decoration: BoxDecoration(
          color: done ? scheme.primary : null,
          border: done
              ? null
              : Border.all(
                  color: scheme.outline,
                  style: BorderStyle.solid,
                ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? loc.t('set_done_label') : '$setNumber',
                  style: t.typography.eyebrow?.copyWith(
                    color: done
                        ? scheme.onPrimary
                        : scheme.tertiary,
                  ),
                ),
                Text(
                  value,
                  style: t.typography.metricSmall?.copyWith(
                    color: done ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: InkWell(
                onTap: () => onToggle(!done),
                child: Padding(
                  padding: EdgeInsets.all(t.spacing.xs / 2),
                  child: Icon(
                    done ? Icons.check_circle : Icons.check_circle_outline,
                    size: t.sizing.iconSm,
                    color: done
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (onStartTimer != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: onStartTimer,
                  child: Padding(
                    padding: EdgeInsets.all(t.spacing.xs / 2),
                    child: Icon(
                      Icons.timer_outlined,
                      size: t.sizing.iconSm,
                      color: done ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
