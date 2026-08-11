import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';

import '../../core/providers/localization_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/live_metrics_provider.dart'; // per healthServiceProvider
import '../../services/health_service.dart'; // per PermessiSaluteMancanti
import '../../models/session.dart';
import '../../core/utils/statistics_helper.dart';
import '../widgets/back_pill.dart';
import '../widgets/charts/activity_chart.dart';
import '../widgets/charts/body_measurements_chart.dart';
import '../widgets/expressive_card.dart';
import '../../core/theme/expressive_tokens.dart';
import 'package:health/health.dart';
import 'health_detail_screen.dart';
import 'workout_summary_screen.dart';

/// L'altezza dei due grafici a card: attivita e progresso corporeo.
///
/// Non e una misura del design system — nessun token descrive l'altezza di un
/// grafico — ma `fl_chart` ne vuole una definita per disegnare. Una costante
/// sola e non due numeri scritti a mano nei due punti d'uso: cosi i due
/// grafici restano della stessa altezza per costruzione, non per coincidenza.
const double kAltezzaGraficoStatistiche = 200;

class StatisticsScreen extends riverpod.ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  riverpod.ConsumerState<StatisticsScreen> createState() =>
      _StatisticsScreenState();
}

class _StatisticsScreenState extends riverpod.ConsumerState<StatisticsScreen> {
  Future<Map<String, dynamic>>? _healthDataFuture;
  int _currentView = 0; // 0 = Statistics, 1 = History

  @override
  void initState() {
    super.initState();
    _healthDataFuture = _initAndFetchHealth();
  }

  Future<Map<String, dynamic>> _initAndFetchHealth() async {
    if (kIsWeb) return {};
    try {
      final health = ref.read(healthServiceProvider);
      await health.configure();
      final mancanti = await health.getMissingSummaryPermissions();
      if (mancanti != null && mancanti.isNotEmpty) {
        // Con dentro l'elenco: la schermata deve poter dire **cosa** manca, non
        // solo che qualcosa e andato storto.
        throw PermessiSaluteMancanti(mancanti);
      }
      return await health.fetchDailySummary();
    } catch (e) {
      debugPrint('Health Load Error: $e');
      rethrow;
    }
  }

  /// Chiede i permessi e ricarica, se sono stati concessi.
  ///
  /// `mounted` dopo l'attesa: la richiesta apre una schermata di sistema, e
  /// l'utente puo tornare indietro chiudendo questa.
  Future<void> _chiediPermessiSalute() async {
    final concessi = await ref.read(healthServiceProvider).requestPermissions();
    if (!mounted) return;
    if (concessi) await _refreshHealthData();
  }

  Future<void> _refreshHealthData() async {
    setState(() {
      _healthDataFuture = ref.read(healthServiceProvider).fetchDailySummary();
    });
    try {
      await _healthDataFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final sessionsAsync = ref.watch(dashboardSessionsProvider);
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackPill(label: loc.t('home')),
        leadingWidth: BackPill.leadingWidth,
        title: Text(
          loc.t('statistics_title'),
          style: t.typography.titleEmphasized?.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHealthData,
        child: CustomScrollView(
          slivers: [
            // TOGGLE (Pill)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: t.spacing.md),
                  child: Container(
                    width: 300,
                    height: t.sizing.minTouchTarget,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: t.shape.cornerFull,
                      boxShadow: t.elevation.level1(scheme.shadow),
                    ),
                    child: Stack(
                      children: [
                        // Animated Background Pill
                        AnimatedAlign(
                          alignment: _currentView == 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Container(
                            width: 150, // meta della larghezza fissa sopra
                            height: t.sizing.minTouchTarget,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: t.shape.cornerFull,
                            ),
                          ),
                        ),
                        // Text Labels
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _currentView = 0),
                                behavior: HitTestBehavior.translucent,
                                child: Center(
                                  child: Text(
                                    loc.t('statistics_tab'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _currentView == 0
                                          ? scheme.onPrimary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _currentView = 1),
                                behavior: HitTestBehavior.translucent,
                                child: Center(
                                  child: Text(
                                    loc.t('history_tab'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _currentView == 1
                                          ? scheme.onPrimary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // CONTENT
            if (_currentView == 0) ...[
              // STATISTICS VIEW
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(t.spacing.lg),
                  child: sessionsAsync.when(
                    data: (sessions) {
                      final streak = StatisticsHelper.calculateCurrentStreak(
                        sessions,
                      );
                      final volume = StatisticsHelper.calculateTotalVolume(
                        sessions,
                      );
                      // Convert volume to tons/kg string
                      final volumeStr = volume > 1000
                          ? '${(volume / 1000).toStringAsFixed(1)}t'
                          : '${volume}kg';

                      return Column(
                        children: [
                          // Row 1: Workouts & Streak
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  loc.t('workouts_label'),
                                  '${sessions.length}',
                                  Icons.fitness_center,
                                  scheme.secondary,
                                ),
                              ),
                              SizedBox(width: t.spacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  loc.t('streak_label'),
                                  '$streak',
                                  Icons.local_fire_department,
                                  scheme.secondary,
                                  suffix: loc.t('days_label'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: t.spacing.md),
                          // Row 2: Volume & RPE
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  loc.t('volume_label'),
                                  volumeStr,
                                  Icons.layers,
                                  scheme.secondary,
                                ),
                              ),
                              SizedBox(width: t.spacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  loc.t('rpe_label'),
                                  StatisticsHelper.calculateAverageRPE(
                                    sessions,
                                  ).toStringAsFixed(1),
                                  Icons.star_half,
                                  // Lo sforzo percepito e un dato vitale, e il
                                  // salmone e il ruolo che la palette riserva
                                  // a quelli. Le altre tre tessere sono
                                  // conteggi: nessuna e un'azione, quindi
                                  // nessuna porta l'ambra.
                                  scheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: t.spacing.md),

                          HealthSummarySection(
                            future: _healthDataFuture,
                            loc: loc,
                            onConsenti: _chiediPermessiSalute,
                          ),
                          SizedBox(height: t.spacing.md),
                          RepaintBoundary(
                            child: ExpressiveCard(
                              title: loc.t('workout_activity_chart'),
                              child: SizedBox(
                                height: kAltezzaGraficoStatistiche,
                                child: ActivityChart(sessions: sessions),
                              ),
                            ),
                          ),
                          SizedBox(height: t.spacing.md),
                          RepaintBoundary(
                            child: ExpressiveCard(
                              title: loc.t('body_progress_chart'),
                              child: SizedBox(
                                height: kAltezzaGraficoStatistiche,
                                child: BodyMeasurementsChart(userId: userId),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ),
              ),
            ] else ...[
              // HISTORY VIEW
              sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(t.spacing.xxl),
                          child: Text(loc.t('no_workouts_history')),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final session = sessions[index];
                      final isToday =
                          DateTime.now()
                                  .difference(session.startTime)
                                  .inDays ==
                              0 &&
                          session.startTime.day == DateTime.now().day;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: _buildHistoryItem(
                          context,
                          session,
                          isToday,
                          loc,
                        ),
                      );
                    }, childCount: sessions.length),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],

            SliverPadding(
              padding: EdgeInsets.only(bottom: t.spacing.bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WorkoutSession session,
    bool isToday,
    Localization loc,
  ) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerLg,
        boxShadow: t.elevation.level2(scheme.shadow),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkoutSummaryScreen(session: session),
              ),
            );
          },
          borderRadius: t.shape.cornerLg,
          child: Padding(
            padding: EdgeInsets.all(t.spacing.lg),
            child: Row(
              children: [
                // Date Badge
                Container(
                  width: t.sizing.thumbnailMd,
                  height: t.sizing.thumbnailMd,
                  decoration: BoxDecoration(
                    // Oggi porta l'ambra perche e la giornata su cui stai
                    // agendo; le altre restano una superficie neutra.
                    color: isToday
                        ? scheme.primary.withValues(alpha: 0.1)
                        : scheme.surfaceContainerHighest,
                    borderRadius: t.shape.cornerMd,
                    border: isToday
                        ? Border.all(
                            color: scheme.primary.withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(session.startTime),
                        style: t.typography.metricSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isToday ? scheme.primary : scheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM',
                        ).format(session.startTime).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: t.spacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.workoutName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: t.spacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: t.spacing.md,
                            color: scheme.onSurfaceVariant,
                          ),
                          SizedBox(width: t.spacing.xs),
                          Text(
                            DateFormat('HH:mm').format(session.startTime),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (session.durationSeconds > 0) ...[
                            SizedBox(width: t.spacing.sm),
                            Icon(
                              Icons.timer_outlined,
                              size: t.spacing.md,
                              color: scheme.onSurfaceVariant,
                            ),
                            SizedBox(width: t.spacing.xs),
                            Text(
                              '${session.durationSeconds ~/ 60} min',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(t.spacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: t.spacing.xl, color: color),
          ),
          SizedBox(height: t.spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                // I numeri del mockout sono monospaziati con cifre tabulari,
                // cosi non ballano quando cambiano.
                style: t.typography.metricMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (suffix != null)
                Text(
                  ' $suffix',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

}

/// La sintesi salute delle statistiche: passi e calorie di oggi.
///
/// È un widget suo e non un metodo della schermata perche `StatisticsScreen`
/// intera non si monta in un test — legge Firestore e i provider della
/// dashboard — e senza montarla non c'e modo di dimostrare la cosa che questa
/// storia promette: che quando il permesso manca **non compare uno zero**.
class HealthSummarySection extends StatelessWidget {
  const HealthSummarySection({
    super.key,
    required this.future,
    required this.loc,
    required this.onConsenti,
  });

  /// La sintesi giornaliera, o l'errore che ne ha impedito la lettura.
  final Future<Map<String, dynamic>>? future;
  final Localization loc;

  /// Chiede i permessi. Vive nella schermata, che ha `ref`.
  final VoidCallback onConsenti;

  /// Il nome leggibile di un tipo di dato, per dire cosa manca.
  String _nome(HealthDataType tipo, Localization loc) => switch (tipo) {
    HealthDataType.STEPS => loc.t('steps_label'),
    HealthDataType.ACTIVE_ENERGY_BURNED => loc.t('active_cal_label'),
    _ => tipo.name,
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          // Prima di questa storia l'errore finiva in `snapshot.data ?? {}` e
          // diventava «0 passi, 0 calorie». Uno zero inventato e peggio di un
          // dato assente: il secondo si nota e si chiede, il primo si crede.
          final errore = snapshot.error;
          return _avviso(
            context,
            errore is PermessiSaluteMancanti ? errore.tipi : null,
          );
        }
        final data = snapshot.data ?? {};
        final steps = data['steps'] ?? 0;
        final calories = data['calories'] ?? 0;
        final t = context.expressive;
        final scheme = Theme.of(context).colorScheme;

        return Row(
          children: [
            Expanded(
              child: ExpressiveCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.STEPS,
                        title: loc.t('steps_label'),
                        baseColor: scheme.secondary,
                        unit: 'steps',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  context,
                  loc.t('steps_label'),
                  '$steps',
                  Icons.directions_walk,
                  scheme.secondary,
                ),
              ),
            ),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: ExpressiveCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.ACTIVE_ENERGY_BURNED,
                        title: loc.t('active_cal_label'),
                        baseColor: scheme.tertiary,
                        unit: 'kcal',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  context,
                  loc.t('active_cal_label'),
                  '${calories.toInt()}',
                  Icons.local_fire_department,
                  // Le calorie sono un dato vitale come il battito: salmone.
                  // Il rosso che c'era qui e il ruolo dell'errore.
                  scheme.tertiary,
                  suffix: ' kcal',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        SizedBox(height: t.spacing.sm),
        Text(
          value + (suffix ?? ''),
          style: t.typography.metricSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _avviso(BuildContext context, List<HealthDataType>? mancanti) {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.lg),
      child: ExpressiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.error),
                SizedBox(width: t.spacing.sm),
                Expanded(
                  child: Text(
                    loc.t('health_permission_needed'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // Quali dati mancano, quando si sa: e la differenza fra «qualcosa
            // non va» e un'informazione su cui si puo agire. Se non si sa —
            // `hasPermissions` non sempre risponde — non si inventa un elenco.
            if (mancanti != null && mancanti.isNotEmpty) ...[
              SizedBox(height: t.spacing.sm),
              Text(
                '${loc.t('health_permission_missing_prefix')} '
                '${mancanti.map((tipo) => _nome(tipo, loc)).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: t.spacing.md),
            FilledButton.icon(
              onPressed: onConsenti,
              icon: const Icon(Icons.health_and_safety_outlined),
              label: Text(loc.t('health_permission_grant')),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
