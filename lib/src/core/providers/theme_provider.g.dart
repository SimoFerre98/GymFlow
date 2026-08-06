// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$themeSettingsNotifierHash() =>
    r'c5ca7da7eccb7c2c6f75c84ebc94c33af39d86b7';

/// Espone modalità e colore del tema, persistendoli fra i riavvii.
///
/// [build] restituisce i valori di default in modo sincrono e avvia la
/// lettura da `SharedPreferences`: lo stato viene aggiornato appena i valori
/// salvati sono disponibili. In questo modo `MaterialApp` non deve gestire uno
/// stato di caricamento e all'avvio non si vede un cambio di tema.
///
/// Copied from [ThemeSettingsNotifier].
@ProviderFor(ThemeSettingsNotifier)
final themeSettingsNotifierProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>.internal(
  ThemeSettingsNotifier.new,
  name: r'themeSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeSettingsNotifier = Notifier<ThemeSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
