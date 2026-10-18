import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymflow/src/models/user_profile.dart';
import '../../services/auth_service.dart';
import 'auth_provider.dart';

part 'profile_provider.g.dart';

/// Il profilo dell'utente corrente, in Riverpod (US-089).
///
/// Serve a chi deve decidere cosa mostrare in base al ruolo — la Home, che
/// mostra «Clienti» solo a un trainer. Prima ogni schermata apriva da sé
/// `AuthService().getUserProfileStream()`: qui lo fa una volta e chi legge si
/// limita a osservare.
///
/// `null` finché il primo valore non arriva, e per un utente senza profilo:
/// chi dipende dal ruolo deve trattare «non so» come «non è trainer».
@riverpod
class CurrentUserProfile extends _$CurrentUserProfile {
  @override
  Stream<UserProfile?> build() {
    // Cambiando utente (logout, nuovo login) il flusso riparte da capo.
    ref.watch(currentUserIdProvider);
    return AuthService().getUserProfileStream();
  }
}
