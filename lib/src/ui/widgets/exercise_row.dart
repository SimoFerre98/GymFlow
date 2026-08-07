import 'package:flutter/material.dart';

import '../../core/theme/expressive_tokens.dart';
import '../../models/exercise.dart';
import 'exercise_thumbnail.dart';

/// Riga standard per visualizzare un esercizio nelle liste.
///
/// Comprende la miniatura da 56 dp a sinistra, il titolo in grassetto
/// ([TextTheme.titleSmall]), un sottotitolo personalizzabile (di default il
/// tipo di esercizio in maiuscolo) e un'eventuale azione/widget di coda.
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.exercise,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onThumbnailTap,
    this.transparentBackground = false,
  });

  final Exercise exercise;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onThumbnailTap;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: transparentBackground
          ? Colors.transparent
          : scheme.surfaceContainerHigh,
      // 16 px del mockup **convertiti**: 16 x 1,36 = 22 dp, e `cornerLg` (24) e
      // il token piu vicino. Copiare il 16 dell'HTML darebbe angoli molto piu
      // squadrati di quelli disegnati: e l'errore che DESIGN-SPEC esiste per
      // impedire.
      borderRadius: t.shape.cornerLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(t.spacing.sm),
          child: Row(
            children: [
              ExerciseThumbnail(
                exercise: exercise,
                side: t.sizing.thumbnailMd,
                onTap: onThumbnailTap,
              ),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: t.spacing.xs),
                    subtitle ??
                        Text(
                          exercise.type.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: t.spacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
