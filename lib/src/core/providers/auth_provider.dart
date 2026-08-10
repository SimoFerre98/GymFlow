import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return AuthService().authStateChanges;
}

/// L'utente corrente, con il ripiego sincrono.
///
/// `authStateProvider` e uno stream: al primo build non ha ancora emesso, e
/// `.value` vale `null` anche a utente autenticato. Chi legge questo provider
/// per disegnare qualcosa vedrebbe quindi un frame «nessun utente» prima di
/// quello giusto — sulla dashboard e il saluto che dice «Atleta» e un istante
/// dopo il nome vero.
///
/// Il client Firebase invece risponde subito, ed e la stessa ragione per cui
/// `currentUserIdProvider` qui sotto ha sempre avuto questo ripiego: le due
/// funzioni erano asimmetriche senza motivo.
@riverpod
User? currentUser(CurrentUserRef ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value ?? AuthService().currentUser;
}

@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value?.uid ?? AuthService().currentUser?.uid;
}
