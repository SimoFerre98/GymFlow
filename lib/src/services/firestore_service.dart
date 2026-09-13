import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/body_measurement.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/models/invite.dart';
import 'package:rxdart/rxdart.dart';
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'gymflow',
  );
  // --- Inviti (US-087) ---
  //
  // Sostituisce l'amico per codice, che scriveva sul documento di un altro
  // utente e cercava leggendo tutti i documenti utente: entrambe negate
  // dalle regole attuali, di proposito (vedi `firestore.rules`). Un solo
  // meccanismo per il legame amico↔amico e per l'invito trainer→cliente:
  // cambia solo `relationshipType`.
  /// Cerca la persona da invitare per codice (un `get()` su `invite_codes`,
  /// mai una query su `users`) e crea l'invito. Restituisce `null` se il
  /// codice non esiste o appartiene a chi sta invitando.
  Future<Invite?> createInvite({
    required String code,
    required String fromUserId,
    required String fromDisplayName,
    required String fromRole,
    required RelationshipType relationshipType,
    Duration validFor = const Duration(days: 7),
  }) async {
    final codeDoc = await _db.collection('invite_codes').doc(code).get();
    if (!codeDoc.exists) return null;
    final toUserId = codeDoc.data()!['userId'] as String;
    if (toUserId == fromUserId) return null;
    final toDisplayName = codeDoc.data()!['displayName'] as String? ?? 'User';
    final now = DateTime.now();
    final invite = Invite(
      id: '',
      fromUserId: fromUserId,
      fromDisplayName: fromDisplayName,
      fromRole: fromRole,
      toUserId: toUserId,
      toDisplayName: toDisplayName,
      code: code,
      relationshipType: relationshipType,
      status: InviteStatus.pending,
      createdAt: now,
      expiresAt: now.add(validFor),
    );
    final docRef = await _db.collection('invites').add(invite.toMap());
    return Invite(
      id: docRef.id,
      fromUserId: invite.fromUserId,
      fromDisplayName: invite.fromDisplayName,
      fromRole: invite.fromRole,
      toUserId: invite.toUserId,
      toDisplayName: invite.toDisplayName,
      code: invite.code,
      relationshipType: invite.relationshipType,
      status: invite.status,
      createdAt: invite.createdAt,
      expiresAt: invite.expiresAt,
    );
  }
  /// Inviti ricevuti, ancora in sospeso.
  Stream<List<Invite>> incomingInvites(String userId) {
    return _db
        .collection('invites')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Invite.fromMap(d.data(), d.id))
            .where((i) => i.status == InviteStatus.pending)
            .toList());
  }
  /// Inviti mandati da me, ancora in sospeso.
  Stream<List<Invite>> outgoingInvites(String userId) {
    return _db
        .collection('invites')
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Invite.fromMap(d.data(), d.id))
            .where((i) => i.status == InviteStatus.pending)
            .toList());
  }
  /// Le connessioni accettate, in entrambe le direzioni.
  Stream<List<Invite>> acceptedRelationships(String userId) {
    return Rx.combineLatest2(
      _db
          .collection('invites')
          .where('fromUserId', isEqualTo: userId)
          .snapshots(),
      _db
          .collection('invites')
          .where('toUserId', isEqualTo: userId)
          .snapshots(),
      (QuerySnapshot<Map<String, dynamic>> mine,
              QuerySnapshot<Map<String, dynamic>> theirs) =>
          [...mine.docs, ...theirs.docs]
              .map((d) => Invite.fromMap(d.data(), d.id))
              .where((i) => i.status == InviteStatus.accepted)
              .toList(),
    );
  }
  Future<void> respondToInvite(String inviteId, bool accept) async {
    await _db.collection('invites').doc(inviteId).update({
      'status': accept ? InviteStatus.accepted.toMap() : InviteStatus.declined.toMap(),
      'respondedAt': Timestamp.now(),
    });
  }
  /// Annulla un invito ancora in sospeso (chi ha invitato) o scioglie un
  /// legame già accettato (entrambe le parti): la regola distingue i due
  /// casi da chi chiama e dallo stato attuale, il codice qui è lo stesso.
  Future<void> revokeInvite(String inviteId) async {
    await _db.collection('invites').doc(inviteId).update({
      'status': InviteStatus.revoked.toMap(),
    });
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
  /// Gli esercizi creati da questo utente.
  ///
  /// **Solo i suoi.** La libreria curata non sta in Firestore: le regole negano
  /// al client la scrittura sulla collezione condivisa, ed e la scelta giusta,
  /// perche quei documenti sarebbero visibili a tutti. I 43 curati viaggiano
  /// con l'app come asset e li unisce `exercisesProvider`.
  ///
  /// Prima questo metodo interrogava anche `isCustom == false`, cioe la
  /// libreria condivisa: una query che restituiva sempre zero documenti, perche
  /// nessuno era mai riuscito a scriverceli.
  Stream<List<Exercise>> getExercises(String userId) {
    return _db
        .collection('exercises')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Exercise.fromMap(d.data(), d.id)).toList(),
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
          if (friendIds.isEmpty) return Stream.value(<WorkoutSession>[]);
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
        })
        // La query sui documenti utente e **negata dalle regole**, e lo e per
        // scelta: US-018 ha chiuso la condivisione fra amici e US-080 la
        // rifara. Il punto e cosa succede al calendario nel frattempo.
        //
        // Il calendario unisce quattro stream con `Rx.combineLatest4`, e
        // `combineLatest` non emette finche **ogni** ingresso non ha emesso
        // almeno una volta: un ingresso che va in errore senza mai emettere
        // spegne la vista intera. Da qui gli eventi che non compaiono.
        //
        // Quindi l'errore non si propaga: si registra e si emette una lista
        // vuota, che e la verita — di sessioni condivise non ce ne sono.
        .onErrorReturnWith((errore, _) {
          debugPrint('Sessioni condivise non leggibili: $errore');
          return <WorkoutSession>[];
        });
  }
  Stream<List<ScheduledWorkout>> getSharedScheduledWorkouts(String myUserId) {
    return _db
        .collection('users')
        .where('calendarSharedWith', arrayContains: myUserId)
        .snapshots()
        .switchMap((snapshot) {
          final friendIds = snapshot.docs.map((d) => d.id).toList();
          if (friendIds.isEmpty) return Stream.value(<ScheduledWorkout>[]);
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
        })
        // Vedi la nota in `getSharedSessions`: un errore qui spegneva il
        // calendario intero, allenamenti propri compresi.
        .onErrorReturnWith((errore, _) {
          debugPrint('Allenamenti programmati condivisi non leggibili: $errore');
          return <ScheduledWorkout>[];
        });
  }
}
