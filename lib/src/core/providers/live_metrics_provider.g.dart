// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_metrics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthServiceProviderHash() =>
    r'89b252069b2d354b2a8d11cbe8d167c13cb10123';

/// Espone l'istanza del servizio Salute.
///
/// Copied from [HealthServiceProvider].
@ProviderFor(HealthServiceProvider)
final healthServiceProvider =
    AutoDisposeNotifierProvider<HealthServiceProvider, HealthService>.internal(
  HealthServiceProvider.new,
  name: r'healthServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$healthServiceProviderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HealthServiceProvider = AutoDisposeNotifier<HealthService>;

String _$liveMetricsNotifierHash() =>
    r'9a31fec793ab98d361c4d4c8eb5d4e12cbb54321';

/// Gestisce l'acquisizione periodica delle metriche dal vivo durante l'allenamento.
///
/// Trattandosi di un provider `autoDispose`, quando l'utente lascia la schermata di
/// sessione attiva, la sottoscrizione e il timer periodico vengono automaticamente
/// annullati senza perdite di memoria.
///
/// Copied from [LiveMetricsNotifier].
@ProviderFor(LiveMetricsNotifier)
final liveMetricsNotifierProvider =
    AutoDisposeNotifierProvider<LiveMetricsNotifier, LiveMetricsState>.internal(
  LiveMetricsNotifier.new,
  name: r'liveMetricsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$liveMetricsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LiveMetricsNotifier = AutoDisposeNotifier<LiveMetricsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
