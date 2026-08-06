import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/body_measurement.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'gymflow',
  );

  Future<bool> addFriendByCode(String code) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return false;

    // 1. Find friend by code
    final snapshot = await _db
        .collection('users')
        .where('friendCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final friendDoc = snapshot.docs.first;
    final friendId = friendDoc.id;

    if (friendId == currentUser.uid) return false; // Can't add self

    // 2. Add Friend Mutual
    final batch = _db.batch();

    // Add friend to my list
    batch.update(_db.collection('users').doc(currentUser.uid), {
      'friends': FieldValue.arrayUnion([friendId]),
    });

    // Add me to friend's list
    batch.update(_db.collection('users').doc(friendId), {
      'friends': FieldValue.arrayUnion([currentUser.uid]),
    });

    await batch.commit();
    return true;
  }

  Future<void> toggleFriendAccess(
    String friendId,
    String type,
    bool allow,
  ) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final field = type == 'calendar'
        ? 'calendarSharedWith'
        : 'programsSharedWith';

    if (allow) {
      await _db.collection('users').doc(user.uid).update({
        field: FieldValue.arrayUnion([friendId]),
      });
    } else {
      await _db.collection('users').doc(user.uid).update({
        field: FieldValue.arrayRemove([friendId]),
      });
    }
  }

  Stream<List<UserProfile>> getFriendsStream(List<String> friendIds) {
    if (friendIds.isEmpty) return Stream.value([]);

    // Firestore 'where in' is limited to 10 items.
    // For simplicity/MVP, we'll just fetch chunks or valid IDs.
    // Given the complexity of robust where-in, and MVP nature:
    // We can just listen to collection where documentId whereIn friendIds (chunked)
    // Or for MVP just fetch them all if list is small.
    // Let's implement a simple fetch for now since Stream with varying list is complex.

    // Actually, 'users' collection might be large, so we MUST filter.
    // Let's just do a Future-based fetch for the list view for now, or stream limited to 10.
    // Better approach: simple Future fetch for the list.
    return _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds.take(10).toList())
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => UserProfile.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<List<UserProfile>> getUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    // Chunking logic for > 10 items would go here for robust app
    final chunks = <List<String>>[];
    for (var i = 0; i < userIds.length; i += 10) {
      chunks.add(
        userIds.sublist(i, (i + 10) < userIds.length ? i + 10 : userIds.length),
      );
    }

    final List<UserProfile> allUsers = [];
    for (final chunk in chunks) {
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      allUsers.addAll(
        snapshot.docs.map((d) => UserProfile.fromMap(d.data(), d.id)),
      );
    }
    return allUsers;
  }

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

  Future<void> deleteExercise(String exerciseId) async {
    await _db.collection('exercises').doc(exerciseId).delete();
  }

  /// Scrive in Firestore gli esercizi della libreria curata.
  ///
  /// L'identificativo del documento e quello dell'esercizio nel file, non uno
  /// generato: **e cosi che l'import e idempotente**. Rieseguirlo riscrive gli
  /// stessi documenti invece di aggiungerne altri quarantatre, e permette di
  /// aggiornare la libreria quando i video mancanti verranno assegnati.
  ///
  /// Non cancella nulla: gli esercizi che c'erano prima restano dove sono.
  /// Cancellare documenti che non ha creato lui non spetta a uno strumento di
  /// import.
  Future<void> importCuratedExercises(List<Exercise> exercises) async {
    if (exercises.isEmpty) return;

    // Un lotto Firestore regge 500 scritture: quarantatre stanno comode. La
    // suddivisione c'e lo stesso, perche la libreria e destinata a crescere.
    const maxPerBatch = 400;
    for (var start = 0; start < exercises.length; start += maxPerBatch) {
      final slice = exercises.skip(start).take(maxPerBatch);
      final batch = _db.batch();
      for (final exercise in slice) {
        final doc = _db.collection('exercises').doc(exercise.id);
        batch.set(doc, exercise.toMap());
      }
      await batch.commit();
    }
  }

  // --- Workouts ---

  // --- Programs ("Schede") ---

  Stream<List<WorkoutProgram>> getUserPrograms(String userId) {
    return _db
        .collection('programs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<WorkoutProgram> getProgramStream(String programId) {
    return _db.collection('programs').doc(programId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Program not found');
      return WorkoutProgram.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> saveProgram(WorkoutProgram program) async {
    if (program.id.isEmpty) {
      final doc = _db.collection('programs').doc();
      // Ensure we set the ID in the map if the model expects it,
      // though fromMap usually handles id from doc.id.
      // But creating a new model with the ID is cleaner.
      await doc.set(program.toMap()..['id'] = doc.id);
    } else {
      await _db.collection('programs').doc(program.id).update(program.toMap());
    }
  }

  Future<void> deleteProgram(String programId) async {
    // Optional: Also delete workouts associated with it?
    // For now, simple delete.
    await _db.collection('programs').doc(programId).delete();
  }

  Future<void> addWorkoutToProgram(String programId, String workoutId) async {
    await _db.collection('programs').doc(programId).update({
      'workoutIds': FieldValue.arrayUnion([workoutId]),
    });
  }

  // --- Workouts ---

  // Get User's Workout Templates
  Stream<List<WorkoutTemplate>> getUserWorkouts(String userId) {
    return _db
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        // .orderBy('name') // Optional sorting
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
  Future<String> saveWorkout(WorkoutTemplate workout) async {
    if (workout.id.isEmpty) {
      final docRef = await _db.collection('workouts').add(workout.toMap());
      return docRef.id;
    } else {
      await _db.collection('workouts').doc(workout.id).update(workout.toMap());
      return workout.id;
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

  // --- Body Measurements ---

  Stream<List<BodyMeasurement>> getBodyMeasurements(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BodyMeasurement.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addBodyMeasurement(
    String userId,
    BodyMeasurement measurement,
  ) async {
    // If ID is empty, create a new doc reference
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(measurement.id.isEmpty ? null : measurement.id);

    // Ensure the ID in the object matches the doc ID (for new docs)
    final data = measurement.toMap()..['id'] = docRef.id;

    await docRef.set(data);
  }

  Future<void> deleteBodyMeasurement(
    String userId,
    String measurementId,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(measurementId)
        .delete();
  }

  /// Deep copy a program and all its workouts to the current user
  Future<void> importSharedProgram(
    WorkoutProgram originalProgram,
    String targetUserId,
  ) async {
    WriteBatch batch = _db.batch();
    List<String> newWorkoutIds = [];

    // Clone each workout
    for (String oldWorkoutId in originalProgram.workoutIds) {
      final docSnap = await _db.collection('workouts').doc(oldWorkoutId).get();
      if (!docSnap.exists) continue;

      final newWorkoutRef = _db.collection('workouts').doc();
      final oldData = docSnap.data();
      if (oldData == null) continue;

      final newData = Map<String, dynamic>.from(oldData);
      newData['id'] = newWorkoutRef.id;
      newData['userId'] = targetUserId;
      // Temporarily empty until we generate program ID, or we can update later
      newData['parentProgramId'] = '';

      batch.set(newWorkoutRef, newData);
      newWorkoutIds.add(newWorkoutRef.id);
    }

    // Clone the program
    final newProgramRef = _db.collection('programs').doc();
    final newProgram = originalProgram.copyWith(
      id: newProgramRef.id,
      userId: targetUserId,
      workoutIds: newWorkoutIds,
      createdAt: DateTime.now(),
      startDate: null,
      endDate: null,
    );

    batch.set(newProgramRef, newProgram.toMap());

    // Update parentProgramId in all new workouts
    for (String newWorkoutId in newWorkoutIds) {
      batch.update(_db.collection('workouts').doc(newWorkoutId), {
        'parentProgramId': newProgramRef.id,
      });
    }

    await batch.commit();
  }

  // --- Shared Calendar ---

  /// Get sessions from friends who shared their calendar with me
  Stream<List<WorkoutSession>> getSharedSessions(String myUserId) {
    // Find sessions where 'userId' is NOT me, but I can't filter by "friends who shared" easily in one query
    // because that permission is on the USER document (calendarSharedWith), not the SESSION document.
    //
    // Approach:
    // 1. Query Users where 'calendarSharedWith' contains myUserId.
    // 2. Extract their UserIDs.
    // 3. Query Sessions where userId matches.
    //
    // Since 'whereIn' is limited to 10, and users might change, this is tricky for a single stream.
    //
    // Alternative:
    // Just fetch "users where calendarSharedWith contains me".
    // Return a Stream of List<String> (friendIds).
    // The UI can then SwitchMap/CombineLatest.
    //
    // Let's implement getting the friend IDs stream first.
    return _db
        .collection('users')
        .where('calendarSharedWith', arrayContains: myUserId)
        .snapshots()
        .switchMap((snapshot) {
          final friendIds = snapshot.docs.map((d) => d.id).toList();
          if (friendIds.isEmpty) return Stream.value([]);

          // Firestore 'whereIn' limitation: max 10.
          // For MVP, we'll take top 10.
          // Ideally, we'd batch or just iterate if < 10.
          // If > 10, we'd need client side merging.
          final limitedIds = friendIds.take(10).toList();

          return _db
              .collection('sessions')
              .where('userId', whereIn: limitedIds)
              .orderBy('startTime', descending: true)
              .limit(50) // Limit total shared events to avoid overload
              .snapshots()
              .map(
                (snap) => snap.docs
                    .map((d) => WorkoutSession.fromMap(d.data(), d.id))
                    .toList(),
              );
        });
  }

  Stream<List<ScheduledWorkout>> getSharedScheduledWorkouts(String myUserId) {
    return _db
        .collection('users')
        .where('calendarSharedWith', arrayContains: myUserId)
        .snapshots()
        .switchMap((snapshot) {
          final friendIds = snapshot.docs.map((d) => d.id).toList();
          if (friendIds.isEmpty) return Stream.value([]);
          final limitedIds = friendIds.take(10).toList();

          return _db
              .collection('scheduled_workouts')
              .where('userId', whereIn: limitedIds)
              .snapshots()
              .map(
                (snap) => snap.docs
                    .map((d) => ScheduledWorkout.fromMap(d.data(), d.id))
                    .toList(),
              );
        });
  }
}
