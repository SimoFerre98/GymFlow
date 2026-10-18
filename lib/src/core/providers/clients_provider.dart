import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymflow/src/core/utils/client_overview.dart';
import 'package:gymflow/src/models/consent.dart';
import 'package:gymflow/src/models/invite.dart';
import 'package:gymflow/src/services/firestore_service.dart' as svc;
import 'auth_provider.dart';
import 'firestore_provider.dart';

part 'clients_provider.g.dart';

/// Collega [loadClientOverview] a Firestore. Niente logica qui: tutto ciò che
/// decide qualcosa sta in `client_overview.dart`, dove si prova senza Firebase.
class _FirestoreClientSource implements ClientOverviewSource {
  _FirestoreClientSource(this._service, this._trainerId);

  final svc.FirestoreService _service;
  final String _trainerId;

  @override
  Future<List<Invite>> acceptedRelationships() => _service.getAcceptedRelationships(_trainerId);

  @override
  Future<List<Consent>> consents() => _service.getConsentsOfTrainer(_trainerId);

  @override
  Future<DateTime?> lastSessionStart(String clientId) => _service.getLastSessionStart(clientId);
}

/// L'elenco dei clienti del trainer, già composto e ordinato (US-089).
///
/// **Si legge una volta** quando la schermata si apre, e di nuovo con
/// [refresh] (il «tira per aggiornare»). Non è un ascolto continuo: un cliente
/// che si allena mentre l'elenco è aperto compare al prossimo aggiornamento,
/// ed è il prezzo di non tenere aperti dieci ascoltatori.
@riverpod
class ClientOverview extends _$ClientOverview {
  @override
  Future<List<ClientRow>> build() {
    final trainerId = ref.watch(currentUserIdProvider);
    if (trainerId == null) return Future.value(const []);
    return _carica(trainerId);
  }

  Future<List<ClientRow>> _carica(String trainerId) {
    return loadClientOverview(
      trainerId: trainerId,
      source: _FirestoreClientSource(ref.read(firestoreServiceProvider), trainerId),
      now: DateTime.now(),
    );
  }

  /// Rilegge tutto. Tiene l'elenco precedente a schermo mentre carica, invece
  /// di svuotarlo.
  Future<void> refresh() async {
    final trainerId = ref.read(currentUserIdProvider);
    if (trainerId == null) return;
    state = const AsyncLoading<List<ClientRow>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _carica(trainerId));
  }
}
