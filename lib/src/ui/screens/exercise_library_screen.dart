import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/exercise_detail_screen.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/ui/widgets/exercise_image.dart';
import 'package:gymflow/src/ui/widgets/exercise_row.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';
import 'package:gymflow/src/ui/widgets/add_exercise_dialog.dart';
/// Titolo "Esercizi" del mockup 2d Libreria: telaio 1:1, nessuna conversione
/// px→dp (vedi `DESIGN-SPEC.md`).
const double _kTitleFontSize = 30;
/// Altezza delle tessere "Sfoglia per gruppo" e dimensione del loro titolo.
const double _kGroupTileHeight = 104;
const double _kGroupTileNameFontSize = 20;
/// Barra "Nuovo esercizio" in fondo, al posto del FAB: testo e riquadro icona.
const double _kCtaFontSize = 20;
const double _kCtaIconBoxSide = 42;
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
  /// altro: la creazione di una scheda. Dal cassetto non ci si arriva piu
  /// (tolto insieme a Statistiche): oggi e sempre vero, ma resta un parametro
  /// legittimo, non un residuo — un domani con un'altra via di consultazione
  /// lo userebbe di nuovo.
  final bool isSelecting;
  /// Dove torna la pillola indietro: il nome della schermata che ha aperto
  /// questa. Assente, mostra la freccia predefinita invece di indovinare.
  final String? backLabel;
  const ExerciseLibraryScreen({
    super.key,
    this.isSelecting = false,
    this.backLabel,
  });
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
  bool _sortAlphabetically = false;
  /// Titolo della sezione elenco: dice davvero cosa si sta guardando invece
  /// di scrivere "usati di recente" quando il filtro Recenti e uno stub che
  /// restituisce sempre vuoto (vedi `filterExercises`).
  String _sectionLabel(Localization loc) {
    if (_selectedMuscleGroup != null) return _selectedMuscleGroup!;
    return switch (_selectedSegment) {
      ExerciseSegmentFilter.all => loc.t('exercises_title'),
      ExerciseSegmentFilter.mine => loc.t('exercise_filter_mine'),
      ExerciseSegmentFilter.recent => loc.t('exercise_filter_recent'),
    };
  }
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = ref.watch(localizationNotifierProvider);
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));
    final snapshot = ref.watch(exercisesProvider);
    final totalCount = snapshot.value?.length ?? 0;
    final allExercises = snapshot.value ?? const <Exercise>[];
    final muscleGroups = extractMuscleGroups(allExercises);
    final topGroups = muscleGroups.take(3).toList();
    return Scaffold(
      appBar: AppBar(
        leading: widget.backLabel != null
            ? BackPill(label: widget.backLabel!)
            : null,
        leadingWidth: widget.backLabel != null ? BackPill.leadingWidth : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.spacing.md,
              0,
              t.spacing.md,
              t.spacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  loc.t('exercises_title').toUpperCase(),
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
                SizedBox(width: t.spacing.md),
                Text(
                  '$totalCount',
                  style: t.typography.eyebrow?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: t.spacing.md,
                vertical: t.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: t.sizing.iconMd,
                    color: scheme.primary,
                  ),
                  SizedBox(width: t.spacing.sm),
                  Expanded(
                    child: TextField(
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: loc.t('exercises_search_placeholder'),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: t.spacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
            child: Row(
              children: [
                for (final seg in ExerciseSegmentFilter.values)
                  Padding(
                    padding: EdgeInsets.only(right: t.spacing.sm),
                    child: _FilterPill(
                      label: loc.t(switch (seg) {
                        ExerciseSegmentFilter.all => 'exercise_filter_all',
                        ExerciseSegmentFilter.mine => 'exercise_filter_mine',
                        ExerciseSegmentFilter.recent =>
                          'exercise_filter_recent',
                      }),
                      selected: _selectedSegment == seg,
                      onTap: () => setState(() => _selectedSegment = seg),
                    ),
                  ),
                for (final group in muscleGroups)
                  Padding(
                    padding: EdgeInsets.only(right: t.spacing.sm),
                    child: _FilterPill(
                      label: group,
                      selected: _selectedMuscleGroup == group,
                      onTap: () => setState(() {
                        _selectedMuscleGroup =
                            _selectedMuscleGroup == group ? null : group;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          if (_searchQuery.isEmpty && topGroups.isNotEmpty) ...[
            SizedBox(height: t.spacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
              child: Text(
                loc.t('library_browse_by_group').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: t.spacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
              child: SizedBox(
                height: _kGroupTileHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < topGroups.length; i++) ...[
                      if (i > 0) SizedBox(width: t.spacing.sm),
                      Expanded(
                        child: _GroupTile(
                          group: topGroups[i],
                          count: allExercises
                              .where(
                                (e) => e.musclesTargeted.any(
                                  (m) =>
                                      m.toLowerCase() ==
                                      topGroups[i].toLowerCase(),
                                ),
                              )
                              .length,
                          exercise: allExercises.firstWhere(
                            (e) => e.musclesTargeted.any(
                              (m) =>
                                  m.toLowerCase() ==
                                  topGroups[i].toLowerCase(),
                            ),
                          ),
                          onTap: () => setState(() {
                            _selectedMuscleGroup = topGroups[i];
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: t.spacing.sm),
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.spacing.md,
              0,
              t.spacing.md,
              t.spacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sectionLabel(loc).toUpperCase(),
                  style: t.typography.eyebrow?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                InkWell(
                  onTap: () => setState(
                    () => _sortAlphabetically = !_sortAlphabetically,
                  ),
                  child: Text(
                    'A-Z',
                    style: t.typography.eyebrow?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                if (_sortAlphabetically) {
                  exercises.sort((a, b) => a.name.compareTo(b.name));
                }
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
                        color: scheme.error,
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.spacing.md,
              t.spacing.sm,
              t.spacing.md,
              t.spacing.md,
            ),
            child: InkWell(
              onTap: _showAddExerciseDialog,
              child: Container(
                padding: EdgeInsets.all(t.spacing.xs),
                color: scheme.primary,
                child: Row(
                  children: [
                    SizedBox(width: t.spacing.md),
                    Expanded(
                      child: Text(
                        loc.t('exercises_new_btn').toUpperCase(),
                        style: t.typography.title?.copyWith(
                          fontSize: _kCtaFontSize,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: _kCtaIconBoxSide,
                      height: _kCtaIconBoxSide,
                      alignment: Alignment.center,
                      color: scheme.onPrimary,
                      child: Icon(Icons.add, color: scheme.primary),
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
  Widget _buildExerciseCard(
    Exercise exercise,
    BuildContext context,
    Localization loc,
  ) {
    final t = context.immersivo;
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
    // Il controller del nome vive dentro `AddExerciseDialog`, che lo rilascia
    // nel proprio `dispose`. Tenerlo qui e rilasciarlo dopo `await showDialog`
    // lo liberava mentre il dialogo stava ancora sfumando, e il `TextField` lo
    // stava ancora usando: schermata rossa in debug.
    await showDialog(
      context: context,
      builder: (_) => AddExerciseDialog(
        loc: ref.read(localizationNotifierProvider),
        userId: _auth.currentUser?.uid,
        saveExercise: _firestore.addExercise,
      ),
    );
  }
}
/// Una pillola del filtro unico del mockup 2d: sostituisce sia il segmentato
/// Tutti/Miei/Recenti sia i chip dei gruppi muscolari, che nel mockup sono
/// la stessa fila scorrevole di rettangoli maiuscoli.
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
/// Una tessera di "Sfoglia per gruppo": foto di un esercizio rappresentativo
/// del gruppo, nome e conteggio reale — non un'icona generica per gruppo, che
/// nella libreria non esiste come dato.
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.count,
    required this.exercise,
    required this.onTap,
  });
  final String group;
  final int count;
  final Exercise exercise;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExerciseImage(
            exercise: exercise,
            size: ExerciseImageSize.hero,
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.scrim.withValues(alpha: 0.05),
                  scheme.scrim.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          Positioned(
            right: t.spacing.sm,
            top: t.spacing.xs,
            child: Text(
              '$count',
              style: t.typography.eyebrow?.copyWith(color: scheme.primary),
            ),
          ),
          Positioned(
            left: t.spacing.sm,
            bottom: t.spacing.xs,
            child: Text(
              group.toUpperCase(),
              style: t.typography.title?.copyWith(
                fontSize: _kGroupTileNameFontSize,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
