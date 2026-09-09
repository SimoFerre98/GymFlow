import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/models/body_measurement.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gymflow/src/ui/widgets/sparkline.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'body_measurements_screen.dart';
/// Misure del mockup 3b Profilo e misure (telaio 1:1, nessuna conversione
/// px→dp).
const double _kHeroHeight = 300;
const double _kNameFontSize = 46;
const double _kStatValueFontSize = 30;
const double _kStatLabelFontSize = 9;
const double _kIconBoxSide = 38;
/// Profilo e misure: la foto, il nome, e i dati reali di [UserProfile] —
/// peso/altezza/massa grassa e la sparkline vengono dall'ultima
/// [BodyMeasurement], non da un campo che nessuno scrive piu.
///
/// Il mockup mostra anche "LIVELLO 7", "Obiettivo: FORZA" e "Livello:
/// INTERMEDIO": nessuno dei tre ha un campo — non esiste ne un sistema di
/// livelli ne un obiettivo salvabile — quindi il badge diventa "membro da N
/// mesi" (calcolato da `createdAt`, un fatto vero) e le due righe DATI
/// spariscono invece di mostrare un valore inventato.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  late TextEditingController _nameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  UserProfile? _profile;
  bool _loaded = false;
  bool _isSaving = false;
  File? _imageFile;
  DateTime? _birthDate;
  String? _gender;
  UserRole _role = UserRole.athlete;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }
  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
  void _applyProfile(UserProfile profile) {
    if (_loaded) return;
    _profile = profile;
    _nameController.text = profile.displayName;
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _birthDate = profile.birthDate;
    _gender = profile.gender;
    _role = profile.role;
    _loaded = true;
  }
  int _monthsSince(DateTime start) {
    final now = DateTime.now();
    var months = (now.year - start.year) * 12 + (now.month - start.month);
    if (now.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Un ritratto non ha bisogno della risoluzione della foto originale: senza
    // un limite, una foto di un telefono recente pesa diversi MB e va tutta
    // su Storage, che sul piano gratuito ha un tetto di 5 GB totali condiviso
    // da tutti gli utenti. 1024 px e qualita 85 restano nitidi su un ritratto
    // e riducono il peso di un ordine di grandezza.
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
      _saveProfile(silent: true);
    }
  }
  Future<void> _pickGender() async {
    final loc = ref.read(localizationNotifierProvider);
    final options = <(String, String)>[
      ('male', loc.t('gender_male')),
      ('female', loc.t('gender_female')),
      ('other', loc.t('gender_other')),
    ];
    final picked = await _showOptionPicker(loc.t('gender_label'), options);
    if (picked != null) {
      setState(() => _gender = picked);
      _saveProfile(silent: true);
    }
  }
  Future<void> _pickRole() async {
    final loc = ref.read(localizationNotifierProvider);
    final options = <(UserRole, String)>[
      (UserRole.athlete, loc.t('role_athlete')),
      (UserRole.trainer, loc.t('role_trainer')),
      (UserRole.both, loc.t('role_both')),
    ];
    final picked = await _showOptionPicker(loc.t('role_label'), options);
    if (picked != null) {
      setState(() => _role = picked);
      _saveProfile(silent: true);
    }
  }
  Future<T?> _showOptionPicker<T>(String title, List<(T, String)> options) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(title),
        children: [
          for (final (value, label) in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Text(label),
            ),
        ],
      ),
    );
  }
  Future<void> _editName() async {
    final loc = ref.read(localizationNotifierProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.t('edit_name_dialog_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.t('username_label')),
            ),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: loc.t('first_name')),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: loc.t('last_name')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.t('done')),
          ),
        ],
      ),
    );
    if (saved == true) {
      setState(() {});
      _saveProfile(silent: true);
    }
  }
  Future<void> _saveProfile({bool silent = false}) async {
    if (_profile == null) return;
    final loc = ref.read(localizationNotifierProvider);
    setState(() => _isSaving = true);
    String? photoUrl = _profile!.photoUrl;
    if (_imageFile != null) {
      // Nome fisso per utente, non un timestamp: chi cambia foto dieci volte
      // sovrascrive lo stesso file invece di lasciarne nove abbandonati su
      // Storage. Senza, i 5 GB del piano gratuito si consumano da soli con
      // l'uso normale — nessuno li libera mai perche nessuno li cancella.
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${_profile!.id}.jpg');
      try {
        await storageRef.putFile(_imageFile!);
        photoUrl = await storageRef.getDownloadURL();
        // Il nome del file non cambia piu tra un salvataggio e il successivo,
        // quindi neanche l'URL: senza svuotare la cache delle immagini, la
        // vecchia foto resterebbe a schermo finche l'app non riparte.
        if (mounted) await NetworkImage(photoUrl).evict();
      } catch (e) {
        if (mounted) ToastUtils.showError(context, '${loc.t('upload_failed')}: $e');
        setState(() => _isSaving = false);
        return;
      }
    }
    // `copyWith` e non un `UserProfile(...)` scritto da zero: quest'ultimo
    // esisteva prima e non passava `friends`, `calendarSharedWith`,
    // `programsSharedWith` — tornavano `const []` a ogni salvataggio, quindi
    // ogni volta che si aggiornava il profilo si perdeva la lista amici e le
    // condivisioni. `copyWith` porta avanti quello che non viene toccato qui.
    final updatedProfile = _profile!.copyWith(
      displayName: _nameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      photoUrl: photoUrl,
      birthDate: _birthDate,
      gender: _gender,
      role: _role,
    );
    try {
      await _auth.updateUserProfile(updatedProfile);
      _profile = updatedProfile;
      _imageFile = null;
      if (mounted && !silent) {
        ToastUtils.showSuccess(context, loc.t('profile_updated'));
      }
    } catch (e) {
      if (mounted) ToastUtils.showError(context, '${loc.t('profile_save_failed')}: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  String _displayName(UserProfile profile) {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) return profile.displayName;
    return '$first\n$last'.trim();
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: StreamBuilder<UserProfile?>(
        stream: _auth.getUserProfileStream(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _applyProfile(profile);
          return StreamBuilder<List<BodyMeasurement>>(
            stream: _firestore.getBodyMeasurements(profile.id),
            builder: (context, measurementsSnapshot) {
              final measurements = measurementsSnapshot.data ?? const <BodyMeasurement>[];
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(context, loc, t, scheme, profile),
                    _buildStatsTrio(context, loc, t, scheme, measurements),
                    _buildWeightTrend(context, loc, t, scheme, measurements),
                    _buildDati(context, loc, t, scheme, profile, measurements),
                    Padding(
                      padding: EdgeInsets.all(t.spacing.md),
                      child: _buildSaveCta(context, loc, t, scheme),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  Widget _buildHero(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    UserProfile profile,
  ) {
    final imageProvider = _imageFile != null
        ? FileImage(_imageFile!) as ImageProvider
        : (profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null);
    final months = _monthsSince(profile.createdAt);
    return Stack(
      children: [
        SizedBox(
          height: _kHeroHeight + MediaQuery.of(context).padding.top,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageProvider != null)
                Image(image: imageProvider, fit: BoxFit.cover)
              else
                Container(
                  color: scheme.surfaceContainer,
                  child: Icon(Icons.person, size: _kHeroHeight / 2, color: scheme.onSurfaceVariant),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.scrim.withValues(alpha: 0.5),
                      scheme.scrim.withValues(alpha: 0.1),
                      scheme.scrim.withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.32, 0.95],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.sm),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: _kIconBoxSide,
                      height: _kIconBoxSide,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.scrim.withValues(alpha: 0.7),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Icon(Icons.chevron_left, color: scheme.onSurface),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: _kIconBoxSide,
                      height: _kIconBoxSide,
                      alignment: Alignment.center,
                      color: scheme.primary,
                      child: Icon(Icons.camera_alt, color: scheme.onPrimary, size: t.sizing.iconSm),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: t.spacing.md,
          right: t.spacing.md,
          bottom: t.spacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: t.spacing.sm, vertical: t.spacing.xs),
                color: scheme.primary,
                child: Text(
                  (months > 0
                          ? '${loc.t('member_since_label')} $months ${loc.t(months == 1 ? 'month_singular' : 'months_plural')}'
                          : loc.t('member_since_recent'))
                      .toUpperCase(),
                  style: t.typography.eyebrow?.copyWith(color: scheme.onPrimary),
                ),
              ),
              SizedBox(height: t.spacing.sm),
              Text(
                _displayName(profile).toUpperCase(),
                style: t.typography.headline?.copyWith(
                  fontSize: _kNameFontSize,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildStatsTrio(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    List<BodyMeasurement> measurements,
  ) {
    final latest = measurements.isNotEmpty ? measurements.first : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline), bottom: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: loc.t('weight_stat_label'),
              value: latest?.weight,
              unit: loc.t('bm_kg'),
              valueColor: scheme.primary,
              border: Border(right: BorderSide(color: scheme.outline)),
            ),
          ),
          Expanded(
            child: _StatCell(
              label: loc.t('height_stat_label'),
              value: latest?.height,
              unit: loc.t('bm_cm'),
              valueColor: scheme.onSurface,
              border: Border(right: BorderSide(color: scheme.outline)),
            ),
          ),
          Expanded(
            child: _StatCell(
              label: loc.t('body_fat_stat_label'),
              value: latest?.bodyFatPercentage,
              unit: loc.t('bm_percent'),
              valueColor: scheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildWeightTrend(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    List<BodyMeasurement> measurements,
  ) {
    // Le ultime 12 rilevazioni con un peso registrato, dalla piu vecchia alla
    // piu recente: `measurements` arriva gia ordinata dalla piu recente (per
    // Firestore), va invertita per disegnare la sparkline da sinistra a destra.
    final weights = measurements
        .where((m) => m.weight != null)
        .take(12)
        .toList()
        .reversed
        .map((m) => m.weight!)
        .toList();
    if (weights.length < 2) return const SizedBox.shrink();
    final delta = weights.last - weights.first;
    final deltaText = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} ${loc.t('bm_kg')}';
    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.md, t.spacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.t('weight_trend_label'),
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                deltaText,
                style: t.typography.eyebrow?.copyWith(color: scheme.tertiary),
              ),
            ],
          ),
          SizedBox(height: t.spacing.sm),
          SizedBox(
            width: double.infinity,
            child: Sparkline(values: weights, color: scheme.tertiary, height: 70),
          ),
        ],
      ),
    );
  }
  Widget _buildDati(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    UserProfile profile,
    List<BodyMeasurement> measurements,
  ) {
    final latest = measurements.isNotEmpty ? measurements.first : null;
    final circumferenceCount = latest == null
        ? 0
        : [
            latest.chest,
            latest.waist,
            latest.hips,
            latest.biceps,
            latest.thighs,
            latest.calves,
            latest.shoulders,
            latest.neck,
          ].where((v) => v != null).length;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.md, vertical: t.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('info_section').toUpperCase(),
            style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
          ),
          _DatiRow(
            label: loc.t('username_label'),
            value: profile.displayName,
            onTap: _editName,
          ),
          _DatiRow(
            label: loc.t('birth_date_label'),
            value: _birthDate != null
                ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                : loc.t('not_set_value'),
            onTap: _selectDate,
          ),
          _DatiRow(
            label: loc.t('gender_label'),
            value: _gender == null ? loc.t('not_set_value') : loc.t('gender_$_gender'),
            onTap: _pickGender,
          ),
          _DatiRow(
            label: loc.t('role_label'),
            value: loc.t(switch (_role) {
              UserRole.athlete => 'role_athlete',
              UserRole.trainer => 'role_trainer',
              UserRole.both => 'role_both',
            }),
            onTap: _pickRole,
          ),
          _DatiRow(
            label: loc.t('circumferences_label'),
            value: '$circumferenceCount ${loc.t('measurements_count_label')}',
            isLast: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BodyMeasurementsScreen()),
            ),
          ),
          SizedBox(height: t.spacing.md),
          Row(
            children: [
              Icon(Icons.email_outlined, size: t.sizing.iconSm, color: scheme.onSurfaceVariant),
              SizedBox(width: t.spacing.sm),
              Text(
                profile.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSaveCta(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return InkWell(
      onTap: _isSaving ? null : () => _saveProfile(),
      child: Container(
        height: t.sizing.minTouchTarget,
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
                loc.t('save').toUpperCase(),
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
/// Una cella della tripletta peso/altezza/massa grassa: etichetta piccola,
/// valore grande, unita accanto. "—" se l'ultima misurazione non ha quel
/// campo (es. la massa grassa e facoltativa).
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    this.border,
  });
  final String label;
  final double? value;
  final String unit;
  final Color valueColor;
  final Border? border;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(border: border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.typography.eyebrow?.copyWith(
              fontSize: _kStatLabelFontSize,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: t.spacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value != null ? value!.toStringAsFixed(value! % 1 == 0 ? 0 : 1) : '—',
                style: t.typography.headline?.copyWith(fontSize: _kStatValueFontSize, color: valueColor),
              ),
              if (value != null) ...[
                SizedBox(width: t.spacing.xs),
                Text(
                  unit,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
/// Una riga della sezione DATI: etichetta, valore, freccia — tocca per
/// modificare (data di nascita, genere, ruolo, nome) o per aprire le misure
/// corporee complete.
class _DatiRow extends StatelessWidget {
  const _DatiRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
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
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                value,
                style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(width: t.spacing.sm),
              Icon(Icons.chevron_right, size: t.sizing.iconSm, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
