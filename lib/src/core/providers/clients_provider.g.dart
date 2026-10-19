// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clientOverviewHash() => r'8ef3d51e9c2fbea574c7a7e8a732e332abe1a26b';

/// L'elenco dei clienti del trainer, già composto e ordinato (US-089).
///
/// **Si legge una volta** quando la schermata si apre, e di nuovo con
/// [refresh] (il «tira per aggiornare»). Non è un ascolto continuo: un cliente
/// che si allena mentre l'elenco è aperto compare al prossimo aggiornamento,
/// ed è il prezzo di non tenere aperti dieci ascoltatori.
///
/// Copied from [ClientOverview].
@ProviderFor(ClientOverview)
final clientOverviewProvider =
    AutoDisposeAsyncNotifierProvider<ClientOverview, List<ClientRow>>.internal(
  ClientOverview.new,
  name: r'clientOverviewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clientOverviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ClientOverview = AutoDisposeAsyncNotifier<List<ClientRow>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
