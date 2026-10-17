import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymflow/src/models/consent.dart';
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
/// I consensi che ho dato da cliente (US-092): a chi, e cosa. Uno per ogni
/// trainer che mi segue.
@riverpod
class ConsentsOfClient extends _$ConsentsOfClient {
  @override
  Stream<List<Consent>> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Stream.value(const []);
    return ref.watch(firestoreServiceProvider).consentsOfClient(userId);
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
