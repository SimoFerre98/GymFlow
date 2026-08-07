import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/personal_record.dart';
import 'dashboard_provider.dart';

part 'personal_best_provider.g.dart';

/// Espone la mappa exerciseId -> PersonalBest calcolata da tutte le sessioni
/// caricate in locale da Isar.
@riverpod
class PersonalBests extends _$PersonalBests {
  @override
  Map<String, PersonalBest> build() {
    final sessionsAsync = ref.watch(dashboardSessionsProvider);
    final sessions = sessionsAsync.value ?? [];
    return PersonalRecord.calculatePersonalBests(sessions);
  }
}
