// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localization_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localizationNotifierHash() =>
    r'b2a2b0036e10e57cf9736af43bfac46469569132';

/// Espone la lingua corrente e le sue traduzioni, persistendo la scelta.
///
/// Come per il tema, [build] restituisce subito il default e avvia la lettura
/// da `SharedPreferences`: nessuno stato di caricamento da gestire nella UI.
///
/// Copied from [LocalizationNotifier].
@ProviderFor(LocalizationNotifier)
final localizationNotifierProvider =
    NotifierProvider<LocalizationNotifier, Localization>.internal(
  LocalizationNotifier.new,
  name: r'localizationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localizationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocalizationNotifier = Notifier<Localization>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
