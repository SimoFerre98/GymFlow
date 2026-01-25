import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Exercises ---

  // --- Exercises ---

  // Get all exercises (Global + Custom for this user)
  Stream<List<Exercise>> getExercises(String userId) {
    final defaultsStream = _db
        .collection('exercises')
        .where('isCustom', isEqualTo: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Exercise.fromMap(d.data(), d.id)).toList(),
        );

    final customsStream = _db
        .collection('exercises')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Exercise.fromMap(d.data(), d.id)).toList(),
        );

    return Rx.combineLatest2<List<Exercise>, List<Exercise>, List<Exercise>>(
      defaultsStream,
      customsStream,
      (defaults, customs) => [...defaults, ...customs],
    );
  }

  Future<void> addExercise(Exercise exercise) async {
    final doc = _db.collection('exercises').doc();
    final newExercise = Exercise(
      id: doc.id,
      userId: exercise.userId,
      name: exercise.name,
      description: exercise.description,
      type: exercise.type,
      videoUrl: exercise.videoUrl,
      musclesTargeted: exercise.musclesTargeted,
      isCustom: true,
    );
    await doc.set(newExercise.toMap());
  }

  Future<void> seedDefaultExercises() async {
    final existing = await _db.collection('exercises').limit(1).get();
    if (existing.docs.isNotEmpty) return; // Already seeded

    final defaults = [
      Exercise(
        id: '',
        name: 'Bench Press',
        description: 'Chest compound',
        type: ExerciseType.strength,
        musclesTargeted: ['Chest', 'Triceps'],
      ),
      Exercise(
        id: '',
        name: 'Squat',
        description: 'Leg compound',
        type: ExerciseType.strength,
        musclesTargeted: ['Quads', 'Glutes'],
      ),
      Exercise(
        id: '',
        name: 'Deadlift',
        description: 'Back compound',
        type: ExerciseType.strength,
        musclesTargeted: ['Back', 'Hamstrings'],
      ),
      Exercise(
        id: '',
        name: 'Overhead Press',
        description: 'Shoulder compound',
        type: ExerciseType.strength,
        musclesTargeted: ['Shoulders'],
      ),
      Exercise(
        id: '',
        name: 'Pull Up',
        description: 'Back compound',
        type: ExerciseType.strength,
        musclesTargeted: ['Back', 'Biceps'],
      ),
      Exercise(
        id: '',
        name: 'Dumbbell Curl',
        description: 'Bicep isolation',
        type: ExerciseType.hypertrophy,
        musclesTargeted: ['Biceps'],
      ),
      Exercise(
        id: '',
        name: 'Tricep Extension',
        description: 'Tricep isolation',
        type: ExerciseType.hypertrophy,
        musclesTargeted: ['Triceps'],
      ),
      Exercise(
        id: '',
        name: 'Running',
        description: 'Cardio',
        type: ExerciseType.cardio,
        musclesTargeted: ['Legs', 'Heart'],
      ),
    ];

    final batch = _db.batch();
    for (var ex in defaults) {
      final doc = _db.collection('exercises').doc();
      batch.set(doc, ex.toMap()..['id'] = doc.id); // Set ID securely
    }
    await batch.commit();
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

  Future<WorkoutTemplate?> getWorkout(String workoutId) async {
    final doc = await _db.collection('workouts').doc(workoutId).get();
    if (doc.exists && doc.data() != null) {
      return WorkoutTemplate.fromMap(doc.data()!, doc.id);
    }
    return null;
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

  // --- Sessions ---

  Future<void> saveSession(WorkoutSession session) async {
    await _db.collection('sessions').doc(session.id).set(session.toMap());
  }

  Future<WorkoutSession?> getLastSession(
    String userId,
    String templateId,
  ) async {
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('workoutTemplateId', isEqualTo: templateId)
        .orderBy('startTime', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return WorkoutSession.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    }
    return null;
  }

  Stream<List<WorkoutSession>> getUserSessions(String userId) {
    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutSession.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).delete();
  }

  // --- Scheduled Workouts ---

  Stream<List<ScheduledWorkout>> getUserScheduledWorkouts(String userId) {
    return _db
        .collection('scheduled_workouts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduledWorkout.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> scheduleWorkout(ScheduledWorkout schedule) async {
    if (schedule.id.isEmpty) {
      await _db.collection('scheduled_workouts').add(schedule.toMap());
    } else {
      await _db
          .collection('scheduled_workouts')
          .doc(schedule.id)
          .set(schedule.toMap());
    }
  }

  Future<void> deleteScheduledWorkout(String scheduleId) async {
    await _db.collection('scheduled_workouts').doc(scheduleId).delete();
  }
}
