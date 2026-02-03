import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/session.dart';
import '../../core/utils/statistics_helper.dart';
import '../widgets/charts/activity_chart.dart';
import '../widgets/charts/body_measurements_chart.dart';
import '../widgets/app_drawer.dart';
import '../../services/health_service.dart';
import 'package:health/health.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import 'health_detail_screen.dart';

class DashboardScreen extends riverpod.ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  riverpod.ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends riverpod.ConsumerState<DashboardScreen> {
  Future<Map<String, dynamic>>? _healthDataFuture;

  @override
  void initState() {
    super.initState();
    // _loadProfile();
    _healthDataFuture = _initAndFetchHealth();
  }

  Future<Map<String, dynamic>> _initAndFetchHealth() async {
    if (kIsWeb) return {};
    try {
      await HealthService().configure();
      return await HealthService().fetchDailySummary();
    } catch (e) {
      debugPrint('Health Load Error: $e');
      rethrow;
    }
  }

  Future<void> _refreshHealthData() async {
    setState(() {
      _healthDataFuture = HealthService().fetchDailySummary();
    });
    try {
      await _healthDataFuture;
    } catch (_) {}
    // Also refresh sessions
    // ref.refresh(dashboardSessionsProvider); // Stream auto-updates, but we could force sync if needed
  }

  @override
  Widget build(BuildContext context) {
    // Legacy provider
    final loc = Provider.of<LocalizationProvider>(context);
    final userId = AuthService().currentUser?.uid ?? '';
    final sessionsAsync = ref.watch(dashboardSessionsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: Text(loc.t('dashboard_title')),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshHealthData,
                ),
              ],
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshHealthData,
          child: CustomScrollView(
            slivers: [
              // BENTO GRID & HEADER STATS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Quick Start Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showQuickStartMenu(context, userId),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(loc.t('quick_start')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      sessionsAsync.when(
                        data: (sessions) {
                          final streak =
                              StatisticsHelper.calculateCurrentStreak(sessions);
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      loc.t('workouts_label'),
                                      '${sessions.length}',
                                      Icons.fitness_center,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      loc.t('streak_label'),
                                      '$streak',
                                      Icons.local_fire_department,
                                      Colors.orange,
                                      suffix: loc.t('days_label'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Health
                              _buildHealthSection(loc),
                              const SizedBox(height: 16),

                              // Charts (RepaintBoundary for Performance)
                              RepaintBoundary(
                                child: _buildBentoCard(
                                  title: loc.t('workout_activity_chart'),
                                  child: SizedBox(
                                    height: 200,
                                    child: ActivityChart(sessions: sessions),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              RepaintBoundary(
                                child: _buildBentoCard(
                                  title: loc.t('body_progress_chart'),
                                  child: BodyMeasurementsChart(userId: userId),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error: $err'),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Text(
                    loc.t('history_tab'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),

              // HISTORY LIST (SliverList)
              sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(child: Text(loc.t('no_workouts_history'))),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final session = sessions[index];
                      final isToday =
                          DateTime.now().difference(session.startTime).inDays ==
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
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
      drawer: const AppDrawer(),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WorkoutSession session,
    bool isToday,
    LocalizationProvider loc,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Detail view
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Date Badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: isToday
                        ? Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.5),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(session.startTime),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : Colors.grey[800],
                          height: 1.0,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM',
                        ).format(session.startTime).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.workoutName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(session.startTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (session.durationSeconds > 0) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.durationSeconds ~/ 60} min',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    return _buildBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (suffix != null)
                Text(
                  ' $suffix',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
            ],
          ),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required Widget child,
    String? title,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthSection(LocalizationProvider loc) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _healthDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LinearProgressIndicator();
        final data = snapshot.data ?? {};
        final steps = data['steps'] ?? 0;
        final calories = data['calories'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.STEPS,
                        title: loc.t('steps_label'),
                        baseColor: Colors.teal,
                        unit: 'steps',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  loc.t('steps_label'),
                  '$steps',
                  Icons.directions_walk,
                  Colors.teal,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.ACTIVE_ENERGY_BURNED,
                        title: loc.t('active_cal_label'),
                        baseColor: Colors.red,
                        unit: 'kcal',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  loc.t('active_cal_label'),
                  '${calories.toInt()}',
                  Icons.local_fire_department,
                  Colors.red,
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
    String title,
    String value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value + (suffix ?? ''),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  void _showQuickStartMenu(BuildContext context, String userId) {
    // TODO: Implement Quick Start Menu
  }
}
