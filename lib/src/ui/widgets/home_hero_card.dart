import 'package:flutter/material.dart';
import '../../core/theme/expressive_tokens.dart';
import 'expressive_card.dart';
import 'expressive_cta_button.dart';
import 'progress_ring.dart';

/// La pillola piccola in maiuscolo: «IN CORSO», il gruppo muscolare di una riga.
///
/// Sta qui, ed e pubblica, perche era scritta due volte — in questa card e nelle
/// righe della dashboard — con gli stessi numeri copiati. Un componente scritto
/// due volte e un valore da sbagliare due volte.
///
/// `DESIGN-SPEC.md`, voce «Pillole»: raggio pieno, maiuscolo, peso 700, fondo
/// all'accento al 13%. I 2,5 e 8 px del mockup convertiti (`x 1,36`) sono 3,4 e
/// 10,9 dp: fra i token i piu vicini sono `spacing.xs` e `spacing.sm`.
class HomeMetaPill extends StatelessWidget {
  const HomeMetaPill({super.key, required this.testo});

  final String testo;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.sm,
        vertical: t.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.13),
        borderRadius: t.shape.cornerFull,
      ),
      child: Text(
        testo.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: scheme.onSurface.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

/// La card in cima alla home: la scheda in corso, o l'invito a crearne una.
///
/// ⚠️ **Nessuna dimensione di carattere scritta a mano.** I numeri del mockup
/// sono in **pixel** su un telaio da 282 px, e il telefono e 384 dp: copiarli fa
/// il testo un quarto piu piccolo di com'e disegnato. La prima versione di
/// questo file aveva cinque `fontSize: 8.5` — cioe la riga `.exr-meta {
/// font-size: 8.5px }` del CSS — e i test del design system l'hanno preso.
///
/// Qui i caratteri vengono dai **ruoli** di `textTheme`, che e meglio che
/// convertire a mano: seguono il tema e la dimensione di sistema scelta
/// dall'utente. La corrispondenza col mockup e questa:
///
/// | Mockup | px | dp | Ruolo |
/// |---|---|---|---|
/// | `.lbl`, `.exr-meta` | 8,5–9,5 | 11,6–12,9 | `labelSmall` |
/// | `.cta` | 10,5 | 14,3 | `labelLarge` |
/// | nome della scheda | 13,5 | 18,4 | `titleMedium` |
class HomeHeroCard extends StatelessWidget {
  final bool hasActiveProgram;
  final String? programName;
  final int? currentDay;
  final int? totalDays;
  final String? workoutName;
  final int? durationMinutes;
  final int? exerciseCount;
  final double? progressFraction;
  final VoidCallback onAction;

  final String locInProgress;
  final String formattedDay;
  final String locResume;
  final String locNoActive;
  final String locCreatePrompt;
  final String locCreateAction;
  final String locMin;
  final String locExercises;
  final String locExerciseOne;

  const HomeHeroCard({
    super.key,
    required this.hasActiveProgram,
    this.programName,
    this.currentDay,
    this.totalDays,
    this.workoutName,
    this.durationMinutes,
    this.exerciseCount,
    this.progressFraction,
    required this.onAction,
    required this.locInProgress,
    required this.formattedDay,
    required this.locResume,
    required this.locNoActive,
    required this.locCreatePrompt,
    required this.locCreateAction,
    required this.locMin,
    required this.locExercises,
    required this.locExerciseOne,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!hasActiveProgram) {
      return ExpressiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locNoActive,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: t.spacing.xs),
            Text(
              locCreatePrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: t.spacing.md),
            _pulsanteAzione(context, locCreateAction),
          ],
        ),
      );
    }

    final stileMeta = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.55),
    );

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HomeMetaPill(testo: locInProgress),
              // L'etichetta del giorno compare **solo se la sappiamo**. Finche
              // «a che punto sono dentro la scheda» non e calcolabile — e
              // US-063, bloccata da US-059 — tacere e meglio che mostrare il
              // «3 / 5» d'esempio del mockup a tutti.
              if (formattedDay.isNotEmpty) ...[
                SizedBox(width: t.spacing.sm),
                Text(
                  formattedDay.toUpperCase(),
                  // `.lbl` del mockup: maiuscolo, spaziato, carta al 58%.
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.58),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: t.spacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutName ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: t.spacing.xs),
                    Row(
                      children: [
                        // La durata compare solo se c'e: il modello non la
                        // conosce, e i «45 min» erano un segnaposto mostrato
                        // come se fosse un dato.
                        if (durationMinutes != null) ...[
                          Text('$durationMinutes $locMin', style: stileMeta),
                          Padding(
                            // Il gap di 7 px del mockup e 9,5 dp: `spacing.sm`.
                            padding: EdgeInsets.symmetric(
                              horizontal: t.spacing.sm,
                            ),
                            child: Text('·', style: stileMeta),
                          ),
                        ],
                        Text(
                          // Singolare e plurale: «1 esercizi» si legge come un
                          // errore, e sulla home compare a ogni scheda da un
                          // esercizio solo.
                          '${exerciseCount ?? 0} '
                          '${exerciseCount == 1 ? locExerciseOne : locExercises}',
                          style: stileMeta,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // L'anello compare solo con un avanzamento vero. Disegnarlo a
              // zero, o al 72% del mockup, direbbe una cosa falsa: e US-063 a
              // saper calcolare a che punto e il ciclo.
              if (progressFraction != null)
                ProgressRing(fraction: progressFraction!),
            ],
          ),
          SizedBox(height: t.spacing.sm),
          _pulsanteAzione(context, locResume),
        ],
      ),
    );
  }

  /// Il `.cta` del mockup, a piena larghezza: vedi `ExpressiveCtaButton`.
  ///
  /// Era duplicato qui — lo stesso ambra, lo stesso cerchio con la freccia —
  /// prima di diventare un widget condiviso: un componente scritto due volte è
  /// un valore da sbagliare due volte.
  Widget _pulsanteAzione(BuildContext context, String testo) {
    return SizedBox(
      width: double.infinity,
      child: ExpressiveCtaButton(label: testo, onTap: onAction),
    );
  }
}
