import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../core/utils/personal_record.dart';
import '../../models/workout.dart';
import 'set_value_slider.dart';

/// Quanto vale una serie, deciso trascinando.
///
/// Sostituisce tre campi numerici larghi poche decine di pixel, che con le mani
/// sudate fra due serie erano il punto in cui l'app costava piu tempo di quanto
/// ne facesse risparmiare.
///
/// E un foglio e non una riscrittura della sessione di proposito: la tabella
/// resta dov'e e continua a mostrare i valori. Questa storia cambia **come si
/// inseriscono**, non come si vedono.
class SetEditorSheet extends ConsumerStatefulWidget {
  const SetEditorSheet({
    super.key,
    required this.set,
    required this.setNumber,
    required this.exerciseName,
    this.exerciseId,
    this.personalBest,
    this.previous,
    this.showWeight = true,
  });

  final WorkoutSet set;
  final int setNumber;
  final String exerciseName;
  final String? exerciseId;

  /// Il massimo storico precedente per questo esercizio, se presente.
  final PersonalBest? personalBest;

  /// La serie precedente dello stesso esercizio, se c'e: da qui vengono i
  /// valori di partenza, ed e quella mostrata in cima come riferimento.
  final WorkoutSet? previous;

  /// Falso per gli esercizi a corpo libero, dove il carico non ha senso.
  final bool showWeight;

  /// Apre il foglio e restituisce i valori scelti, o `null` se si e annullato.
  static Future<SetValues?> show(
    BuildContext context, {
    required WorkoutSet set,
    required int setNumber,
    required String exerciseName,
    String? exerciseId,
    PersonalBest? personalBest,
    WorkoutSet? previous,
    bool showWeight = true,
  }) {
    return showModalBottomSheet<SetValues>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SetEditorSheet(
        set: set,
        setNumber: setNumber,
        exerciseName: exerciseName,
        exerciseId: exerciseId,
        personalBest: personalBest,
        previous: previous,
        showWeight: showWeight,
      ),
    );
  }

  @override
  ConsumerState<SetEditorSheet> createState() => _SetEditorSheetState();
}

/// I tre valori di una serie, come li restituisce il foglio.
class SetValues {
  const SetValues({required this.weight, required this.reps, this.rpe});

  final double weight;
  final int reps;
  final double? rpe;
}

class _SetEditorSheetState extends ConsumerState<SetEditorSheet> {
  static const weightStep = 2.5;
  static const weightMax = 300.0;
  static const repsMax = 50.0;
  static const rpeMin = 1.0;
  static const rpeMax = 10.0;

  late double _weight;
  late double _reps;
  late double _rpe;

  @override
  void initState() {
    super.initState();
    // In ordine: la serie precedente, poi cio che questa serie ha gia, poi un
    // valore di partenza sensato. Il criterio chiede "i valori della serie
    // precedente", e quando non c'e non si inventa nulla di diverso da cio che
    // l'utente vede gia in tabella.
    final previous = widget.previous;
    _weight = _firstPositive([
      previous?.weight,
      widget.set.weight,
    ]) ?? 20.0;
    _reps = _firstPositive([
      previous?.reps.toDouble(),
      widget.set.reps.toDouble(),
    ]) ?? 8.0;
    _rpe = _firstPositive([previous?.rpe, widget.set.rpe]) ?? 7.0;
  }

  static double? _firstPositive(List<double?> candidates) {
    for (final value in candidates) {
      if (value != null && value > 0) return value;
    }
    return null;
  }

  String _weightText(double v) {
    // 62,5 e non 62.5: la virgola e il separatore decimale italiano, e il
    // numero si legge fra due serie, non si copia in un foglio di calcolo.
    final text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }

  /// La via d'uscita per i casi fuori scala: il bilanciere da 137,5 kg quando
  /// il cursore arriva a 300 a passi di 2,5 richiederebbe troppi trascinamenti.
  Future<void> _typeValue({
    required String title,
    required double current,
    required bool decimals,
    required ValueChanged<double> onDone,
  }) async {
    final loc = ref.read(localizationNotifierProvider);
    final controller = TextEditingController(
      text: decimals ? _weightText(current) : current.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: decimals),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onSubmitted: (raw) => Navigator.pop(ctx, _parse(raw)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _parse(controller.text)),
            child: Text(loc.t('done')),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result != null) onDone(result);
  }

  static double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final loc = ref.watch(localizationNotifierProvider);
    final previous = widget.previous;
    final personalBest = widget.personalBest;

    final isRecord = widget.showWeight &&
        personalBest != null &&
        personalBest.weight > 0 &&
        _weight > personalBest.weight;
    final diff = isRecord ? _weight - personalBest.weight : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.spacing.xl,
        0,
        t.spacing.xl,
        t.spacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.exerciseName,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${loc.t('set_label')} ${widget.setNumber}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
              ],
            ),

            // Il riferimento: cosa si era fatto la volta prima. Senza, si
            // impostano tre numeri senza sapere rispetto a cosa.
            if (previous != null || isRecord) ...[
              SizedBox(height: t.spacing.md),
              _PreviousSet(
                text: previous != null
                    ? (widget.showWeight
                        ? '${_weightText(previous.weight)} kg × ${previous.reps}'
                        : '${previous.reps} ${loc.t('reps_label')}')
                    : '',
                label: previous != null
                    ? loc.t('previous_set')
                    : loc.t('record_pill'),
                comparisonText: isRecord
                    ? '+${_weightText(diff)} kg ${loc.t('record_over_max')}'
                    : null,
              ),
            ],

            SizedBox(height: t.spacing.lg),

            if (widget.showWeight) ...[
              SetValueSlider(
                label: loc.t('load_label'),
                value: _weight,
                min: 0,
                max: weightMax,
                step: weightStep,
                semanticUnit: 'kg',
                formatValue: (v) => '${_weightText(v)} kg',
                onChanged: (v) => setState(() => _weight = v),
                onTapValue: () => _typeValue(
                  title: loc.t('load_label'),
                  current: _weight,
                  decimals: true,
                  onDone: (v) => setState(() => _weight = v),
                ),
              ),
              SizedBox(height: t.spacing.md),
            ],

            SetValueSlider(
              label: loc.t('reps_label'),
              value: _reps,
              min: 1,
              max: repsMax,
              step: 1,
              semanticUnit: loc.t('reps_label').toLowerCase(),
              onChanged: (v) => setState(() => _reps = v),
              onTapValue: () => _typeValue(
                title: loc.t('reps_label'),
                current: _reps,
                decimals: false,
                onDone: (v) => setState(() => _reps = v),
              ),
            ),
            SizedBox(height: t.spacing.md),

            // Salmone: la palette lo riserva ai dati vitali, e lo sforzo
            // percepito e esattamente quello. Carico e ripetizioni si
            // impostano, l'RPE si dichiara.
            SetValueSlider(
              label: loc.t('rpe_full_label'),
              value: _rpe,
              min: rpeMin,
              max: rpeMax,
              step: 1,
              color: scheme.tertiary,
              formatValue: (v) => 'RPE ${v.toStringAsFixed(0)}',
              semanticUnit: 'RPE',
              onChanged: (v) => setState(() => _rpe = v),
            ),

            SizedBox(height: t.spacing.xl),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                SetValues(
                  weight: widget.showWeight ? _weight : 0,
                  reps: _reps.round(),
                  rpe: _rpe,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(t.sizing.minTouchTarget),
                shape: t.shape.pill,
              ),
              child: Text(loc.t('close_set')),
            ),
          ],
        ),
      ),
    );
  }
}

/// La serie precedente, come riferimento sopra i cursori.
class _PreviousSet extends StatelessWidget {
  const _PreviousSet({
    required this.label,
    required this.text,
    this.comparisonText,
  });

  final String label;
  final String text;
  final String? comparisonText;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: t.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (text.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  text,
                  style:
                      t.typography.metricSmall?.copyWith(
                        color: scheme.onSurface,
                      ) ??
                      const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          if (comparisonText != null) ...[
            if (text.isNotEmpty) SizedBox(height: t.spacing.xs),
            Text(
              comparisonText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

