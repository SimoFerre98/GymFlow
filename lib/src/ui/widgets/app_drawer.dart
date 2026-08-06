import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';

import 'package:gymflow/src/ui/screens/design_catalog_screen.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';
import 'package:gymflow/src/ui/screens/settings_screen.dart';
import 'package:gymflow/src/ui/screens/gamification_screen.dart';
import 'package:gymflow/src/ui/screens/connect_friend_screen.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = AuthService().currentUser;
    final loc = ref.watch(localizationNotifierProvider);

    return Drawer(
      child: Column(
        children: [
          // 1. Custom Premium Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  foregroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          (user?.displayName?.isNotEmpty == true)
                              ? user!.displayName![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName ?? loc.t('gymflow_user'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_filled,
                  title: loc.t('home'),
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: loc.t('settings_title'),
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // La libreria era raggiungibile solo entrando nella creazione
                // di una scheda: tutto il materiale visivo di EP-009 era di
                // fatto invisibile.
                _buildDrawerItem(
                  context,
                  icon: Icons.fitness_center_outlined,
                  title: loc.t('exercises_menu'),
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // In consultazione: dal menu si guarda la libreria,
                        // non si sceglie un esercizio per qualcos'altro.
                        builder: (_) => const ExerciseLibraryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context,
                  icon: Icons.emoji_events_outlined,
                  title: loc.t('achievements'),
                  color: Colors.amber,
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
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context,
                  icon: Icons.timer,
                  title: loc.t('stopwatch_menu'),
                  color: Colors.green,
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
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_add_alt_1,
                  title: loc.t('connect_friend'),
                  color: Colors.purple,
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

                // Catalogo del design system: solo nelle build di debug.
                if (DesignCatalogScreen.isAvailable) ...[
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Design system',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DesignCatalogScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
