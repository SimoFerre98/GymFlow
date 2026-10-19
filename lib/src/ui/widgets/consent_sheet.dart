import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/models/consent.dart';
import 'package:gymflow/src/ui/widgets/immersivo_switch.dart';

/// Il titolo, in parole, di una categoria di consenso.
String consentCategoryTitleKey(ConsentCategory category) => switch (category) {
  ConsentCategory.sessions => 'consent_sessions_title',
  ConsentCategory.measurements => 'consent_measurements_title',
  ConsentCategory.programs => 'consent_programs_title',
};

/// Cosa il trainer vedrebbe, in parole: è ciò che il cliente legge prima di
/// concedere, e deve dire tutto ciò che una categoria apre (US-092).
String consentCategoryDescriptionKey(ConsentCategory category) => switch (category) {
  ConsentCategory.sessions => 'consent_sessions_desc',
  ConsentCategory.measurements => 'consent_measurements_desc',
  ConsentCategory.programs => 'consent_programs_desc',
};

/// Il riassunto, in una riga: «Vede: … · Può scrivere le tue schede». Le frasi
/// vengono da [consentSummaryKeys], che le compone.
String consentSummaryText(Localization loc, ConsentGrants grants) =>
    consentSummaryKeys(grants).map(loc.t).join(' · ');

/// Una categoria di consenso: cosa è, cosa apre, e l'interruttore.
///
/// Un solo widget per il foglio di accettazione e per il dettaglio della
/// connessione, così il cliente legge le stesse parole prima e dopo.
/// [onChanged] nullo lo disabilita.
class ConsentCategoryTile extends ConsumerWidget {
  const ConsentCategoryTile({
    super.key,
    required this.category,
    required this.value,
    required this.onChanged,
  });

  final ConsentCategory category;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    // Un solo nodo per la tastiera e per i lettori di schermo: titolo,
    // descrizione e interruttore sono la stessa scelta.
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t(consentCategoryTitleKey(category)),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: t.spacing.xs),
                  Text(
                    loc.t(consentCategoryDescriptionKey(category)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: t.spacing.md),
            ImmersivoSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Il foglio che il cliente vede **prima** di accettare un invito da un
/// trainer (US-092): cosa verrebbe condiviso, categoria per categoria, e cosa
/// resta privato. Restituisce ciò che ha scelto, o `null` se rinuncia.
///
/// Gli interruttori **partono spenti**: non si concede per inerzia. Accettare
/// con tutto spento è valido — un legame senza dati — e il cliente potrà
/// accendere dopo, dal dettaglio della connessione.
Future<ConsentGrants?> showConsentSheet(BuildContext context, String trainerName) {
  return showModalBottomSheet<ConsentGrants>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ConsentSheet(trainerName: trainerName),
  );
}

class ConsentSheet extends ConsumerStatefulWidget {
  const ConsentSheet({super.key, required this.trainerName});

  final String trainerName;

  @override
  ConsumerState<ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends ConsumerState<ConsentSheet> {
  ConsentGrants _grants = ConsentGrants.none;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(t.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.t('consent_sheet_title').replaceFirst('%s', widget.trainerName).toUpperCase(),
              style: t.typography.headline?.copyWith(color: scheme.onSurface),
            ),
            SizedBox(height: t.spacing.sm),
            Text(
              loc.t('consent_sheet_intro'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: t.spacing.md),
            for (final category in ConsentCategory.values)
              ConsentCategoryTile(
                category: category,
                value: _grants.isGranted(category),
                onChanged: (value) =>
                    setState(() => _grants = _grants.withGrant(category, value)),
              ),
            SizedBox(height: t.spacing.sm),
            Text(
              loc.t('consent_always_private'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: t.spacing.xl),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.t('cancel')),
                  ),
                ),
                SizedBox(width: t.spacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _grants),
                    child: Text(loc.t('accept_invite')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
