import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymflow/src/models/invite.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
part 'invite_provider.g.dart';
@riverpod
class IncomingInvites extends _$IncomingInvites {
  @override
  Stream<List<Invite>> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Stream.value(const []);
    return ref.watch(firestoreServiceProvider).incomingInvites(userId);
  }
}
@riverpod
class OutgoingInvites extends _$OutgoingInvites {
  @override
  Stream<List<Invite>> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Stream.value(const []);
    return ref.watch(firestoreServiceProvider).outgoingInvites(userId);
  }
}
@riverpod
class AcceptedRelationships extends _$AcceptedRelationships {
  @override
  Stream<List<Invite>> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Stream.value(const []);
    return ref.watch(firestoreServiceProvider).acceptedRelationships(userId);
  }
}
