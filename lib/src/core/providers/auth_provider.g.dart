// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authStateHash() => r'67c08d9e96433c5148b2b1c9df2f3f795e41ff4c';

/// See also [AuthState].
@ProviderFor(AuthState)
final authStateProvider =
    AutoDisposeStreamNotifierProvider<AuthState, User?>.internal(
  AuthState.new,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthState = AutoDisposeStreamNotifier<User?>;
String _$currentUserHash() => r'4574a92b2678caf7a8c259de1605624e16a28351';

/// L'utente corrente, con il ripiego sincrono.
///
/// `authStateProvider` e uno stream: al primo build non ha ancora emesso, e
/// `.value` vale `null` anche a utente autenticato. Chi legge questo provider
/// per disegnare qualcosa vedrebbe quindi un frame «nessun utente» prima di
/// quello giusto — sulla dashboard e il saluto che dice «Atleta» e un istante
/// dopo il nome vero.
///
/// Il client Firebase invece risponde subito, ed e la stessa ragione per cui
/// `currentUserIdProvider` qui sotto ha sempre avuto questo ripiego: le due
/// funzioni erano asimmetriche senza motivo.
///
/// Copied from [CurrentUser].
@ProviderFor(CurrentUser)
final currentUserProvider =
    AutoDisposeNotifierProvider<CurrentUser, User?>.internal(
  CurrentUser.new,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUser = AutoDisposeNotifier<User?>;
String _$currentUserIdHash() => r'56f398c8ce250a713d5da1432af2782ca14f6152';

/// See also [CurrentUserId].
@ProviderFor(CurrentUserId)
final currentUserIdProvider =
    AutoDisposeNotifierProvider<CurrentUserId, String?>.internal(
  CurrentUserId.new,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserId = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
