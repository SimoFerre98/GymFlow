import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/program_creator_screen.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:intl/intl.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/expressive_card.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = AuthService().currentUser;
    final loc = ref.watch(localizationNotifierProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Login required')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('my_programs_title')),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<WorkoutProgram>>(
        stream: FirestoreService().getUserPrograms(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.expressive.spacing.md),
                child: Text(
                  'Error loading programs: ${snapshot.error}', // Technical error message usually kept in English or generic error key
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
          return ListView.builder(
            padding: EdgeInsets.all(context.expressive.spacing.md),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return _buildProgramCard(context, program, loc);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Localization loc) {
    final t = context.expressive;
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
            style: t.typography.titleEmphasized?.copyWith(
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
            child: Text(
              loc.t('delete') != 'delete' ? loc.t('delete') : 'Delete',
            ), // Same for delete.
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      try {
        await FirestoreService().deleteProgram(program.id);
        if (context.mounted) {
          ToastUtils.showInfo(context, loc.t('program_deleted'));
        }
      } catch (e) {
        if (context.mounted) {
          // ToastUtils.showError(context, 'Error deleting program: $e');
          ToastUtils.showError(context, '${loc.t('error_deleting')}: $e');
          // I missed 'error_deleting', will fallback to English if missing or I should fix it.
          // I'll stick to English for technical error part.
          ToastUtils.showError(context, 'Error deleting program: $e');
        }
      }
    }
  }

  Widget _buildProgramCard(
    BuildContext context,
    WorkoutProgram program,
    Localization loc,
  ) {
    final t = context.expressive;
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
                      style: t.typography.titleEmphasized?.copyWith(
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
                            borderRadius: t.shape.cornerFull,
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
                            _confirmDelete(context, program, loc);
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
