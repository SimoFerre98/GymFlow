import 'package:flutter/material.dart';
import '../../core/theme/expressive_tokens.dart';
import 'expressive_card.dart';
import 'progress_ring.dart';

class HomeHeroCard extends StatelessWidget {
  final bool hasActiveProgram;
  final String? programName;
  final int? currentDay;
  final int? totalDays;
  final String? workoutName;
  final int? durationMinutes;
  final int? exerciseCount;
  final double? progressFraction;
  final VoidCallback onAction;
  
  final String locInProgress;
  final String formattedDay;
  final String locResume;
  final String locNoActive;
  final String locCreatePrompt;
  final String locCreateAction;
  final String locMin;
  final String locExercises;

  const HomeHeroCard({
    super.key,
    required this.hasActiveProgram,
    this.programName,
    this.currentDay,
    this.totalDays,
    this.workoutName,
    this.durationMinutes,
    this.exerciseCount,
    this.progressFraction,
    required this.onAction,
    required this.locInProgress,
    required this.formattedDay,
    required this.locResume,
    required this.locNoActive,
    required this.locCreatePrompt,
    required this.locCreateAction,
    required this.locMin,
    required this.locExercises,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    if (!hasActiveProgram) {
      return ExpressiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locNoActive,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: t.spacing.xs),
            Text(
              locCreatePrompt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: t.spacing.md),
            _buildActionBtn(context, locCreateAction, scheme, t),
          ],
        ),
      );
    }

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.13),
                  borderRadius: t.shape.cornerFull,
                ),
                child: Text(
                  locInProgress.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: scheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ),
              SizedBox(width: t.spacing.sm),
              Text(
                formattedDay.toUpperCase(),
                style: TextStyle(
                  fontSize: 8.5,
                  color: scheme.onSurface.withValues(alpha: 0.58),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: t.spacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutName ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${durationMinutes ?? 0} $locMin',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Text(
                            '·',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        Text(
                          '${exerciseCount ?? 0} $locExercises',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ProgressRing(fraction: progressFraction ?? 0.0),
            ],
          ),
          SizedBox(height: t.spacing.sm),
          _buildActionBtn(context, locResume, scheme, t),
        ],
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, String text, ColorScheme scheme, ExpressiveTokens t) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color bgColor = isDark ? scheme.primary : scheme.primaryContainer;
    final Color textColor = isDark ? scheme.onPrimary : scheme.onPrimaryContainer;

    return GestureDetector(
      onTap: onAction,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: t.shape.cornerFull,
        ),
        padding: const EdgeInsets.fromLTRB(14, 9, 9, 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: -0.1,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '→',
                  style: TextStyle(
                    color: bgColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
