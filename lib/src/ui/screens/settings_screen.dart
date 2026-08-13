import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/ui/screens/profile_screen.dart';
import 'package:gymflow/src/ui/screens/body_measurements_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:gymflow/src/services/health_service.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart'; // Added
import 'package:gymflow/src/core/providers/timer_settings_provider.dart';

/// Altezza del dialogo di scelta della posizione: geometria di questo
/// dialogo, non una spaziatura condivisa.
const double _kAltezzaDialogoMappa = 400;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Mock settings state for now
  bool _notificationsEnabled = true;

  final TextEditingController _gymNameController = TextEditingController();
  final TextEditingController _gymAddressController = TextEditingController();
  double? _gymLat;
  double? _gymLng;
  DateTime? _subscriptionExpiry;

  /// Vero mentre `_saveGymInfo` e in corso: disabilita il pulsante di
  /// aggiornamento, cosi un secondo tocco durante il salvataggio non parte
  /// una seconda scrittura.
  bool _isSaving = false;

  @override
  void dispose() {
    _gymNameController.dispose();
    _gymAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Providers
    final loc = ref.watch(localizationNotifierProvider);
    final theme = ref.watch(themeSettingsNotifierProvider);
    final themeNotifier = ref.read(themeSettingsNotifierProvider.notifier);
    final timerSettings = ref.watch(timerSettingsNotifierProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = context.expressive;

    // Preset del colore delle azioni. Ognuno supera WCAG AA sulle superfici
    // scure: la scelta e libera dentro un insieme che non produce testo
    // illeggibile. Verificato da test/contrast_test.dart
    final List<Color> colorPresets = AppPalette.accentPresets;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('settings_title')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;

          if (profile != null && _gymNameController.text.isEmpty) {
            _gymNameController.text = profile.gymName ?? '';
            _gymAddressController.text = profile.gymAddress ?? '';
            _gymLat = profile.gymLat;
            _gymLng = profile.gymLng;
            _subscriptionExpiry = profile.subscriptionExpiry;
          }

          return ListView(
            padding: EdgeInsets.all(t.spacing.xl),
            children: [
              // 1. Account Section
              _buildSectionHeader(context, loc.t('account_section')),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    title: loc.t('my_profile'),
                    subtitle: profile?.displayName ?? loc.t('guest_user'),
                    icon: Icons.person_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  _buildSettingsTile(
                    context,
                    title: loc.t('body_measurements'),
                    subtitle: loc.t('track_progress'),
                    icon: Icons.monitor_weight_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BodyMeasurementsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildSettingsTile(
                    context,
                    title: loc.t('subscription'),
                    subtitle: _subscriptionExpiry == null
                        ? loc.t('free_plan')
                        : '${loc.t('expires')}: ${_subscriptionExpiry!.toString().split(' ')[0]}',
                    icon: Icons.star_outline,
                    trailing: _subscriptionExpiry != null
                        ? _buildBadgeAbbonamento(context, scheme, t)
                        : null,
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _subscriptionExpiry ??
                            today.add(const Duration(days: 30)),
                        firstDate: today, // Allows selecting today
                        lastDate: today.add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() => _subscriptionExpiry = picked);
                        _saveGymInfo();
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: t.spacing.xl),

              // 2. Gym Section
              _buildSectionHeader(context, loc.t('gym_settings_section')),
              _buildSettingsCard(
                context,
                children: [
                  ExpansionTile(
                    leading: _buildLeadingIcona(context, scheme, t, Icons.fitness_center),
                    title: Text(
                      loc.t('gym_details'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _gymNameController.text.isNotEmpty
                          ? _gymNameController.text
                          : loc.t('set_name_address'),
                    ),
                    childrenPadding: EdgeInsets.all(t.spacing.md),
                    tilePadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.xs,
                    ),
                    shape: const Border(),
                    children: [
                      TextField(
                        controller: _gymNameController,
                        decoration: InputDecoration(
                          labelText: loc.t('gym_name_label'),
                          prefixIcon: const Icon(Icons.business),
                        ),
                      ),
                      SizedBox(height: t.spacing.sm),
                      TextField(
                        controller: _gymAddressController,
                        decoration: InputDecoration(
                          labelText: loc.t('address_label'),
                          prefixIcon: const Icon(Icons.place),
                        ),
                      ),
                      SizedBox(height: t.spacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveGymInfo,
                          child: _isSaving
                              ? SizedBox(
                                  width: t.sizing.iconSm,
                                  height: t.sizing.iconSm,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Text(loc.t('update_info_btn')),
                        ),
                      ),
                    ],
                  ),

                  _buildSettingsTile(
                    context,
                    title: loc.t('gym_location'),
                    subtitle: _gymLat != null
                        ? loc.t('location_pinned')
                        : loc.t('tap_to_set'),
                    icon: Icons.map_outlined,
                    onTap: _showMapPicker,
                  ),
                ],
              ),
              SizedBox(height: t.spacing.xl),

              // Integrations
              _buildSectionHeader(context, loc.t('integrations_section')),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    title: 'Google Fit / Health Connect',
                    subtitle: loc.t('sync_steps'),
                    icon: Icons.health_and_safety,
                    onTap: () async {
                      bool success = await HealthService().requestPermissions();
                      if (context.mounted) {
                        if (success) {
                          ToastUtils.showSuccess(
                            context,
                            loc.t('permissions_granted'),
                          );
                        } else {
                          // Allow user to check permissions
                        }
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: t.spacing.xl),

              // 3. Preferences Section
              _buildSectionHeader(context, loc.t('preferences_section')),
              _buildSettingsCard(
                context,
                children: [
                  // Language Selection
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.xs,
                    ),
                    leading: _buildLeadingIcona(context, scheme, t, Icons.language),
                    title: Text(
                      loc.t('language'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: loc.locale.languageCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'it',
                          child: Text('🇮🇹 Italiano'),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('🇬🇧 English'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(localizationNotifierProvider.notifier)
                              .setLocale(Locale(val));
                        }
                      },
                    ),
                  ),

                  // Color Picker
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.sm,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(t.spacing.sm),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: t.shape.cornerSm,
                      ),
                      child: Icon(Icons.color_lens, color: theme.primaryColor),
                    ),
                    title: Text(
                      loc.t('primary_color'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    subtitle: SizedBox(
                      height: t.sizing.thumbnailSm,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: colorPresets.map((color) {
                          final isSelected =
                              theme.primaryColor.toARGB32() ==
                              color.toARGB32();
                          return GestureDetector(
                            onTap: () => themeNotifier.setPrimaryColor(color),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: t.spacing.sm,
                                top: t.spacing.xs,
                              ),
                              width: t.sizing.iconLg + t.spacing.sm,
                              height: t.sizing.iconLg + t.spacing.sm,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: scheme.onSurface,
                                        width: 2,
                                      )
                                    : null,
                                boxShadow: t.elevation.level1(color),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: t.sizing.iconSm,
                                      color: AppPalette.indigo900,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.xs,
                    ),
                    secondary: _buildLeadingIcona(
                      context,
                      scheme,
                      t,
                      Icons.notifications_outlined,
                    ),
                    title: Text(
                      loc.t('notifications'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    value: _notificationsEnabled,
                    // Nessun colore qui: `SwitchThemeData` in `app_theme.dart`
                    // gia' distingue pollice (`onPrimary`) e binario (`primary`)
                    // da acceso. Forzare qui lo stesso ambra sul pollice li
                    // rendeva indistinguibili — una pillola unica, non uno
                    // switch con un pollice visibile.
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),

                  // Theme Selector
                  ListTile(
                    leading: _buildLeadingIcona(context, scheme, t, Icons.palette_outlined),
                    title: Text(
                      loc.t('app_theme'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      theme.themeMode == ThemeMode.system
                          ? loc.t('system')
                          : (theme.themeMode == ThemeMode.dark
                                ? loc.t('dark')
                                : loc.t('light')),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: theme.themeMode,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          themeNotifier.setThemeMode(newValue);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(loc.t('system')),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(loc.t('light')),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(loc.t('dark')),
                        ),
                      ],
                    ),
                  ),

                  // Vibrazione al tocco
                  SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.xs,
                    ),
                    secondary: _buildLeadingIcona(
                      context,
                      scheme,
                      t,
                      Icons.vibration,
                    ),
                    title: Text(
                      loc.t('haptic_feedback'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    value: theme.hapticFeedback,
                    onChanged: (val) => themeNotifier.setHapticFeedback(val),
                  ),
                ],
              ),
              SizedBox(height: t.spacing.xl),

              // Timer & Rest Section
              _buildSectionHeader(context, loc.t('timer_settings_section')),
              _buildSettingsCard(
                context,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.xs,
                    ),
                    secondary: _buildLeadingIcona(
                      context,
                      scheme,
                      t,
                      Icons.timer_outlined,
                    ),
                    title: Text(
                      loc.t('auto_rest_timer'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    subtitle: Text(loc.t('auto_rest_timer_desc')),
                    value: timerSettings.autoRestEnabled,
                    onChanged: (val) => ref
                        .read(timerSettingsNotifierProvider.notifier)
                        .setAutoRestEnabled(val),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.xs,
                    ),
                    leading: _buildLeadingIcona(
                      context,
                      scheme,
                      t,
                      Icons.hourglass_bottom,
                    ),
                    title: Text(
                      loc.t('default_rest_time'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    trailing: DropdownButton<int>(
                      value: timerSettings.defaultRestSeconds,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30s')),
                        DropdownMenuItem(value: 60, child: Text('60s')),
                        DropdownMenuItem(value: 90, child: Text('90s')),
                        DropdownMenuItem(value: 120, child: Text('120s')),
                        DropdownMenuItem(value: 180, child: Text('180s')),
                        DropdownMenuItem(value: 300, child: Text('300s')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(timerSettingsNotifierProvider.notifier)
                              .setDefaultRestSeconds(val);
                        }
                      },
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: t.spacing.md,
                      vertical: t.spacing.xs,
                    ),
                    secondary: _buildLeadingIcona(
                      context,
                      scheme,
                      t,
                      Icons.vibration_outlined,
                    ),
                    title: Text(
                      loc.t('vibrate_on_timer_end'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    value: timerSettings.vibrateOnTimerEnd,
                    onChanged: (val) => ref
                        .read(timerSettingsNotifierProvider.notifier)
                        .setVibrateOnTimerEnd(val),
                  ),
                ],
              ),
              SizedBox(height: t.spacing.xl),



              // Logout Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.all(t.spacing.md),
                    backgroundColor: AppPalette.danger.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: t.shape.cornerMd,
                    ),
                  ),
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppPalette.danger),
                  label: Text(
                    loc.t('sign_out'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPalette.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: t.spacing.xxl + t.spacing.sm),
            ],
          );
        },
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildBadgeAbbonamento(
    BuildContext context,
    ColorScheme scheme,
    ExpressiveTokens t,
  ) {
    final attiva = _subscriptionExpiry!.isAfter(DateTime.now());
    final colore = attiva ? AppPalette.success : AppPalette.danger;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.sm,
        vertical: t.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.2),
        borderRadius: t.shape.cornerSm,
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

  /// L'icona a sinistra di una voce, sempre nello stesso neutro: nessuna di
  /// queste destinazioni e "cosa fare adesso", quindi nessuna prende l'ambra.
  Widget _buildLeadingIcona(
    BuildContext context,
    ColorScheme scheme,
    ExpressiveTokens t,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(t.spacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: t.shape.cornerSm,
      ),
      child: Icon(icon, color: scheme.onSurfaceVariant),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(left: t.spacing.sm, bottom: t.spacing.md),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerLg,
        boxShadow: t.elevation.level2(scheme.shadow),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: t.spacing.xs,
      ),
      leading: _buildLeadingIcona(context, scheme, t, icon),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[trailing, SizedBox(width: t.spacing.sm)],
          Icon(
            Icons.chevron_right,
            color: scheme.onSurfaceVariant,
            size: t.sizing.iconMd,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showMapPicker() {
    final t = context.expressive;

    // Default to Rome if not set
    final initialCenter = _gymLat != null && _gymLng != null
        ? LatLng(_gymLat!, _gymLng!)
        : const LatLng(41.9028, 12.4964);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          height: _kAltezzaDialogoMappa,
          child: Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _gymLat = point.latitude;
                        _gymLng = point.longitude;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gymflow.app',
                    ),
                    if (_gymLat != null && _gymLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_gymLat!, _gymLng!),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: AppPalette.danger,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(t.spacing.sm),
                child: Text(ref.read(localizationNotifierProvider).t('tap_to_select_location')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGymInfo() async {
    setState(() => _isSaving = true);

    try {
      var userProfile = await AuthService().getUserProfile();

      // Fallback: If no Firestore doc exists, try to create from Auth
      if (userProfile == null) {
        final authUser = AuthService().currentUser;
        if (authUser != null) {
          userProfile = UserProfile(
            id: authUser.uid,
            email: authUser.email ?? '',
            displayName:
                authUser.displayName ??
                ref.read(localizationNotifierProvider).t('default_user_name'),
            createdAt: DateTime.now(),
          );
        } else {
          if (mounted) ToastUtils.showError(context, ref.read(localizationNotifierProvider).t('user_not_authenticated'));
          return;
        }
      }

      final updatedProfile = userProfile.copyWith(
        gymName: _gymNameController.text.trim(),
        gymAddress: _gymAddressController.text.trim(),
        gymLat: _gymLat,
        gymLng: _gymLng,
        subscriptionExpiry: _subscriptionExpiry,
      );

      debugPrint('Saving profile: ${updatedProfile.toMap()}'); // Debug log

      await AuthService().updateUserProfile(updatedProfile);

      if (mounted) {
        ToastUtils.showSuccess(
          context,
          ref.read(localizationNotifierProvider).t('gym_info_saved'),
        );
      }
    } catch (e) {
      debugPrint('Error saving gym info: $e');
      if (mounted) {
        ToastUtils.showError(
          context,
          '${ref.read(localizationNotifierProvider).t('info_save_error')}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
