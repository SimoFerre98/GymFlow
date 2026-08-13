import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/exercise_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../models/exercise.dart';
import '../../models/image_credit.dart';
import '../widgets/toast_utils.dart';

/// Elenca autore e licenza di ogni foto della libreria curata.
///
/// Le foto vengono da wger.de con licenza Creative Commons
/// Attribution-ShareAlike: la licenza impone di nominare autore e licenza, e
/// una miniatura da 56 dp non ha lo spazio per farlo. Questa schermata e dove
/// quell'attribuzione vive davvero.
class ImageCreditsScreen extends ConsumerWidget {
  const ImageCreditsScreen({super.key});

  Future<void> _apri(BuildContext context, WidgetRef ref, String url) async {
    final loc = ref.read(localizationNotifierProvider);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ToastUtils.showError(context, loc.t('image_credits_open_failed'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    final loc = ref.watch(localizationNotifierProvider);

    final exercises = ref.watch(curatedExercisesProvider).valueOrNull ?? const <Exercise>[];
    final credits = ref.watch(imageCreditsProvider).valueOrNull ?? const <ImageCredit>[];

    final nomiPerId = {for (final e in exercises) e.id: e.name};
    // Solo i crediti che corrispondono a un esercizio ancora presente: un
    // credito orfano non avrebbe un nome da mostrare.
    final voci =
        credits.where((c) => nomiPerId.containsKey(c.exerciseId)).toList()
          ..sort(
            (a, b) => nomiPerId[a.exerciseId]!.compareTo(
              nomiPerId[b.exerciseId]!,
            ),
          );

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('image_credits_title'))),
      body: ListView(
        padding: EdgeInsets.all(t.spacing.xl),
        children: [
          Text(
            loc.t('image_credits_intro'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: t.spacing.lg),
          for (final credito in voci)
            Padding(
              padding: EdgeInsets.only(bottom: t.spacing.sm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: t.shape.cornerMd,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: t.spacing.md,
                    vertical: t.spacing.xs,
                  ),
                  title: Text(
                    nomiPerId[credito.exerciseId]!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '© ${credito.author} · ${credito.licenseShortName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: credito.sourceUrl.isEmpty
                      ? null
                      : IconButton(
                          tooltip: loc.t('image_credits_source_cta'),
                          icon: Icon(
                            Icons.open_in_new,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              _apri(context, ref, credito.sourceUrl),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
