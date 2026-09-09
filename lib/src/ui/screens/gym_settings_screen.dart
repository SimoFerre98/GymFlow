import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../widgets/back_pill.dart';
import '../widgets/toast_utils.dart';
/// Misure del mockup 3c Palestra (telaio 1:1, nessuna conversione px→dp).
const double _kTitleFontSize = 28;
const double _kMapHeight = 250;
/// Palestra e posizione: nome, indirizzo, mappa — gia campi reali di
/// `UserProfile` — piu gli amici che condividono la stessa palestra, calcolati
/// da `UserProfile.friends` invece di essere un dato a se.
///
/// Il mockup mostra anche un promemoria all'arrivo e un trio di statistiche
/// (sessioni qui, ore totali, dal anno X): il primo richiede geolocalizzazione
/// in background (una dipendenza nuova, da decidere con l'utente), il secondo
/// richiede legare le sessioni a una palestra — un cambio al modello dati che
/// non conterebbe le sessioni gia registrate. Gli orari di apertura invece non
/// avevano nessuno dei due ostacoli: aggiunti come campo reale.
class GymSettingsScreen extends ConsumerStatefulWidget {
  const GymSettingsScreen({super.key});
  @override
  ConsumerState<GymSettingsScreen> createState() => _GymSettingsScreenState();
}
class _GymSettingsScreenState extends ConsumerState<GymSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _loaded = false;
  bool _isSaving = false;
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }
  void _applyProfile(UserProfile profile) {
    if (_loaded) return;
    _nameController.text = profile.gymName ?? '';
    _addressController.text = profile.gymAddress ?? '';
    _hoursController.text = profile.gymOpeningHours ?? '';
    _lat = profile.gymLat;
    _lng = profile.gymLng;
    _loaded = true;
  }
  Future<void> _pickLocation() async {
    final t = context.immersivo;
    final initialCenter = _lat != null && _lng != null
        ? LatLng(_lat!, _lng!)
        : const LatLng(41.9028, 12.4964);
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _lat = point.latitude;
                        _lng = point.longitude;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gymflow.app',
                    ),
                    if (_lat != null && _lng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_lat!, _lng!),
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
  Future<void> _save() async {
    final loc = ref.read(localizationNotifierProvider);
    setState(() => _isSaving = true);
    try {
      var profile = await AuthService().getUserProfile();
      if (profile == null) {
        final authUser = AuthService().currentUser;
        if (authUser == null) {
          if (mounted) ToastUtils.showError(context, loc.t('user_not_authenticated'));
          return;
        }
        profile = UserProfile(
          id: authUser.uid,
          email: authUser.email ?? '',
          displayName: authUser.displayName ?? loc.t('default_user_name'),
          createdAt: DateTime.now(),
        );
      }
      final updated = profile.copyWith(
        gymName: _nameController.text.trim(),
        gymAddress: _addressController.text.trim(),
        gymOpeningHours: _hoursController.text.trim(),
        gymLat: _lat,
        gymLng: _lng,
      );
      await AuthService().updateUserProfile(updated);
      if (mounted) ToastUtils.showSuccess(context, loc.t('gym_info_saved'));
    } catch (e) {
      if (mounted) ToastUtils.showError(context, '${loc.t('info_save_error')}: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: AuthService().getUserProfileStream(),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            if (profile != null) _applyProfile(profile);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
                  child: Row(
                    children: [
                      BackPill(label: loc.t('settings_title')),
                      SizedBox(width: t.spacing.md),
                      Text(
                        loc.t('gym_settings_title').toUpperCase(),
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
                        _buildMap(context, loc, t, scheme),
                        SizedBox(height: t.spacing.lg),
                        _buildField(
                          context,
                          t,
                          scheme,
                          label: loc.t('gym_name_label'),
                          controller: _nameController,
                          accent: scheme.primary,
                        ),
                        SizedBox(height: t.spacing.md),
                        _buildField(
                          context,
                          t,
                          scheme,
                          label: loc.t('address_label'),
                          controller: _addressController,
                          accent: scheme.outline,
                        ),
                        SizedBox(height: t.spacing.md),
                        _buildField(
                          context,
                          t,
                          scheme,
                          label: loc.t('gym_hours_label'),
                          controller: _hoursController,
                          accent: scheme.outline,
                        ),
                        SizedBox(height: t.spacing.lg),
                        if (profile != null)
                          _FriendsAtGym(profile: profile, loc: loc),
                        SizedBox(height: t.spacing.xl),
                        _buildSaveCta(context, loc, t, scheme),
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
    );
  }
  Widget _buildMap(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return InkWell(
      onTap: _pickLocation,
      child: Container(
        height: _kMapHeight,
        decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
        child: _lat != null && _lng != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_lat!, _lng!),
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.gymflow.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_lat!, _lng!),
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_on, color: scheme.primary, size: 34),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: scheme.scrim.withValues(alpha: 0.7),
                      padding: EdgeInsets.symmetric(
                        horizontal: t.spacing.md,
                        vertical: t.spacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                              style: t.typography.eyebrow?.copyWith(color: scheme.onSurface),
                            ),
                          ),
                          Text(
                            loc.t('tap_to_select_location').toUpperCase(),
                            style: t.typography.eyebrow?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  loc.t('tap_to_set'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
      ),
    );
  }
  Widget _buildField(
    BuildContext context,
    ImmersivoTokens t,
    ColorScheme scheme, {
    required String label,
    required TextEditingController controller,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(t.spacing.md),
              suffixIcon: Icon(
                Icons.edit_outlined,
                size: t.sizing.iconSm,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSaveCta(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return InkWell(
      onTap: _isSaving ? null : _save,
      child: Container(
        height: t.sizing.minTouchTarget,
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
        color: scheme.primary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving)
              SizedBox(
                width: t.sizing.iconMd,
                height: t.sizing.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
              )
            else ...[
              Text(
                loc.t('update_info_btn').toUpperCase(),
                style: t.typography.title?.copyWith(color: scheme.onPrimary),
              ),
              SizedBox(width: t.spacing.sm),
              Icon(Icons.check, color: scheme.onPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
/// Amici che condividono la stessa palestra: reali, calcolati da
/// `UserProfile.friends` filtrando su `gymName`, non un dato a se stante.
class _FriendsAtGym extends StatelessWidget {
  const _FriendsAtGym({required this.profile, required this.loc});
  final UserProfile profile;
  final Localization loc;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final gymName = profile.gymName?.trim();
    if (gymName == null || gymName.isEmpty || profile.friends.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<UserProfile>>(
      future: FirestoreService().getUsers(profile.friends),
      builder: (context, snapshot) {
        final matches = (snapshot.data ?? const <UserProfile>[])
            .where((f) => f.gymName?.trim().toLowerCase() == gymName.toLowerCase())
            .toList();
        if (matches.isEmpty) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outline)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: t.spacing.md),
            child: Row(
              children: [
                Icon(Icons.groups_outlined, size: t.sizing.iconMd, color: scheme.onSurfaceVariant),
                SizedBox(width: t.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('friends_at_gym'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${matches.length} ${loc.t(matches.length == 1 ? 'friend_singular' : 'friends_plural')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
