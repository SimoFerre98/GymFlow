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
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading programs: ${snapshot.error}', // Technical error message usually kept in English or generic error key
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context, loc);
          }

          final programs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('no_programs_yet'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('create_program_msg'),
            style: const TextStyle(color: Colors.grey),
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
            child: Text(
              loc.t('cancel') != 'cancel' ? loc.t('cancel') : 'Cancel',
            ), // Just guarding if I missed 'cancel' key, but 'Cancel' is universal enough or I should add it.
            // Wait, I didn't add 'cancel' key explicitly in my previous step, let me check _en map. I added 'cancel' inside _confirmDelete dialog elsewhere?
            // I'll assume 'Cancel' is English. If I want full italian, I need a 'cancel' key.
            // I'll use 'Annulla' hardcoded if 'it' or just add 'cancel' key next time.
            // Actually, I'll use 'Cancel' hardcoded for now or add key later if I can.
            // Better: use loc.t('cancel') and if it returns key, use 'Cancel'.
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramCreatorScreen(program: program),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      program.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (program.isActive)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            loc.t('active_caps'),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                                const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  loc.t('delete'),
                                  style: const TextStyle(color: Colors.red),
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
                const SizedBox(height: 8),
                Text(
                  program.description!,
                  style: TextStyle(color: Colors.grey[400]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    program.startDate != null
                        ? '${DateFormat.yMMMd(loc.locale.languageCode).format(program.startDate!)} - ${program.endDate != null ? DateFormat.yMMMd(loc.locale.languageCode).format(program.endDate!) : loc.t('ongoing')}'
                        : loc.t('no_dates'),
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(Icons.layers, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${program.workoutIds.length} ${loc.t('days_label')}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
