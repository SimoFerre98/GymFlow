import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/exercise_detail_screen.dart';
import 'package:gymflow/src/ui/widgets/exercise_row.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';

/// Cosa mostrare al posto della lista, se qualcosa.
enum ExerciseLibraryView { loading, empty, list }

/// Opzioni del segmentato in cima alla libreria.
enum ExerciseSegmentFilter { all, mine, recent }

/// Decide fra girella, messaggio di lista vuota e lista.
///
/// Sta fuori dal widget per una ragione precisa: la schermata istanzia
/// `FirestoreService` nel proprio `State` — debito di US-008 — e quindi non si
/// monta in un test. Con la decisione qui, il caso che conta si prova sul codice
/// vero invece che su una copia.
///
/// Il caso che conta e il primo: **`isLoading` da solo non basta**. Un
/// `AsyncValue` che ricarica avendo gia un valore ha `isLoading` vero, e
/// mostrargli la girella sostituisce la lista intera per un istante. Succedeva a
/// ogni emissione dello stream Firestore che `exercisesProvider` osserva — due
/// volte all'apertura, cache e server — ed e da li che veniva lo sfarfallio.
ExerciseLibraryView exerciseLibraryViewFor(AsyncValue<List<Exercise>> snapshot) {
  if (snapshot.isLoading && !snapshot.hasValue) {
    return ExerciseLibraryView.loading;
  }
  if (!snapshot.hasValue || snapshot.value!.isEmpty) {
    return ExerciseLibraryView.empty;
  }
  return ExerciseLibraryView.list;
}

/// Esito del tentativo di aggiunta di un esercizio personalizzato.
enum AddExerciseOutcome {
  success,
  validationError,
  saveError,
}

/// Risultato dell'operazione di salvataggio dell'esercizio.
class AddExerciseResult {
  final AddExerciseOutcome outcome;
  final String? errorKey;
  final bool shouldCloseDialog;

  const AddExerciseResult.success()
      : outcome = AddExerciseOutcome.success,
        errorKey = null,
        shouldCloseDialog = true;

  const AddExerciseResult.validationError(this.errorKey)
      : outcome = AddExerciseOutcome.validationError,
        shouldCloseDialog = false;

  const AddExerciseResult.saveError(this.errorKey)
      : outcome = AddExerciseOutcome.saveError,
        shouldCloseDialog = false;
}

/// Gestisce la validazione e il salvataggio di un nuovo esercizio personalizzato.
///
/// Questa funzione e estratta per consentire il test unitario della logica di
/// salvataggio e gestione errori, dato che [ExerciseLibraryScreen] non e montabile nei test.
Future<AddExerciseResult> handleAddExerciseSubmit({
  required String rawName,
  required ExerciseType type,
  required String? userId,
  required Future<void> Function(Exercise exercise) saveExercise,
}) async {
  final name = rawName.trim();
  if (name.isEmpty) {
    return const AddExerciseResult.validationError('add_exercise_name_empty');
  }

  try {
    final exercise = Exercise(
      id: '',
      userId: userId,
      name: name,
      description: 'Custom exercise',
      type: type,
      musclesTargeted: const [],
      isCustom: true,
    );
    await saveExercise(exercise);
    return const AddExerciseResult.success();
  } catch (e) {
    // All'utente va un messaggio comprensibile, ma il dettaglio tecnico deve
    // restare nel log: questa storia nasce da un `permission-denied` che per
    // sei mesi nessuno ha collegato ai sintomi, e il primo controllo quando un
    // dato non arriva e `adb logcat`.
    debugPrint('Errore nel salvataggio dell\'esercizio: $e');
    return const AddExerciseResult.saveError('add_exercise_error_saving');
  }
}

/// Estrae i gruppi muscolari dagli esercizi caricati, ordinati per frequenza.
///
/// Raccoglie `musclesTargeted` di tutti gli esercizi e restituisce i piu
/// frequenti in ordine decrescente (e in ordine alfabetico a parita di frequenza).
List<String> extractMuscleGroups(List<Exercise> exercises) {
  final counts = <String, int>{};
  for (final exercise in exercises) {
    for (final muscle in exercise.musclesTargeted) {
      final trimmed = muscle.trim();
      if (trimmed.isNotEmpty) {
        counts[trimmed] = (counts[trimmed] ?? 0) + 1;
      }
    }
  }
  final list = counts.keys.toList();
  list.sort((a, b) {
    final countA = counts[a]!;
    final countB = counts[b]!;
    if (countA != countB) {
      return countB.compareTo(countA);
    }
    return a.toLowerCase().compareTo(b.toLowerCase());
  });
  return list;
}

/// Filtra gli esercizi in base alla ricerca, al segmentato e al gruppo muscolare scelto.
List<Exercise> filterExercises({
  required List<Exercise> exercises,
  required String searchQuery,
  required ExerciseSegmentFilter segment,
  String? selectedMuscleGroup,
}) {
  final query = searchQuery.trim().toLowerCase();
  return exercises.where((e) {
    final matchesSearch =
        query.isEmpty || e.name.toLowerCase().contains(query);
    final matchesSegment = switch (segment) {
      ExerciseSegmentFilter.all => true,
      ExerciseSegmentFilter.mine => e.isCustom,
      ExerciseSegmentFilter.recent => false,
    };
    final matchesMuscle = selectedMuscleGroup == null ||
        selectedMuscleGroup.isEmpty ||
        e.musclesTargeted.any(
          (m) => m.toLowerCase() == selectedMuscleGroup.toLowerCase(),
        );

    return matchesSearch && matchesSegment && matchesMuscle;
  }).toList();
}

/// Costruisce la stringa di dettaglio per l'esercizio.
///
/// Esempio: "Petto · Tricipiti", "Petto alto · tuo", "senza video" oppure "Petto · tuo · senza video".
String buildExerciseSubtitleText(Exercise exercise, Localization loc) {
  final parts = <String>[];
  if (exercise.musclesTargeted.isNotEmpty) {
    parts.add(exercise.musclesTargeted.join(' · '));
  }
  if (exercise.isCustom) {
    parts.add(loc.t('exercise_tag_yours'));
  }
  if (!exercise.hasSpecificVideo) {
    parts.add(loc.t('exercise_tag_no_video'));
  }
  return parts.join(' · ');
}

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// Vero quando la schermata serve a **scegliere** un esercizio per qualcos
  /// altro: la creazione di una scheda. Falso quando la si consulta, che e il
  /// caso di chi arriva dal menu.
  final bool isSelecting;
  const ExerciseLibraryScreen({super.key, this.isSelecting = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  String _searchQuery = '';
  ExerciseSegmentFilter _selectedSegment = ExerciseSegmentFilter.all;
  String? _selectedMuscleGroup;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = ref.watch(localizationNotifierProvider);
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    final snapshot = ref.watch(exercisesProvider);
    final totalCount = snapshot.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.t('exercises_title')),
            SizedBox(width: t.spacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: t.spacing.sm,
                vertical: t.spacing.xs / 2,
              ),
              decoration: ShapeDecoration(
                color: scheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: t.shape.cornerFull,
                ),
              ),
              child: Text(
                '$totalCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.md,
              vertical: t.spacing.xs,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: loc.t('exercises_search_placeholder'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: t.shape.cornerMd,
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: t.spacing.md,
                  vertical: t.spacing.sm,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          SizedBox(height: t.spacing.xs),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
            child: Container(
              decoration: ShapeDecoration(
                color: scheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: t.shape.cornerFull,
                ),
              ),
              padding: EdgeInsets.all(t.spacing.xs),
              child: Row(
                children: ExerciseSegmentFilter.values.map((seg) {
                  final isSelected = _selectedSegment == seg;
                  final labelKey = switch (seg) {
                    ExerciseSegmentFilter.all => 'exercise_filter_all',
                    ExerciseSegmentFilter.mine => 'exercise_filter_mine',
                    ExerciseSegmentFilter.recent => 'exercise_filter_recent',
                  };
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedSegment = seg),
                      borderRadius: t.shape.cornerFull,
                      child: AnimatedContainer(
                        duration: t.motion.quick,
                        padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                        decoration: ShapeDecoration(
                          color: isSelected
                              ? scheme.primary
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: t.shape.cornerFull,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          loc.t(labelKey),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: t.spacing.xs),
          if (snapshot.hasValue && snapshot.value!.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final muscleGroups = extractMuscleGroups(snapshot.value!);
                if (muscleGroups.isEmpty) return const SizedBox.shrink();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: t.spacing.md,
                    vertical: t.spacing.xs,
                  ),
                  child: Row(
                    children: muscleGroups.map((group) {
                      final isSelected = _selectedMuscleGroup == group;
                      return Padding(
                        padding: EdgeInsets.only(right: t.spacing.sm),
                        child: FilterChip(
                          label: Text(group),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleGroup = selected ? group : null;
                            });
                          },
                          backgroundColor: scheme.surfaceContainerHigh,
                          selectedColor: scheme.primary,
                          checkmarkColor: scheme.onPrimary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: t.shape.cornerFull,
                            side: BorderSide(
                              color: isSelected
                                  ? scheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
          SizedBox(height: t.spacing.xs),
          Expanded(
            child: Builder(
              builder: (context) {
                final vista = exerciseLibraryViewFor(snapshot);

                if (vista == ExerciseLibraryView.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vista == ExerciseLibraryView.empty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(t.spacing.xl),
                      child: Text(
                        loc.t('exercises_empty'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final exercises = filterExercises(
                  exercises: snapshot.value!,
                  searchQuery: _searchQuery,
                  segment: _selectedSegment,
                  selectedMuscleGroup: _selectedMuscleGroup,
                );

                if (exercises.isEmpty) {
                  // Tre vuoti diversi, e dirli tutti «non ci sono esercizi»
                  // manderebbe l'utente a caricare una libreria che ha gia.
                  // Qui gli esercizi ci sono per definizione — `vista` sarebbe
                  // `empty` altrimenti — quindi sono i filtri a non trovare
                  // niente.
                  final emptyMsg =
                      _selectedSegment == ExerciseSegmentFilter.recent
                          ? loc.t('exercises_recent_empty')
                          : loc.t('exercises_no_match');
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(t.spacing.xl),
                      child: Text(
                        emptyMsg,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(bottom: t.spacing.bottomInset),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    if (!exercise.isCustom) {
                      return _buildExerciseCard(exercise, context, loc);
                    }

                    return Dismissible(
                      key: Key(exercise.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: t.spacing.md,
                          vertical: t.spacing.xs,
                        ),
                        decoration: ShapeDecoration(
                          color: scheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: t.shape.cornerLg,
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: t.spacing.lg),
                        child: Icon(Icons.delete, color: scheme.onError),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(loc.t('delete_event_title')),
                            content: Text(
                              '${exercise.name} - ${loc.t('delete_event_body')}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(loc.t('cancel')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  loc.t('delete'),
                                  style: TextStyle(color: scheme.error),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _firestore.deleteExercise(exercise.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.t('event_deleted'))),
                        );
                      },
                      child: _buildExerciseCard(exercise, context, loc),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExerciseCard(
    Exercise exercise,
    BuildContext context,
    Localization loc,
  ) {
    final t = context.expressive;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitleText = buildExerciseSubtitleText(exercise, loc);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: t.spacing.xs,
      ),
      child: ExerciseRow(
        exercise: exercise,
        subtitle: Text(
          subtitleText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onThumbnailTap: () => ExerciseVideoSheet.show(context, exercise),
        onTap: () {
          if (widget.isSelecting) {
            Navigator.pop(context, exercise);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showAddExerciseDialog() async {
    final nameController = TextEditingController();
    ExerciseType selectedType = ExerciseType.strength;
    String? nameError;

    final loc = ref.read(localizationNotifierProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(loc.t('add_exercise_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.t('add_exercise_name_label'),
                    errorText: nameError,
                  ),
                  onChanged: (_) {
                    if (nameError != null) {
                      setState(() => nameError = null);
                    }
                  },
                ),
                SizedBox(height: context.expressive.spacing.md),
                DropdownButton<ExerciseType>(
                  value: selectedType,
                  isExpanded: true,
                  onChanged: (val) => setState(() => selectedType = val!),
                  items: ExerciseType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(loc.t('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  final result = await handleAddExerciseSubmit(
                    rawName: nameController.text,
                    type: selectedType,
                    userId: _auth.currentUser?.uid,
                    saveExercise: _firestore.addExercise,
                  );

                  if (!dialogContext.mounted) return;

                  if (result.shouldCloseDialog) {
                    Navigator.of(dialogContext).pop();
                  } else {
                    if (result.outcome == AddExerciseOutcome.validationError) {
                      setState(() {
                        nameError = loc.t(result.errorKey!);
                      });
                    } else if (result.outcome == AddExerciseOutcome.saveError) {
                      ToastUtils.showError(
                        dialogContext,
                        loc.t(result.errorKey!),
                      );
                    }
                  }
                },
                child: Text(loc.t('save')),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
  }
}
