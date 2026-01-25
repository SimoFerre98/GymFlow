import 'package:flutter/material.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  final bool isSelecting; // If true, allows returning the selected exercise
  const ExerciseLibraryScreen({super.key, this.isSelecting = false});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  String _searchQuery = '';
  final Set<ExerciseType> _selectedFilters = {};

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
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
                    ).colorScheme.primary.withOpacity(0.2),
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
                            : Colors.grey.withOpacity(0.3),
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
                labelText: 'Search Exercise',
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
            child: StreamBuilder<List<Exercise>>(
              stream: _firestore.getExercises(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No exercises found. Add one!'),
                  );
                }

                final exercises = snapshot.data!.where((e) {
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
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
                            // TODO: Show exercise details
                          }
                        },
                      ),
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

  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    ExerciseType selectedType = ExerciseType.strength;

    showDialog(
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
              // Check if the dialog is still open/mounted before popping
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
