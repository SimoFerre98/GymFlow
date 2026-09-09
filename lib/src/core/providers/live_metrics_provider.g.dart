// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_metrics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthServiceProviderHash() =>
    r'b100af424c2ebdc29fdd4f642be1c115479966d1';

/// Espone l'istanza del servizio Salute.
///
/// Copied from [HealthServiceProvider].
@ProviderFor(HealthServiceProvider)
final healthServiceProviderProvider =
    AutoDisposeNotifierProvider<HealthServiceProvider, HealthService>.internal(
  HealthServiceProvider.new,
  name: r'healthServiceProviderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$healthServiceProviderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HealthServiceProvider = AutoDisposeNotifier<HealthService>;
String _$liveMetricsNotifierHash() =>
    r'db2be186f4150fe59583945acabaaaf9ecfab44d';

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
