// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserProfileHash() =>
    r'd19e93b51f3dd67e973421a44f79c36a9380a858';

/// Il profilo dell'utente corrente, in Riverpod (US-089).
///
/// Serve a chi deve decidere cosa mostrare in base al ruolo — la Home, che
/// mostra «Clienti» solo a un trainer. Prima ogni schermata apriva da sé
/// `AuthService().getUserProfileStream()`: qui lo fa una volta e chi legge si
/// limita a osservare.
///
/// `null` finché il primo valore non arriva, e per un utente senza profilo:
/// chi dipende dal ruolo deve trattare «non so» come «non è trainer».
///
/// Copied from [CurrentUserProfile].
@ProviderFor(CurrentUserProfile)
final currentUserProfileProvider = AutoDisposeStreamNotifierProvider<
    CurrentUserProfile, UserProfile?>.internal(
  CurrentUserProfile.new,
  name: r'currentUserProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserProfile = AutoDisposeStreamNotifier<UserProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
