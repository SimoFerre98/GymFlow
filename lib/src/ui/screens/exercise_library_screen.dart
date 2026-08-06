import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/widgets/exercise_thumbnail.dart';
import 'package:gymflow/src/ui/widgets/exercise_video_sheet.dart';

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

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  String _searchQuery = '';
  final Set<ExerciseType> _selectedFilters = {};

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('exercises_title'))),
      body: Column(
        children: [
          // Filter Chips Section
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ExerciseType.values.map((type) {
                final isSelected = _selectedFilters.contains(type);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFilters.add(type);
                        } else {
                          _selectedFilters.remove(type);
                        }
                      });
                    },
                    backgroundColor: Theme.of(context).cardColor,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: loc.t('exercises_search'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            // Dal provider e non da uno stream creato qui: `build` girava a
            // ogni ricostruzione e ne creava uno nuovo ogni volta. Ed e il
            // provider che unisce i curati dell'asset agli esercizi
            // dell'utente.
            child: Builder(
              builder: (context) {
                final snapshot = ref.watch(exercisesProvider);
                if (snapshot.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasValue || snapshot.value!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        loc.t('exercises_empty'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final exercises = snapshot.value!.where((e) {
                  final matchesSearch = e.name.toLowerCase().contains(
                    _searchQuery,
                  );
                  final matchesFilter =
                      _selectedFilters.isEmpty ||
                      _selectedFilters.contains(e.type);
                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    if (!exercise.isCustom) {
                      return _buildExerciseCard(exercise, context);
                    }

                    return Dismissible(
                      key: Key(exercise.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Exercise?'),
                            content: Text(
                              'Delete "${exercise.name}"? This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _firestore.deleteExercise(exercise.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exercise deleted')),
                        );
                      },
                      child: _buildExerciseCard(exercise, context),
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

  Widget _buildExerciseCard(Exercise exercise, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: ExerciseThumbnail(
          exercise: exercise,
          // Il tocco sulla miniatura mostra l'esecuzione; quello sulla cella
          // resta la selezione dell'esercizio. Due gesti, due significati.
          onTap: () => ExerciseVideoSheet.show(context, exercise),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(exercise.type.name.toUpperCase()),
        onTap: () {
          if (widget.isSelecting) {
            Navigator.pop(context, exercise);
          } else {
            // In consultazione la cella non aveva nessun gesto: un tocco
            // morto proprio dove si prova per primo. La schermata di dettaglio
            // dell'esercizio non esiste ancora ed e US-062; l'esecuzione si.
            ExerciseVideoSheet.show(context, exercise);
          }
        },
      ),
    );
  }

  Future<void> _showAddExerciseDialog() async {
    final nameController = TextEditingController();
    ExerciseType selectedType = ExerciseType.strength;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Custom Exercise'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Exercise Name'),
                ),
                const SizedBox(height: 16),
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
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              try {
                final exercise = Exercise(
                  id: '',
                  userId: _auth.currentUser?.uid,
                  name: nameController.text.trim(),
                  description: 'Custom exercise',
                  type: selectedType,
                  musclesTargeted: [],
                  isCustom: true,
                );

                await _firestore.addExercise(exercise);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                // Ignore or show error
                debugPrint('Error saving exercise: $e');
                // Ensure we pop even on error? Or let user retry?
                // Better to let retry.
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
  }
}
