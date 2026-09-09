// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerSettingsNotifierHash() =>
    r'cacbb6ce7c8e684b7c211ec2172513b54e3c9935';

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
