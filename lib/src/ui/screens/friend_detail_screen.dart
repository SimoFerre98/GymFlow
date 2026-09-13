import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
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
  const FriendDetailScreen({
    super.key,
    required this.connectionId,
    required this.displayName,
    required this.since,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
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
