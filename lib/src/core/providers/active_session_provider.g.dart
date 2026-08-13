// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSessionNotifierHash() =>
    r'aef9ac2195dc77e03aba0db833ad160f9f6ae1b9';

/// Provider globale che mantiene in memoria l'allenamento attivo.
///
/// Copied from [ActiveSessionNotifier].
@ProviderFor(ActiveSessionNotifier)
final activeSessionNotifierProvider =
    NotifierProvider<ActiveSessionNotifier, ActiveSessionState>.internal(
  ActiveSessionNotifier.new,
  name: r'activeSessionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSessionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveSessionNotifier = Notifier<ActiveSessionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
