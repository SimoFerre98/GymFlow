import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/core/utils/program_timeline.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/ui/widgets/expressive_card.dart';
import 'package:intl/intl.dart';

/// Larghezza della striscia col colore che l'utente ha scelto per la scheda.
const double _kStripeWidth = 6;

/// Altezza della barra di avanzamento delle settimane.
const double _kProgressHeight = 4;

/// La scheda nella lista di Schede.
///
/// **Il colore scelto dall'utente si vede.** Nel creatore ogni scheda riceve
/// un colore, e il calendario lo usa; qui restava ignorato, ed era una parte
/// della piattezza della card. Ora e la striscia a sinistra: e un tag
/// personale, non un ruolo del tema, quindi viene dal modello e non dal
/// `ColorScheme`.
///
/// **L'attiva si distingue a colpo d'occhio**: bordo e bagliore nel colore
/// d'azione, che nella palette significa «cosa fare adesso» — la scheda su cui
/// ci si sta allenando.
///
/// **I numeri sono grandi**: i giorni della scheda e, se ha le date, la
/// settimana corrente su quelle totali. Vengono dalle sole date scritte
/// dall'utente ([programTimeline]); senza date non si mostra nessuna settimana
/// invece di inventarne una.
class ProgramCard extends ConsumerWidget {
  const ProgramCard({
    super.key,
    required this.program,
    required this.onTap,
    required this.onDelete,
    this.now,
  });

  final WorkoutProgram program;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Il «oggi» del calcolo delle settimane; assente, l'ora vera. Esiste perche
  /// un test non puo dipendere dal giorno in cui gira.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final timeline = programTimeline(program, now ?? DateTime.now());
    final active = program.isActive;
    // La card condivisa porta fondo, filetto e onda del tocco. Il padding e
    // azzerato perche la striscia deve arrivare al bordo: lo spazio interno lo
    // da la colonna a destra.
    return ExpressiveCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      borderColor: active ? scheme.primary : null,
      glow: active ? t.elevation.level2(scheme.primary) : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: _kStripeWidth, color: Color(program.color)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(t.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context, loc, t, scheme),
                    if (program.description != null && program.description!.isNotEmpty) ...[
                      SizedBox(height: t.spacing.sm),
                      Text(
                        program.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: t.spacing.md),
                    _stats(context, loc, t, scheme, timeline),
                    if (timeline.progress != null) ...[
                      SizedBox(height: t.spacing.sm),
                      LinearProgressIndicator(
                        value: timeline.progress,
                        minHeight: _kProgressHeight,
                        color: scheme.tertiary,
                        backgroundColor: scheme.surfaceContainerLowest,
                      ),
                    ],
                    SizedBox(height: t.spacing.sm),
                    _dates(context, loc, t, scheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Localization loc, ImmersivoTokens t, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            program.name,
            style: t.typography.title?.copyWith(color: scheme.onSurface),
          ),
        ),
        // «Attiva» e la scheda su cui ci si sta allenando: porta il colore
        // d'azione, che nella palette significa esattamente «cosa fare adesso».
        if (program.isActive)
          Container(
            margin: EdgeInsets.only(right: t.spacing.sm),
            padding: EdgeInsets.symmetric(horizontal: t.spacing.sm, vertical: t.spacing.xs),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.20),
              borderRadius: t.shape.cornerXs,
              border: Border.all(color: scheme.primary),
            ),
            child: Text(
              loc.t('active_caps'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: scheme.error),
                  SizedBox(width: t.spacing.sm),
                  Text(loc.t('delete'), style: TextStyle(color: scheme.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// La fila dei numeri: giorni della scheda, e dove si e nel tempo.
  Widget _stats(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    ProgramTimeline timeline,
  ) {
    final days = program.workoutIds.length;
    final (String value, String label)? when = switch (timeline.phase) {
      ProgramPhase.undated => null,
      ProgramPhase.upcoming => ('${timeline.daysToStart}', loc.t('program_stat_to_start')),
      ProgramPhase.running => (
        timeline.totalWeeks == null ? '${timeline.week}' : '${timeline.week}/${timeline.totalWeeks}',
        loc.t('program_stat_week'),
      ),
      ProgramPhase.ended => ('${timeline.totalWeeks}', loc.t('program_stat_ended_weeks')),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // «1 giorni» era scritto cosi nella vecchia card: con un solo giorno
        // l'etichetta e al singolare.
        _Stat(
          value: '$days',
          label: loc.t(days == 1 ? 'day_label_one' : 'days_label'),
          color: scheme.onSurface,
        ),
        if (when != null) ...[
          SizedBox(width: t.spacing.xl),
          // Dati, non azioni: stesso colore dei dati vitali, mai quello delle
          // azioni.
          _Stat(value: when.$1, label: when.$2, color: scheme.tertiary),
        ],
      ],
    );
  }

  /// L'intervallo scritto per esteso resta: e l'informazione che la card
  /// mostrava prima, e i numeri sopra non la sostituiscono.
  Widget _dates(BuildContext context, Localization loc, ImmersivoTokens t, ColorScheme scheme) {
    String format(DateTime d) => DateFormat.yMMMd(loc.locale.languageCode).format(d);
    final start = program.startDate;
    final text = start == null
        ? loc.t('no_dates')
        : '${format(start)} - ${program.endDate != null ? format(program.endDate!) : loc.t('ongoing')}';
    return Row(
      children: [
        Icon(Icons.calendar_today, size: t.spacing.md, color: scheme.onSurfaceVariant),
        SizedBox(width: t.spacing.xs),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Un numero grande con la sua etichetta sotto.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: t.typography.headline?.copyWith(color: color)),
        SizedBox(height: t.spacing.xs),
        Text(
          label.toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
