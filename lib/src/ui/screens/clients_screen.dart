import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/clients_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/core/utils/client_overview.dart';
import 'package:gymflow/src/ui/screens/connect_friend_screen.dart';
import 'package:gymflow/src/ui/screens/friend_detail_screen.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/ui/widgets/expressive_card.dart';

const double _kTitleFontSize = 28;

/// Larghezza della striscia a sinistra di ogni cliente.
const double _kStripeWidth = 6;

/// I clienti di un trainer, con l'ultimo allenamento di ciascuno (US-089).
///
/// Compare nella Home solo per chi ha il ruolo trainer. Legge **un** provider
/// già composto e ordinato ([clientOverviewProvider]) e non conosce Firestore:
/// è ciò che permette di provarla con un widget test, a differenza delle altre
/// schermate che istanziano i servizi.
///
/// Chi è fermo da troppo tempo si riconosce a colpo d'occhio — bordo, striscia
/// e numero nel colore che nella palette significa «serve attenzione» — e sta
/// in cima. Chi non ha concesso gli allenamenti **non ha una data**: una riga
/// neutra lo dice, invece di un «mai» che sarebbe falso.
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final overview = ref.watch(clientOverviewProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('home')),
                  SizedBox(width: t.spacing.md),
                  Text(
                    loc.t('clients_title').toUpperCase(),
                    style: t.typography.headline?.copyWith(
                      fontSize: _kTitleFontSize,
                      color: scheme.onSurface,
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
              child: overview.when(
                // Mentre rilegge, l'elenco di prima resta a schermo: il
                // «tira per aggiornare» non lo svuota.
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Error(
                  message: loc.t('clients_error'),
                  retryLabel: loc.t('clients_retry'),
                  onRetry: () => ref.read(clientOverviewProvider.notifier).refresh(),
                ),
                data: (rows) => RefreshIndicator(
                  onRefresh: () => ref.read(clientOverviewProvider.notifier).refresh(),
                  child: rows.isEmpty
                      ? const _Empty()
                      : ListView.separated(
                          // Sempre scorrevole, anche con poche righe: senza,
                          // «tira per aggiornare» non parte con due clienti.
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(t.spacing.md),
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => SizedBox(height: t.spacing.md),
                          itemBuilder: (context, index) => _ClientTile(row: rows[index]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le frasi che il trainer legge per ogni cliente. Funzione pura, per
/// provarle senza montare la schermata.
String clientSubtitle(Localization loc, ClientRow row) {
  final giorni = row.daysSinceLastSession;
  switch (row.activity) {
    case ClientActivity.overdue:
      return loc.t('client_overdue').replaceFirst('%s', '$giorni');
    case ClientActivity.recent:
      final quando = switch (giorni) {
        0 => loc.t('client_when_today'),
        1 => loc.t('client_when_yesterday'),
        _ => loc.t('client_when_days_ago').replaceFirst('%s', '$giorni'),
      };
      return loc.t('client_last_session').replaceFirst('%s', quando);
    case ClientActivity.noSessions:
      return loc.t('client_no_sessions');
    case ClientActivity.notShared:
      return loc.t('client_not_shared');
  }
}

class _ClientTile extends ConsumerWidget {
  const _ClientTile({required this.row});

  final ClientRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final overdue = row.activity == ClientActivity.overdue;
    // `error` e il ruolo che significa «serve attenzione»: un cliente fermo non
    // e un errore, ma e l'unica cosa in questa schermata che deve saltare
    // all'occhio.
    final attenzione = overdue ? scheme.error : null;
    final giorni = row.daysSinceLastSession;
    return ExpressiveCard(
      padding: EdgeInsets.zero,
      borderColor: attenzione,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendDetailScreen(
            connectionId: row.clientId,
            displayName: row.name,
            since: row.since,
            invite: row.invite,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: _kStripeWidth, color: attenzione ?? scheme.outline),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(t.spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.name,
                            style: t.typography.title?.copyWith(color: scheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: t.spacing.xs),
                          Text(
                            clientSubtitle(loc, row),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: attenzione ?? scheme.onSurfaceVariant,
                              fontWeight: overdue ? FontWeight.w700 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Il numero grande solo dove c'è un numero vero.
                    if (giorni != null) ...[
                      SizedBox(width: t.spacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            giorni == 0 ? loc.t('client_when_today').toUpperCase() : '$giorni',
                            style: t.typography.headline?.copyWith(
                              color: attenzione ?? scheme.tertiary,
                            ),
                          ),
                          if (giorni > 0)
                            Text(
                              loc.t(giorni == 1 ? 'client_stat_day_ago' : 'client_stat_days_ago').toUpperCase(),
                              style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                        ],
                      ),
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

/// Un trainer senza clienti legge come invitarne uno, non una pagina vuota.
class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    // Scorrevole anche vuoto: il «tira per aggiornare» deve funzionare qui,
    // dove l'utente aspetta che compaia il cliente appena invitato.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.all(t.spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: t.sizing.thumbnailLg, color: scheme.onSurfaceVariant),
                SizedBox(height: t.spacing.md),
                Text(
                  loc.t('clients_empty_title'),
                  textAlign: TextAlign.center,
                  style: t.typography.title?.copyWith(color: scheme.onSurface),
                ),
                SizedBox(height: t.spacing.sm),
                Text(
                  loc.t('clients_empty_body'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: t.spacing.xl),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConnectFriendScreen()),
                  ),
                  child: Text(loc.t('clients_empty_cta')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            SizedBox(height: t.spacing.md),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
