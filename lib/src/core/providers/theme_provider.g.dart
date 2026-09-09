// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$themeSettingsNotifierHash() =>
    r'ee19333f1c3bef63cc07765e6c264da236e1b2cc';

/// Espone modalità, palette e colore del tema, persistendoli fra i riavvii.
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
