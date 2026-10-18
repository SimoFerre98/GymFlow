import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/providers/program_provider.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/ui/screens/program_creator_screen.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/ui/widgets/program_card.dart';
import 'package:gymflow/src/ui/widgets/ticker_marquee.dart';
/// Barra "Nuovo programma" in fondo: stesso trattamento del "+ Nuovo
/// esercizio" di `exercise_library_screen.dart` — testo pieno e riquadro
/// icona, non un FAB fluttuante estraneo al linguaggio Immersivo.
///
/// Serve perche' Schede e' tornata voce di navigazione al posto di Crea
/// (segnalato dall'utente: due modi di "creare" non avevano senso): senza
/// questo pulsante, l'unico posto da cui nasceva un programma nuovo era lo
/// stato vuoto della Home, buono solo per il primissimo programma.
const double _kCtaFontSize = 20;
const double _kCtaIconBoxSide = 42;
class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    if (userId == null) {
      return Scaffold(body: Center(child: Text(loc.t('login_required'))));
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.lg, t.spacing.sm, t.spacing.lg, 0),
              child: _buildHeader(context, loc, t, scheme),
            ),
            Expanded(
              child: ref.watch(localProgramsProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.immersivo.spacing.md),
                    child: Text(
                      '${loc.t('error_loading_programs')}: $error', // Technical error message usually kept in English or generic error key
                      textAlign: TextAlign.center,
                      // `error` e il ruolo che significa «qualcosa non ha
                      // funzionato», e nel tema scuro non e il rosso acceso che
                      // era scritto qui.
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
                data: (programs) {
                  if (programs.isEmpty) {
                    return _buildEmptyState(context, loc);
                  }
                  final attivi = programs.where((p) => p.isActive).length;
                  return Column(
                    children: [
                      // Segnalato dall'utente: senza questo spazio il banner
                      // scorrevole finiva a filo col titolo "Schede" sopra.
                      SizedBox(height: context.immersivo.spacing.sm),
                      // La striscia del mockup ("TOTALE N PROGRAMMI / ..."), con
                      // i dati che questa schermata gia interroga.
                      TickerMarquee(
                        text:
                            '${loc.t('total_programs_ticker').replaceFirst('%s', '${programs.length}')}'
                            '   /   '
                            '${loc.t('active_programs_ticker').replaceFirst('%s', '$attivi')}',
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(context.immersivo.spacing.md),
                          itemCount: programs.length,
                          itemBuilder: (context, index) {
                            final program = programs[index];
                            return _buildProgramCard(context, ref, program, loc);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildNewProgramCta(context, loc, t, scheme),
          ],
        ),
      ),
    );
  }
  Widget _buildNewProgramCta(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, t.spacing.md),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgramCreatorScreen()),
        ),
        child: Container(
          padding: EdgeInsets.all(t.spacing.xs),
          color: scheme.primary,
          child: Row(
            children: [
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Text(
                  loc.t('new_program').toUpperCase(),
                  style: t.typography.title?.copyWith(
                    fontSize: _kCtaFontSize,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
              Container(
                width: _kCtaIconBoxSide,
                height: _kCtaIconBoxSide,
                alignment: Alignment.center,
                color: scheme.onPrimary,
                child: Icon(Icons.add, color: scheme.primary),
              ),
            ],
          ),
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
        Text(
          loc.t('programs_tab').toUpperCase(),
          style: t.typography.title?.copyWith(color: scheme.onSurface),
        ),
        SizedBox(width: t.spacing.md),
        Expanded(
          child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
  Widget _buildEmptyState(BuildContext context, Localization loc) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            // L'icona del vuoto e grande come una miniatura di rilievo: e la
            // misura piu vicina fra i token, e resta una misura decisa dal
            // design system invece che dal caso.
            size: t.sizing.thumbnailLg,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(height: t.spacing.md),
          Text(
            loc.t('no_programs_yet'),
            style: t.typography.title?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: t.spacing.sm),
          Text(
            loc.t('create_program_msg'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram program,
    Localization loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('delete_program_title')),
        content: Text(
          '${loc.t('delete_program_body_prefix')} "${program.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel'))
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(loc.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      try {
        await ref.read(firestoreServiceProvider).deleteProgram(program.id, program.userId);
        if (context.mounted) {
          ToastUtils.showInfo(context, loc.t('program_deleted'));
        }
      } catch (e) {
        if (context.mounted) {
          ToastUtils.showError(context, '${loc.t('error_deleting')}: $e');
        }
      }
    }
  }
  Widget _buildProgramCard(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram program,
    Localization loc,
  ) {
    final t = context.immersivo;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.md),
      child: ProgramCard(
        program: program,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProgramCreatorScreen(program: program),
          ),
        ),
        onDelete: () => _confirmDelete(context, ref, program, loc),
      ),
    );
  }
}
