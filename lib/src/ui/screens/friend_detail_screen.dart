import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/providers/invite_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/models/consent.dart';
import 'package:gymflow/src/models/invite.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/ui/widgets/consent_sheet.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:intl/intl.dart';
/// Raggio del ritratto grande in cima al profilo della connessione.
const double _kRaggioAvatarProfilo = 60;
const double _kTitleFontSize = 24;
/// Il profilo di una connessione accettata (amico o cliente, US-087).
///
/// Prima di questa storia prendeva un [UserProfile] intero e mostrava tab
/// calendario/schede condivisi — mai stati funzionanti, perché
/// `getUserSessions(friend.id)`/`getUserPrograms(friend.id)` sono negati
/// dalle stesse regole che l'invito sostituisce (vedi `firestore.rules`).
/// Restano fuori da questa storia deliberatamente: si ricollegano quando un
/// passo successivo apre la lettura dei dati condivisi in base a un invito
/// accettato. Qui basta ciò che l'invito stesso porta con sé: nome e data.
class FriendDetailScreen extends ConsumerWidget {
  final String connectionId;
  final String displayName;
  final DateTime since;

  /// L'invito accettato che regge questo legame. Serve a riconoscere un
  /// legame trainer↔cliente e, se sono io il cliente, a mostrare cosa
  /// concedo e a lasciarmelo cambiare (US-092).
  final Invite? invite;
  const FriendDetailScreen({
    super.key,
    required this.connectionId,
    required this.displayName,
    required this.since,
    this.invite,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final myUserId = ref.watch(currentUserIdProvider);
    final legame = invite;
    // `fromUserId` è sempre il trainer: il cliente è chi riceve l'invito.
    final iAmClient = legame != null &&
        legame.relationshipType == RelationshipType.trainerClient &&
        legame.toUserId == myUserId;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('connect_friends_title')),
                  SizedBox(width: t.spacing.md),
                  Flexible(
                    child: Text(
                      displayName.toUpperCase(),
                      style: t.typography.headline?.copyWith(
                        fontSize: _kTitleFontSize,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(t.spacing.xl),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: _kRaggioAvatarProfilo,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    SizedBox(height: t.spacing.xl),
                    Text(
                      displayName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: t.typography.headline?.copyWith(
                        fontSize: _kTitleFontSize + 6,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: t.spacing.sm),
                    Text(
                      loc.t('connection_since').replaceFirst(
                        '%s',
                        DateFormat.yMMMd(loc.locale.languageCode).format(since),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (iAmClient) ...[
                      SizedBox(height: t.spacing.xxl),
                      _ConsentSection(invite: legame),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cosa questo trainer vede di me, e gli interruttori per cambiarlo (US-092).
///
/// Ogni tocco scrive subito: la prossima lettura del trainer, nelle regole, è
/// negata o permessa di conseguenza. Nessun «Salva» da dimenticare di premere.
class _ConsentSection extends ConsumerWidget {
  const _ConsentSection({required this.invite});

  final Invite invite;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    Consent consent,
    ConsentCategory category,
    bool value,
  ) async {
    final loc = ref.read(localizationNotifierProvider);
    try {
      await ref.read(firestoreServiceProvider).setConsentGrant(consent.id, category, value);
    } catch (e) {
      if (context.mounted) {
        ToastUtils.showError(context, '${loc.t('error_connecting')}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final consents = ref.watch(consentsOfClientProvider);
    // Prima del primo dato non si mostra nulla: un «non trovato» passeggero
    // sarebbe una bugia.
    if (!consents.hasValue) return const SizedBox.shrink();
    final consent = consents.requireValue.where((c) => c.inviteId == invite.id).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.t('consent_manage_title').toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        if (consent == null)
          Text(
            loc.t('consent_missing_msg'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else ...[
          Text(
            consentSummaryText(loc, consent.grants),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final category in ConsentCategory.values)
            ConsentCategoryTile(
              category: category,
              value: consent.grants.isGranted(category),
              onChanged: (value) => _set(context, ref, consent, category, value),
            ),
        ],
      ],
    );
  }
}
