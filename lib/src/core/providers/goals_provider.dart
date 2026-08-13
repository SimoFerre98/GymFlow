import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_goal.dart';
import '../../models/session.dart';

part 'goals_provider.g.dart';

@Riverpod(keepAlive: true)
class UserGoalsNotifier extends _$UserGoalsNotifier {
  static const _goalsStorageKey = 'user_goals_v1';

  @override
  List<UserGoal> build() {
    _loadFromPrefs();
    return _defaultGoals();
  }

  List<UserGoal> _defaultGoals() {
    final now = DateTime.now();
    return [
      UserGoal(
        id: 'default_freq',
        userId: 'local',
        title: '3 Allenamenti a settimana',
        type: GoalType.workoutFrequency,
        targetValue: 3.0,
        currentValue: 1.0,
        unit: 'allenamenti',
        createdAt: now,
      ),
      UserGoal(
        id: 'default_load',
        userId: 'local',
        title: 'Spinta Panca 80 kg',
        type: GoalType.targetLoad,
        targetValue: 80.0,
        currentValue: 60.0,
        unit: 'kg',
        createdAt: now,
      ),
    ];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_goalsStorageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
        final goals = decoded
            .map((item) => UserGoal.fromMap(item as Map<String, dynamic>, ''))
            .toList();
        if (goals.isNotEmpty) {
          state = goals;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((g) => g.toMap()).toList();
      await prefs.setString(_goalsStorageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  void addGoal(UserGoal goal) {
    state = [...state, goal];
    _saveToPrefs();
  }

  void removeGoal(String id) {
    state = state.where((g) => g.id != id).toList();
    _saveToPrefs();
  }

  void updateProgressFromSessions(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return;

    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final recentSessionsCount = sessions.where((s) => s.startTime.isAfter(oneWeekAgo)).length.toDouble();

    final updated = state.map((goal) {
      if (goal.isAchieved) return goal;

      if (goal.type == GoalType.workoutFrequency) {
        final achieved = recentSessionsCount >= goal.targetValue;
        return goal.copyWith(
          currentValue: recentSessionsCount,
          isAchieved: achieved,
          achievedAt: achieved ? (goal.achievedAt ?? now) : null,
        );
      } else if (goal.type == GoalType.targetLoad) {
        double maxLoad = goal.currentValue;
        for (final session in sessions) {
          for (final exercise in session.exercises) {
            if (goal.exerciseId != null && exercise.exerciseId != goal.exerciseId) continue;
            for (final set in exercise.sets) {
              if (set.isCompleted && set.weight > maxLoad) {
                maxLoad = set.weight;
              }
            }
          }
        }
        final achieved = maxLoad >= goal.targetValue;
        return goal.copyWith(
          currentValue: maxLoad,
          isAchieved: achieved,
          achievedAt: achieved ? (goal.achievedAt ?? now) : null,
        );
      }
      return goal;
    }).toList();

    state = updated;
    _saveToPrefs();
  }
}
