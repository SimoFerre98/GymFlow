import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/goals_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/expressive_tokens.dart';
import '../../models/user_goal.dart';
import '../widgets/expressive_card.dart';
import '../widgets/progress_ring.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final goals = ref.watch(userGoalsNotifierProvider);
    final achievedCount = goals.where((g) => g.isAchieved).length;
    final totalCount = goals.length;
    final overallFraction = totalCount > 0 ? achievedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.t('goals_title'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context, ref, loc),
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.t('goals_add_cta')),
      ),
      body: ListView(
        padding: EdgeInsets.all(context.expressive.spacing.lg),
        children: [
          ExpressiveCard(
            child: Row(
              children: [
                ProgressRing(
                  fraction: overallFraction,
                ),
                SizedBox(width: context.expressive.spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('goals_card_title'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: context.expressive.spacing.xs),
                      Text(
                        '$achievedCount / $totalCount ${loc.t('goals_achieved')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.expressive.spacing.lg),
          if (goals.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.expressive.spacing.xl),
                child: Text(
                  loc.t('goals_subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ...goals.map((goal) => _buildGoalCard(context, ref, loc, goal)),
          SizedBox(height: context.expressive.spacing.xxl),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    WidgetRef ref,
    Localization loc,
    UserGoal goal,
  ) {
    final theme = Theme.of(context);
    final isAchieved = goal.isAchieved;

    return Padding(
      padding: EdgeInsets.only(bottom: context.expressive.spacing.md),
      child: ExpressiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.expressive.spacing.sm,
                    vertical: context.expressive.spacing.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAchieved
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: context.expressive.shape.cornerSm,
                  ),
                  child: Text(
                    isAchieved ? loc.t('goals_achieved') : loc.t('goals_in_progress'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isAchieved
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () {
                    ref.read(userGoalsNotifierProvider.notifier).removeGoal(goal.id);
                  },
                ),
              ],
            ),
            SizedBox(height: context.expressive.spacing.sm),
            ClipRRect(
              borderRadius: context.expressive.shape.cornerSm,
              child: LinearProgressIndicator(
                value: goal.progressFraction,
                minHeight: context.expressive.spacing.sm,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAchieved ? theme.colorScheme.primary : theme.colorScheme.secondary,
                ),
              ),
            ),
            SizedBox(height: context.expressive.spacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(goal.progressFraction * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref, Localization loc) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.expressive.shape.radiusLg),
        ),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: context.expressive.spacing.lg,
            right: context.expressive.spacing.lg,
            top: context.expressive.spacing.lg,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + context.expressive.spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.t('goals_new_title'),
                style: Theme.of(bottomSheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: context.expressive.spacing.md),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: loc.t('goals_name_label'),
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: context.expressive.spacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.t('goals_target_label'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: context.expressive.spacing.md),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: InputDecoration(
                        labelText: loc.t('goals_unit_label'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.expressive.spacing.lg),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final target = double.tryParse(targetController.text.trim()) ?? 0.0;
                  final unit = unitController.text.trim();
                  if (title.isNotEmpty && target > 0) {
                    final newGoal = UserGoal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: 'local',
                      title: title,
                      type: GoalType.targetLoad,
                      targetValue: target,
                      currentValue: 0.0,
                      unit: unit,
                      createdAt: DateTime.now(),
                    );
                    ref.read(userGoalsNotifierProvider.notifier).addGoal(newGoal);
                    Navigator.of(bottomSheetContext).pop();
                  }
                },
                child: Text(loc.t('goals_add_cta')),
              ),
            ],
          ),
        );
      },
    );
  }
}
