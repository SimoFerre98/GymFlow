import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/exercise_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../models/exercise.dart';
import 'exercise_image.dart';

/// La miniatura di un esercizio come compare in una lista.
///
/// Aggiunge a [ExerciseImage] le tre cose che una lista chiede e la catena di
/// ripiego non deve conoscere: la misura e la forma dai token del design
/// system, e l'indicatore per gli esercizi che hanno davvero un video.
///
/// Chi ha in mano solo l'identificativo dell'esercizio — una scheda, una
/// sessione — usa [ExerciseThumbnailById].
class ExerciseThumbnail extends ConsumerWidget {
  const ExerciseThumbnail({
    super.key,
    required this.exercise,
    this.side,
    this.onTap,
  });

  final Exercise exercise;

  /// Lato della miniatura. Di norma `thumbnailMd` dei token.
  final double? side;

  /// Cosa fare al tocco. Nullo significa **nessun tocco**: la miniatura resta
  /// decorativa e la cella che la contiene mantiene il proprio gesto.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final dimension = side ?? t.sizing.thumbnailMd;

    return SizedBox.square(
      dimension: dimension,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: t.shape.cornerMd,
              child: ExerciseImage(
                exercise: exercise,
                // Decodificare alla misura reale invece che a 480 px e cio che
                // tiene scorrevole una lista lunga.
                decodeWidth: dimension,
              ),
            ),
          ),

          // Sopra l'immagine e sotto l'indicatore: il tocco copre tutta la
          // miniatura, mentre il resto della cella conserva il proprio gesto.
          if (onTap != null)
            Positioned.fill(
              child: Material(
                // `transparency` invece di un colore trasparente: qui non c'e
                // una scelta di colore da fare, serve solo la superficie che
                // disegna l'onda del tocco.
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap, borderRadius: t.shape.cornerMd),
              ),
            ),

          // Solo per un video vero, non per una ricerca: un indicatore su un
          // esercizio che porta a una lista di risultati promette l'esecuzione
          // e consegna altro. E la ragione per cui US-041 ha tenuto separati i
          // due campi.
          if (exercise.hasSpecificVideo)
            Positioned(
              right: t.spacing.xs,
              bottom: t.spacing.xs,
              child: Semantics(
                label: ref.watch(localizationNotifierProvider).t(
                  'video_available',
                ),
                child: Container(
                  width: t.sizing.badge,
                  height: t.sizing.badge,
                  decoration: BoxDecoration(
                    // Salmone come nel mockup: la palette lo riserva ai dati
                    // vitali, e un indicatore non e un'azione.
                    color: scheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: t.sizing.badge * 0.72,
                    color: scheme.onTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// La miniatura di un esercizio di cui si conosce solo l'identificativo.
///
/// Schede e sessioni salvano `exerciseId` ed `exerciseName` e nient'altro:
/// l'esercizio completo si risolve dall'indice.
///
/// Quando l'indice non lo conosce — l'esercizio e stato cancellato, oppure la
/// risposta non e ancora arrivata — si disegna il segnaposto derivato dal
/// **nome**, che una scheda ha sempre. Il ripiego per hash di US-042 lo rende
/// stabile, quindi la stessa scheda mostra sempre lo stesso segnaposto e non
/// cambia aspetto quando Firestore risponde.
class ExerciseThumbnailById extends ConsumerWidget {
  const ExerciseThumbnailById({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.side,
    this.onTap,
  });

  final String exerciseId;
  final String exerciseName;
  final double? side;

  /// Riceve l'esercizio risolto: chi tocca una miniatura in una scheda vuole
  /// agire su quell'esercizio, non sul suo identificativo.
  final void Function(Exercise exercise)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `select` sulla singola voce: guardando la mappa intera, l'arrivo di un
    // esercizio qualsiasi ricostruirebbe tutte le celle visibili.
    final found = ref.watch(
      exerciseIndexProvider.select((index) => index[exerciseId]),
    );
    final resolved = found ?? _unknown();
    final handler = onTap;

    return ExerciseThumbnail(
      exercise: resolved,
      side: side,
      // Finche l'indice non ha risolto l'esercizio non si sa se abbia un video:
      // meglio nessun gesto che un gesto che apre "non disponibile".
      onTap: (handler == null || found == null)
          ? null
          : () => handler(resolved),
    );
  }

  /// Un esercizio con il solo nome: basta al segnaposto, che dal nome ricava
  /// una regione stabile.
  Exercise _unknown() => Exercise(
    id: exerciseId,
    name: exerciseName,
    description: '',
    type: ExerciseType.strength,
    musclesTargeted: const [],
  );
}
