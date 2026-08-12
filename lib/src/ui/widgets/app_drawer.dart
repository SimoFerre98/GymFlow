import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';

import 'package:gymflow/src/ui/screens/settings_screen.dart';
import 'package:gymflow/src/ui/screens/gamification_screen.dart';
import 'package:gymflow/src/ui/screens/connect_friend_screen.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';
import 'expressive_card.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          Container(
            color: scheme.surfaceContainerHigh,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(t.spacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: t.sizing.thumbnailMd / 2,
                      backgroundColor: scheme.surface,
                      foregroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                              (user?.displayName?.isNotEmpty == true)
                                  ? user!.displayName![0].toUpperCase()
                                  : 'U',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: scheme.onSurface),
                            )
                          : null,
                    ),
                    SizedBox(width: t.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.displayName ?? loc.t('gymflow_user'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(t.spacing.md),
              children: [
                _VoceMenu(
                  icon: Icons.home_filled,
                  title: loc.t('home'),
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                ),
                SizedBox(height: t.spacing.sm),
                _VoceMenu(
                  icon: Icons.settings_outlined,
                  title: loc.t('settings_title'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                SizedBox(height: t.spacing.sm),
                _VoceMenu(
                  icon: Icons.emoji_events_outlined,
                  title: loc.t('achievements'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GamificationScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: t.spacing.sm),
                _VoceMenu(
                  icon: Icons.timer,
                  title: loc.t('stopwatch_menu'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TimeToolsScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: t.spacing.sm),
                _VoceMenu(
                  icon: Icons.person_add_alt_1,
                  title: loc.t('connect_friend'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectFriendScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una destinazione del cassetto.
///
/// Un solo colore per tutte le icone, non un'icona ciascuna: nessuna di
/// queste e "cosa fare adesso", quindi nessuna prende l'ambra. Distinguerle
/// con un colore diverso a testa avrebbe reintrodotto la stessa confusione
/// gia risolta nella barra di navigazione.
class _VoceMenu extends StatelessWidget {
  const _VoceMenu({required this.icon, required this.title, required this.onTap});

  /// Il 5% in meno di `spacing.md` (16): l'utente ha chiesto righe un po piu
  /// compatte nel cassetto, a icona e testo invariati — solo lo spazio
  /// intorno si stringe.
  static const double _paddingVerticale = 15;

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: _paddingVerticale,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(t.spacing.sm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: t.shape.cornerSm,
            ),
            child: Icon(icon, color: scheme.onSurfaceVariant, size: t.sizing.iconMd),
          ),
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: t.sizing.iconSm,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
