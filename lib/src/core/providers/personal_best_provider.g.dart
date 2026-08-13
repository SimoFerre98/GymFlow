// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_best_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$personalBestsHash() => r'de7acd3cafb09591af5651588a04ce9341b294e8';

/// Espone la mappa exerciseId -> PersonalBest calcolata da tutte le sessioni
/// caricate in locale da Isar.
///
/// Copied from [PersonalBests].
@ProviderFor(PersonalBests)
final personalBestsProvider = AutoDisposeNotifierProvider<PersonalBests,
    Map<String, PersonalBest>>.internal(
  PersonalBests.new,
  name: r'personalBestsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$personalBestsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PersonalBests = AutoDisposeNotifier<Map<String, PersonalBest>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
