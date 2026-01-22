import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Exercises ---

  // Get all exercises (Global + Custom)
  Stream<List<Exercise>> getExercises(String userId) {
    // This is simplified. In reality you might want to merge two streams or queries
    // For now assuming all exercises are in one collection, distinguished by isCustom and userId (implied ownership)
    return _db
        .collection('exercises')
        .where('isCustom', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Exercise.fromMap(doc.data(), doc.id))
              .toList(),
        );

    // TODO: Add logic to fetch custom exercises for the specific user
  }

  Future<void> addExercise(Exercise exercise) async {
    await _db.collection('exercises').add(exercise.toMap());
  }

  // --- Workouts ---

  // Get User's Workout Templates
  Stream<List<WorkoutTemplate>> getUserWorkouts(String userId) {
    return _db
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutTemplate.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Create/Update Workout
  Future<void> saveWorkout(WorkoutTemplate workout) async {
    if (workout.id.isEmpty) {
      await _db.collection('workouts').add(workout.toMap());
    } else {
      await _db.collection('workouts').doc(workout.id).update(workout.toMap());
    }
  }

  // Delete Workout
  Future<void> deleteWorkout(String workoutId) async {
    await _db.collection('workouts').doc(workoutId).delete();
  }
}
