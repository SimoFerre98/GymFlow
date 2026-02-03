import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return AuthService().authStateChanges;
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider).value;
}

@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  return ref.watch(currentUserProvider)?.uid;
}
