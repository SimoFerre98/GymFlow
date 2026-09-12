import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/ui/screens/program_creator_screen.dart';
import 'package:intl/intl.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/ui/widgets/expressive_card.dart';
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
              child: StreamBuilder<List<WorkoutProgram>>(
                stream: ref.watch(firestoreServiceProvider).getUserPrograms(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(context.immersivo.spacing.md),
                        child: Text(
                          '${loc.t('error_loading_programs')}: ${snapshot.error}', // Technical error message usually kept in English or generic error key
                          textAlign: TextAlign.center,
                          // `error` e il ruolo che significa «qualcosa non ha
                          // funzionato», e nel tema scuro non e il rosso acceso che
                          // era scritto qui.
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(context, loc);
                  }
                  final programs = snapshot.data!;
                  final attivi = programs.where((p) => p.isActive).length;
                  return Column(
                    children: [
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
        await ref.read(firestoreServiceProvider).deleteProgram(program.id);
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.md),
      // La card condivisa porta con se fondo, raggio, ombra e padding: quello
      // che qui era una `Card` con elevazione 4 e raggio 16 scritti a mano.
      child: ExpressiveCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramCreatorScreen(program: program),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      program.name,
                      style: t.typography.title?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // La pillola resta un `Container`: non sta facendo una
                      // card, e la card condivisa non deve crescere per
                      // coprirla.
                      //
                      // «Attiva» e la scheda su cui ti stai allenando adesso,
                      // quindi porta l'ambra, che nella palette significa
                      // esattamente «cosa fare adesso». Il verde acceso che
                      // c'era qui non e in palette.
                      if (program.isActive)
                        Container(
                          margin: EdgeInsets.only(right: t.spacing.sm),
                          padding: EdgeInsets.symmetric(
                            horizontal: t.spacing.sm,
                            vertical: t.spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.20),
                            borderRadius: t.shape.cornerXs,
                            border: Border.all(color: scheme.primary),
                          ),
                          child: Text(
                            loc.t('active_caps'),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDelete(context, ref, program, loc);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: scheme.error,
                                ),
                                SizedBox(width: t.spacing.sm),
                                Text(
                                  loc.t('delete'),
                                  style: TextStyle(color: scheme.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (program.description != null &&
                  program.description!.isNotEmpty) ...[
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
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: t.spacing.md,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: t.spacing.xs),
                  Text(
                    program.startDate != null
                        ? '${DateFormat.yMMMd(loc.locale.languageCode).format(program.startDate!)} - ${program.endDate != null ? DateFormat.yMMMd(loc.locale.languageCode).format(program.endDate!) : loc.t('ongoing')}'
                        : loc.t('no_dates'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.layers,
                    size: t.spacing.md,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: t.spacing.xs),
                  Text(
                    '${program.workoutIds.length} ${loc.t('days_label')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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
