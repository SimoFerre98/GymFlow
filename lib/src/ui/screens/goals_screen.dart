import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/goals_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/theme/immersivo_tokens.dart';
import '../../models/user_goal.dart';
import '../widgets/back_pill.dart';
import '../widgets/expressive_card.dart';
import '../widgets/progress_ring.dart';
/// Misure del telaio Immersivo (BackPill+titolo+filetto), non di un mockup
/// dedicato: "Obiettivi" nel mockup e `gamification_screen.dart` (badge e
/// sfide), un concetto diverso da questi obiettivi liberi definiti
/// dall'utente. Il vocabolario dei token si applica cosi com'e, non e
/// disegno nuovo.
const double _kTitleFontSize = 28;
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final goals = ref.watch(userGoalsNotifierProvider);
    final achievedCount = goals.where((g) => g.isAchieved).length;
    final totalCount = goals.length;
    final overallFraction = totalCount > 0 ? achievedCount / totalCount : 0.0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('home')),
                  SizedBox(width: t.spacing.md),
                  Text(
                    loc.t('goals_title_short').toUpperCase(),
                    style: t.typography.headline?.copyWith(
                      fontSize: _kTitleFontSize,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(t.spacing.md),
                children: [
                  ExpressiveCard(
                    child: Row(
                      children: [
                        ProgressRing(
                          fraction: overallFraction,
                        ),
                        SizedBox(width: t.spacing.lg),
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
                              SizedBox(height: t.spacing.xs),
                              Text(
                                '$achievedCount / $totalCount ${loc.t('goals_achieved')}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: t.spacing.lg),
                  if (goals.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: t.spacing.xl),
                        child: Text(
                          loc.t('goals_subtitle'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  else
                    ...goals.map((goal) => _buildGoalCard(context, ref, loc, goal)),
                  SizedBox(height: t.spacing.lg),
                  _buildAddCta(context, ref, loc, t, scheme),
                  SizedBox(height: t.spacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddCta(
    BuildContext context,
    WidgetRef ref,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
  ) {
    return InkWell(
      onTap: () => _showAddGoalSheet(context, ref, loc),
      child: Container(
        width: double.infinity,
        height: t.sizing.minTouchTarget,
        color: scheme.primary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.t('goals_add_cta').toUpperCase(),
              style: t.typography.title?.copyWith(color: scheme.onPrimary),
            ),
            SizedBox(width: t.spacing.sm),
            Icon(Icons.add, color: scheme.onPrimary),
          ],
        ),
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
      padding: EdgeInsets.only(bottom: context.immersivo.spacing.md),
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
                    horizontal: context.immersivo.spacing.sm,
                    vertical: context.immersivo.spacing.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAchieved
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: context.immersivo.shape.cornerSm,
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
            SizedBox(height: context.immersivo.spacing.sm),
            ClipRRect(
              borderRadius: context.immersivo.shape.cornerSm,
              child: LinearProgressIndicator(
                value: goal.progressFraction,
                minHeight: context.immersivo.spacing.sm,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAchieved ? theme.colorScheme.primary : theme.colorScheme.secondary,
                ),
              ),
            ),
            SizedBox(height: context.immersivo.spacing.xs),
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
          top: Radius.circular(context.immersivo.shape.radiusLg),
        ),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: context.immersivo.spacing.lg,
            right: context.immersivo.spacing.lg,
            top: context.immersivo.spacing.lg,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + context.immersivo.spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.t('goals_new_title').toUpperCase(),
                style: context.immersivo.typography.title?.copyWith(
                  color: Theme.of(bottomSheetContext).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: context.immersivo.spacing.md),
              _GoalField(controller: titleController, label: loc.t('goals_name_label')),
              SizedBox(height: context.immersivo.spacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _GoalField(
                      controller: targetController,
                      label: loc.t('goals_target_label'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(width: context.immersivo.spacing.md),
                  Expanded(
                    child: _GoalField(controller: unitController, label: loc.t('goals_unit_label')),
                  ),
                ],
              ),
              SizedBox(height: context.immersivo.spacing.lg),
              InkWell(
                onTap: () {
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
                child: Container(
                  width: double.infinity,
                  height: context.immersivo.sizing.minTouchTarget,
                  color: Theme.of(bottomSheetContext).colorScheme.primary,
                  alignment: Alignment.center,
                  child: Text(
                    loc.t('goals_add_cta').toUpperCase(),
                    style: context.immersivo.typography.title?.copyWith(
                      color: Theme.of(bottomSheetContext).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/// Un campo del modulo "Nuovo obiettivo": bordo sottile e accento a sinistra,
/// lo stesso linguaggio dei campi editabili altrove (es. Palestra, Misure).
class _GoalField extends StatelessWidget {
  const _GoalField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(left: BorderSide(color: scheme.outline, width: 3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(t.spacing.md),
          labelText: label,
        ),
      ),
    );
  }
}
