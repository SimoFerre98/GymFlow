import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../../models/body_measurement.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../ui/widgets/back_pill.dart';
import '../../ui/widgets/set_value_slider.dart';
import '../../ui/widgets/toast_utils.dart';
/// Misure del telaio Immersivo (BackPill+titolo+filetto, campi a bordo
/// sottile), non di un mockup dedicato: nessuna delle due sorgenti copre
/// questa schermata, quindi il vocabolario dei token si applica cosi com'e
/// altrove — non e disegno nuovo.
const double _kTitleFontSize = 28;
/// Schermata per registrare peso e misure corporee.
///
/// Il peso si imposta con [SetValueSlider] (US-046) o digitandolo dopo un tap
/// sul valore: `onTapValue` apre un dialog con campo numerico, la via d'uscita
/// da tastiera per valori fuori scala.
///
/// Estremi del cursore: **30–250 kg**, passo 0,1 kg.
/// 30 kg copre gli adolescenti leggeri, 250 kg i sollevatori piu pesanti.
/// Un cursore che non arriva al peso dell'utente e peggio della tastiera:
/// il dialog di inserimento diretto copre comunque qualsiasi valore.
///
/// Il peso letto da Salute NON viene importato: la schermata salva solo cio
/// che l'utente imposta esplicitamente. Se un giorno arrivera l'integrazione
/// con Health, il salvataggio manuale non dovra essere sovrascritto.
/// I campi di misura, con la chiave del modello e quelle delle etichette.
///
/// L'elenco sta qui e non sparso nel widget perche deve restare **allineato ai
/// campi di `BodyMeasurement`**: se il modello ne guadagna uno e questo elenco
/// no, il dato diventa salvabile e non rivedibile. Un test lo verifica.
class _CampoMisura {
  const _CampoMisura(this.chiave, this.chiaveEtichetta, this.chiaveUnita);
  final String chiave;
  final String chiaveEtichetta;
  final String chiaveUnita;
}
const _campiMisura = <_CampoMisura>[
  _CampoMisura('height', 'bm_height', 'bm_cm'),
  _CampoMisura('chest', 'bm_chest', 'bm_cm'),
  _CampoMisura('waist', 'bm_waist', 'bm_cm'),
  _CampoMisura('hips', 'bm_hips', 'bm_cm'),
  _CampoMisura('biceps', 'bm_arms', 'bm_cm'),
  _CampoMisura('thighs', 'bm_thighs', 'bm_cm'),
  _CampoMisura('calves', 'bm_calves', 'bm_cm'),
  _CampoMisura('shoulders', 'bm_shoulders', 'bm_cm'),
  _CampoMisura('neck', 'bm_neck', 'bm_cm'),
  _CampoMisura('bodyFat', 'bm_body_fat', 'bm_percent'),
];
class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});
  @override
  ConsumerState<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}
class _BodyMeasurementsScreenState
    extends ConsumerState<BodyMeasurementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final String _userId;
  double _currentWeight = 70.0;
  /// Un controller per ogni campo che `BodyMeasurement` sa registrare.
  ///
  /// Sono undici perche undici sono i campi del modello: una schermata che ne
  /// mostra meno rende i dati gia salvati invisibili e non piu aggiornabili,
  /// senza cancellarli — che e il modo peggiore di perderli.
  final _controllers = <String, TextEditingController>{
    'height': TextEditingController(),
    'chest': TextEditingController(),
    'waist': TextEditingController(),
    'hips': TextEditingController(),
    'biceps': TextEditingController(),
    'thighs': TextEditingController(),
    'calves': TextEditingController(),
    'shoulders': TextEditingController(),
    'neck': TextEditingController(),
    'bodyFat': TextEditingController(),
  };
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _userId = AuthService().currentUser?.uid ?? '';
  }
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  // ── Salvataggio ───────────────────────────────────────────
  Future<void> _save() async {
    if (_userId.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      double? valore(String chiave) =>
          double.tryParse(_controllers[chiave]!.text.replaceAll(',', '.'));
      final measurement = BodyMeasurement(
        id: '',
        userId: _userId,
        date: DateTime.now(),
        weight: _currentWeight,
        height: valore('height'),
        chest: valore('chest'),
        waist: valore('waist'),
        hips: valore('hips'),
        biceps: valore('biceps'),
        thighs: valore('thighs'),
        calves: valore('calves'),
        shoulders: valore('shoulders'),
        neck: valore('neck'),
        bodyFatPercentage: valore('bodyFat'),
      );
      await _firestoreService.addBodyMeasurement(_userId, measurement);
      if (mounted) {
        final loc = ref.read(localizationNotifierProvider);
        ToastUtils.showSuccess(context, loc.t('measurements_saved'));
        for (final c in _controllers.values) {
          c.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '$e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  // ── Dialog per inserimento peso da tastiera ───────────────
  void _showWeightDialog() {
    final loc = ref.read(localizationNotifierProvider);
    final controller = TextEditingController(
      text: _currentWeight.toStringAsFixed(1),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.t('enter_weight')),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(suffixText: loc.t('bm_kg')),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(loc.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  setState(() => _currentWeight = value);
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(loc.t('done')),
            ),
          ],
        );
      },
    );
  }
  // ── UI ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    if (_userId.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
                child: _buildHeader(context, loc, t, scheme),
              ),
              Expanded(child: Center(child: Text(loc.t('login_required')))),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: _buildHeader(context, loc, t, scheme),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(t.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Peso attuale ──────────────────────────────
                    Text(
                      loc.t('current_weight').toUpperCase(),
                      style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    SizedBox(height: t.spacing.sm),
                    SetValueSlider(
                      label: loc.t('bm_kg'),
                      value: _currentWeight,
                      min: 30.0,
                      max: 250.0,
                      step: 0.1,
                      formatValue: (v) => v.toStringAsFixed(1),
                      semanticUnit: 'kg',
                      onChanged: (v) => setState(() => _currentWeight = v),
                      onTapValue: _showWeightDialog,
                    ),
                    SizedBox(height: t.spacing.xl),
                    // ── Misure corporee ───────────────────────────
                    Text(
                      loc.t('body_measures_section').toUpperCase(),
                      style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    SizedBox(height: t.spacing.sm),
                    // Ogni campo che il modello sa registrare ha il suo posto qui: una
                    // misura senza campo e un dato che si puo salvare e non rivedere.
                    for (final campo in _campiMisura) ...[
                      _MeasureField(
                        controller: _controllers[campo.chiave]!,
                        label: loc.t(campo.chiaveEtichetta),
                        unit: loc.t(campo.chiaveUnita),
                      ),
                      SizedBox(height: t.spacing.sm),
                    ],
                    SizedBox(height: t.spacing.md),
                    // ── Pulsante salva ────────────────────────────
                    _buildSaveCta(context, loc, t, scheme),
                    SizedBox(height: t.spacing.xxl),
                    // ── Storico ───────────────────────────────────
                    Text(
                      loc.t('weight_history').toUpperCase(),
                      style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    _WeightHistory(
                      userId: _userId,
                      firestoreService: _firestoreService,
                      emptyText: loc.t('no_measurements'),
                    ),
                    SizedBox(height: t.spacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        BackPill(label: loc.t('settings_title')),
        SizedBox(width: t.spacing.md),
        Text(
          loc.t('body_measurements_title').toUpperCase(),
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
        width: double.infinity,
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
                loc.t('done').toUpperCase(),
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
// ── Campo di misura ───────────────────────────────────────────
class _MeasureField extends StatelessWidget {
  const _MeasureField({
    required this.controller,
    required this.label,
    required this.unit,
  });
  final TextEditingController controller;
  final String label;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(left: BorderSide(color: scheme.outline, width: 3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(t.spacing.md),
          labelText: label,
          suffixText: unit,
          suffixIcon: Icon(
            Icons.edit_outlined,
            size: t.sizing.iconSm,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
// ── Storico pesi ──────────────────────────────────────────────
/// I dieci pesi piu recenti, in ascolto via stream.
///
/// Widget separato per evitare di creare lo stream dentro `build` della
/// schermata principale: lo stream vive qui, viene creato una volta sola
/// e non si ricrea a ogni ricostruzione dell'albero.
class _WeightHistory extends StatelessWidget {
  const _WeightHistory({
    required this.userId,
    required this.firestoreService,
    required this.emptyText,
  });
  final String userId;
  final FirestoreService firestoreService;
  final String emptyText;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.immersivo;
    return StreamBuilder<List<BodyMeasurement>>(
      stream: firestoreService.getBodyMeasurements(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: t.spacing.xl),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data ?? [];
        final recent = all.take(10).toList();
        if (recent.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: t.spacing.xl),
            child: Center(
              child: Text(
                emptyText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final m in recent) _HistoryTile(measurement: m),
          ],
        );
      },
    );
  }
}
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.measurement});
  final BodyMeasurement measurement;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.immersivo;
    final dateText = DateFormat('d MMM yyyy').format(measurement.date);
    final weightText = measurement.weight != null
        ? '${measurement.weight!.toStringAsFixed(1)} kg'
        : '—';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.55))),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              weightText,
              style: t.typography.metricSmall?.copyWith(color: scheme.onSurface) ??
                  TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
