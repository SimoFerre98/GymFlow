import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/timer_settings_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/health_service.dart';
import '../widgets/timer_aurora.dart';
import '../widgets/toast_utils.dart';
import 'appearance_settings_screen.dart';
import 'body_measurements_screen.dart';
import 'general_settings_screen.dart';
import 'gym_settings_screen.dart';
import 'profile_screen.dart';
import 'timer_settings_screen.dart';
/// Misure del mockup 3a Impostazioni indice (telaio 1:1, nessuna conversione
/// px→dp).
const double _kTitleFontSize = 28;
const double _kAvatarRadius = 26;
/// Indice delle impostazioni: solo navigazione verso le schermate dedicate
/// (Aspetto, Timer, Palestra, Generali) piu tre azioni reali dirette
/// (profilo, misure corporee, abbonamento) e il tasto per uscire.
///
/// Il mockup mostra anche un interruttore "Notifiche": nessun servizio di
/// notifiche push esiste in questo progetto (niente `firebase_messaging` ne
/// canale locale a parte quello del timer, gia gestito altrove) — l'unico
/// stato che lo sosteneva era una variabile locale che non veniva letta da
/// nessuna parte, quindi e stato tolto invece di restare un interruttore che
/// non fa nulla.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSavingSubscription = false;
  Future<void> _pickSubscriptionDate(UserProfile? profile) async {
    final loc = ref.read(localizationNotifierProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: profile?.subscriptionExpiry ?? today.add(const Duration(days: 30)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() => _isSavingSubscription = true);
    try {
      var updatedSource = profile;
      if (updatedSource == null) {
        final authUser = AuthService().currentUser;
        if (authUser == null) return;
        updatedSource = UserProfile(
          id: authUser.uid,
          email: authUser.email ?? '',
          displayName: authUser.displayName ?? loc.t('default_user_name'),
          createdAt: DateTime.now(),
        );
      }
      await AuthService().updateUserProfile(
        updatedSource.copyWith(subscriptionExpiry: picked),
      );
      if (mounted) ToastUtils.showSuccess(context, loc.t('gym_info_saved'));
    } catch (e) {
      if (mounted) ToastUtils.showError(context, '${loc.t('info_save_error')}: $e');
    } finally {
      if (mounted) setState(() => _isSavingSubscription = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final theme = ref.watch(themeSettingsNotifierProvider);
    final timerSettings = ref.watch(timerSettingsNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: TimerAurora()),
          SafeArea(
            child: StreamBuilder<UserProfile?>(
              stream: AuthService().getUserProfileStream(),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
                      child: Row(
                        children: [
                          Text(
                            loc.t('settings_title').toUpperCase(),
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
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(t.spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileCard(context, loc, t, scheme, profile),
                            SizedBox(height: t.spacing.lg),
                            _buildSectionHeader(context, loc.t('account_section')),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.person_outline,
                              iconColor: scheme.primary,
                              title: loc.t('my_profile'),
                              subtitle: profile?.displayName ?? loc.t('guest_user'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              ),
                            ),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.monitor_weight_outlined,
                              iconColor: scheme.tertiary,
                              title: loc.t('body_measurements'),
                              subtitle: loc.t('track_progress'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BodyMeasurementsScreen()),
                              ),
                            ),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.star_outline,
                              iconColor: scheme.primary,
                              title: loc.t('subscription'),
                              subtitle: profile?.subscriptionExpiry == null
                                  ? loc.t('free_plan')
                                  : '${loc.t('expires')}: ${profile!.subscriptionExpiry!.toString().split(' ')[0]}',
                              trailing: profile?.subscriptionExpiry != null
                                  ? _buildBadgeAbbonamento(context, scheme, t, profile!)
                                  : null,
                              isLast: true,
                              onTap: _isSavingSubscription ? null : () => _pickSubscriptionDate(profile),
                            ),
                            SizedBox(height: t.spacing.lg),
                            _buildSectionHeader(context, loc.t('gym_settings_section')),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.business_outlined,
                              iconColor: scheme.onSurfaceVariant,
                              title: loc.t('gym_details'),
                              subtitle: (profile?.gymName?.isNotEmpty ?? false)
                                  ? profile!.gymName!
                                  : loc.t('set_name_address'),
                              isLast: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GymSettingsScreen()),
                              ),
                            ),
                            SizedBox(height: t.spacing.lg),
                            _buildSectionHeader(context, loc.t('app_section')),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.palette_outlined,
                              iconColor: scheme.primary,
                              title: loc.t('appearance_title'),
                              subtitle: loc.t('appearance_index_subtitle'),
                              trailing: Container(width: 16, height: 16, color: theme.primaryColor),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
                              ),
                            ),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.access_time,
                              iconColor: scheme.onSurfaceVariant,
                              title: loc.t('timer_settings_section_title'),
                              subtitle: timerSettings.autoRestEnabled
                                  ? '${loc.t('auto_label')} · ${timerSettings.defaultRestSeconds}s'
                                  : '${loc.t('manual_label')} · ${timerSettings.defaultRestSeconds}s',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TimerSettingsScreen()),
                              ),
                            ),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.language,
                              iconColor: scheme.onSurfaceVariant,
                              title: loc.t('general_settings_section_title'),
                              subtitle: loc.locale.languageCode == 'it'
                                  ? loc.t('language_name_it')
                                  : loc.t('language_name_en'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()),
                              ),
                            ),
                            _buildTile(
                              context,
                              t,
                              scheme,
                              icon: Icons.health_and_safety_outlined,
                              iconColor: scheme.tertiary,
                              title: 'Google Fit / Health Connect',
                              subtitle: loc.t('sync_steps'),
                              isLast: true,
                              onTap: () async {
                                final success = await HealthService().requestPermissions();
                                if (context.mounted && success) {
                                  ToastUtils.showSuccess(context, loc.t('permissions_granted'));
                                }
                              },
                            ),
                            SizedBox(height: t.spacing.xl),
                            _buildSignOut(context, loc, t),
                            SizedBox(height: t.spacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProfileCard(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    UserProfile? profile,
  ) {
    final imageProvider = profile?.photoUrl != null ? NetworkImage(profile!.photoUrl!) : null;
    final subscriptionActive = profile?.subscriptionExpiry?.isAfter(DateTime.now()) ?? false;
    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _kAvatarRadius,
            backgroundColor: scheme.surfaceContainer,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.person, size: _kAvatarRadius, color: scheme.onSurfaceVariant)
                : null,
          ),
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? loc.t('guest_user'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  profile?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (subscriptionActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: t.spacing.sm, vertical: t.spacing.xs),
              decoration: BoxDecoration(
                color: AppPalette.success.withValues(alpha: 0.18),
                border: Border.all(color: AppPalette.success),
              ),
              child: Text(
                loc.t('subscription_active').toUpperCase(),
                style: t.typography.eyebrow?.copyWith(color: AppPalette.success),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildBadgeAbbonamento(
    BuildContext context,
    ColorScheme scheme,
    ImmersivoTokens t,
    UserProfile profile,
  ) {
    final attiva = profile.subscriptionExpiry!.isAfter(DateTime.now());
    final colore = attiva ? AppPalette.success : AppPalette.danger;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.sm, vertical: t.spacing.xs),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.2),
        border: Border.all(color: colore),
      ),
      child: Text(
        attiva
            ? ref.read(localizationNotifierProvider).t('subscription_active')
            : ref.read(localizationNotifierProvider).t('subscription_expired'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colore,
        ),
      ),
    );
  }
  Widget _buildSectionHeader(BuildContext context, String title) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outline))),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
        child: Text(title.toUpperCase(), style: t.typography.eyebrow),
      ),
    );
  }
  Widget _buildTile(
    BuildContext context,
    ImmersivoTokens t,
    ColorScheme scheme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isLast = false,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
            bottom: isLast ? BorderSide(color: scheme.outline) : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
          child: Row(
            children: [
              Icon(icon, size: t.sizing.iconMd, color: iconColor),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[trailing, SizedBox(width: t.spacing.sm)],
              Icon(Icons.chevron_right, size: t.sizing.iconSm, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSignOut(BuildContext context, Localization loc, ImmersivoTokens t) {
    return InkWell(
      onTap: () async {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: t.spacing.md),
        decoration: BoxDecoration(
          color: AppPalette.danger.withValues(alpha: 0.12),
          border: Border.all(color: AppPalette.danger.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppPalette.danger),
            SizedBox(width: t.spacing.sm),
            Text(
              loc.t('sign_out'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPalette.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
