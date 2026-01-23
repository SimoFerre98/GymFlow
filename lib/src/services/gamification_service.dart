import '../models/badge_model.dart';
import '../models/session.dart';
import '../core/utils/statistics_helper.dart';

class GamificationService {
  /// Returns a list of badges that the user has unlocked based on their sessions.
  static List<BadgeModel> getUnlockedBadges(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return [];

    final unlocked = <BadgeModel>[];
    final totalWorkouts = sessions.length;
    final currentStreak = StatisticsHelper.calculateCurrentStreak(sessions);

    for (var badge in allBadges) {
      bool isUnlocked = false;

      switch (badge.type) {
        case BadgeType.workoutCount:
          if (totalWorkouts >= badge.threshold) isUnlocked = true;
          break;
        case BadgeType.streak:
          if (currentStreak >= badge.threshold) isUnlocked = true;
          break;
      }

      if (isUnlocked) {
        unlocked.add(badge);
      }
    }
    return unlocked;
  }
}
