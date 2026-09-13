// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$incomingInvitesHash() => r'498cddafd4aa7be672d9d6d7969764b55925f5f9';

/// See also [IncomingInvites].
@ProviderFor(IncomingInvites)
final incomingInvitesProvider =
    AutoDisposeStreamNotifierProvider<IncomingInvites, List<Invite>>.internal(
  IncomingInvites.new,
  name: r'incomingInvitesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incomingInvitesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IncomingInvites = AutoDisposeStreamNotifier<List<Invite>>;
String _$outgoingInvitesHash() => r'63b48a4c450ef514debbe828c0161ac18081c697';

/// See also [OutgoingInvites].
@ProviderFor(OutgoingInvites)
final outgoingInvitesProvider =
    AutoDisposeStreamNotifierProvider<OutgoingInvites, List<Invite>>.internal(
  OutgoingInvites.new,
  name: r'outgoingInvitesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$outgoingInvitesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OutgoingInvites = AutoDisposeStreamNotifier<List<Invite>>;
String _$acceptedRelationshipsHash() =>
    r'f53334c4dffe55c42237484b91024a109cd2eb7f';

/// See also [AcceptedRelationships].
@ProviderFor(AcceptedRelationships)
final acceptedRelationshipsProvider = AutoDisposeStreamNotifierProvider<
    AcceptedRelationships, List<Invite>>.internal(
  AcceptedRelationships.new,
  name: r'acceptedRelationshipsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$acceptedRelationshipsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AcceptedRelationships = AutoDisposeStreamNotifier<List<Invite>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
