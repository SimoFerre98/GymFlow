// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerSettingsNotifierHash() =>
    r'eb0c22ed283bc006dbad4e1ff7be5314d3ea7efd';

/// Provider per le impostazioni del timer con persistenza locale.
///
/// Copied from [TimerSettingsNotifier].
@ProviderFor(TimerSettingsNotifier)
final timerSettingsNotifierProvider =
    NotifierProvider<TimerSettingsNotifier, TimerSettings>.internal(
  TimerSettingsNotifier.new,
  name: r'timerSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timerSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TimerSettingsNotifier = Notifier<TimerSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
