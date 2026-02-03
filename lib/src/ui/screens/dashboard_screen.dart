import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/session.dart';
import '../../core/utils/statistics_helper.dart';
import '../widgets/charts/activity_chart.dart';
import '../widgets/charts/workout_type_pie_chart.dart';
import '../widgets/charts/body_measurements_chart.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_profile.dart';
import '../../services/health_service.dart';
import 'package:health/health.dart';
import '../../core/providers/localization_provider.dart';
import 'health_detail_screen.dart';

import '../../models/workout.dart';
import 'active_session_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile? _userProfile;
  Future<Map<String, dynamic>>? _healthDataFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Initialize health and then fetch
    _healthDataFuture = _initAndFetchHealth();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService().getUserProfile();
    if (mounted) {
      setState(() => _userProfile = profile);
    }
  }

  Future<Map<String, dynamic>> _initAndFetchHealth() async {
    if (kIsWeb) return {};
    try {
      await HealthService().configure(); // Ensure it's configured
      return await HealthService().fetchDailySummary();
    } catch (e) {
      print('Health Load Error: $e');
      // Return empty map or specific error indicator if needed
      // But rethrow so FutureBuilder catches it
      rethrow;
    }
  }

  Future<void> _refreshHealthData() async {
    setState(() {
      _healthDataFuture = HealthService()
          .fetchDailySummary(); // Already configured
    });
    // Wait for the future to complete so the refresh indicator spins until done
    try {
      await _healthDataFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final loc = Provider.of<LocalizationProvider>(context);
    final userId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('dashboard_title'))),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickStartMenu(context, userId),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(loc.t('quick_start') ?? 'Quick Start'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: firestore.getUserSessions(userId),
        builder: (context, snapshot) {
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final sessions = snapshot.data ?? [];
          final streak = StatisticsHelper.calculateCurrentStreak(sessions);

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Custom Tab Selector (Premium Segmented Control)
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    dividerColor:
                        Colors.transparent, // Remove default underline
                    tabs: [
                      Tab(text: loc.t('overview_tab')),
                      Tab(text: loc.t('history_tab')),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Overview Tab
                      _buildOverviewTab(
                        context,
                        userId,
                        sessions,
                        streak,
                        isLoading,
                        loc,
                      ),
                      // History Tab
                      _buildHistoryTab(sessions, isLoading, loc),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    String userId,
    List<WorkoutSession> sessions,
    int streak,
    bool isLoading,
    LocalizationProvider loc,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshHealthData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure refresh works even if content is short
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting / Header could go here

            // Row 1: Quick Stats (Small Bento Cards)
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    child: _buildStatContent(
                      loc.t('workouts_label'),
                      sessions.length.toString(),
                      Icons.fitness_center_rounded,
                      Colors.blue,
                      isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBentoCard(
                    child: _buildStatContent(
                      loc.t('streak_label'),
                      '$streak ${loc.t('days_label')}',
                      Icons.local_fire_department_rounded,
                      Colors.orange,
                      isLoading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health / Wellness Row
            FutureBuilder<Map<String, dynamic>>(
              future: _healthDataFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final steps = data?['steps'] ?? 0;
                final calories = data?['calories'] ?? 0.0;
                final heartRate = data?['heartRate'] ?? 0;
                final sleep = data?['sleepMinutes'] ?? 0;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LinearProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Could not load health data: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (data == null && !snapshot.hasData) {
                  return const SizedBox.shrink(); // Hide if no data (and no error)
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildBentoCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HealthDetailScreen(
                                  dataType: HealthDataType.STEPS,
                                  title: loc.t('steps_label'),
                                  baseColor: Colors.teal,
                                  unit: 'steps',
                                ),
                              ),
                            ),
                            child: _buildStatContent(
                              loc.t('steps_label'),
                              '$steps',
                              Icons.directions_walk,
                              Colors.teal,
                              false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBentoCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HealthDetailScreen(
                                  dataType: HealthDataType.ACTIVE_ENERGY_BURNED,
                                  title: loc.t('active_cal_label'),
                                  baseColor: Colors.red,
                                  unit: 'kcal',
                                ),
                              ),
                            ),
                            child: _buildStatContent(
                              loc.t('active_cal_label'),
                              '${calories.toInt()}',
                              Icons.local_fire_department,
                              Colors.red,
                              false,
                              suffix: ' kcal',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBentoCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HealthDetailScreen(
                                  dataType: HealthDataType.HEART_RATE,
                                  title: loc.t('heart_rate_label'),
                                  baseColor: Colors.pink,
                                  unit: 'bpm',
                                ),
                              ),
                            ),
                            child: _buildStatContent(
                              loc.t('heart_rate_label'),
                              heartRate > 0 ? '$heartRate' : '--',
                              Icons.favorite,
                              Colors.pink,
                              false,
                              suffix: ' bpm',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBentoCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HealthDetailScreen(
                                  dataType: HealthDataType.SLEEP_SESSION,
                                  title: loc.t('sleep_label'),
                                  baseColor: Colors.indigo,
                                  unit: 'hours',
                                ),
                              ),
                            ),
                            child: _buildStatContent(
                              loc.t('sleep_label'),
                              sleep > 0
                                  ? '${(sleep / 60).toStringAsFixed(1)}'
                                  : '--',
                              Icons.bedtime,
                              Colors.indigo,
                              false,
                              suffix: ' h',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Row 1.5: Detailed Volume/RPE Stats
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    child: _buildStatContent(
                      loc.t('volume_label'),
                      isLoading
                          ? '0'
                          : '${(StatisticsHelper.calculateTotalVolume(sessions) / 1000).toStringAsFixed(1)}k',
                      Icons.scale_rounded,
                      Colors.purple,
                      isLoading,
                      suffix: ' kg',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBentoCard(
                    child: _buildStatContent(
                      loc.t('avg_intensity_label'),
                      isLoading
                          ? '0'
                          : StatisticsHelper.calculateAverageRPE(
                              sessions,
                            ).toStringAsFixed(1),
                      Icons.speed_rounded,
                      Colors.redAccent,
                      isLoading,
                      suffix: '/10',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Gym Map (Wide Bento Card)
            if (_userProfile?.gymLat != null) ...[
              _buildGymBentoCard(loc),
              const SizedBox(height: 16),
            ],

            // Row 3: Charts (Medium Bento Cards)
            // Using a Column for mobile, but styled as blocks
            _buildBentoCard(
              title: loc.t('workout_activity_chart'),
              child: SizedBox(
                height: 200,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ActivityChart(sessions: sessions),
              ),
            ),
            const SizedBox(height: 16),

            // Body Progress Chart
            _buildBentoCard(
              title: loc.t('body_progress_chart'),
              child: BodyMeasurementsChart(userId: userId),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),

            _buildBentoCard(
              title: loc.t('workout_types_chart'),
              child: isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : WorkoutTypePieChart(
                      data: StatisticsHelper.getWorkoutTypeDistribution(
                        sessions,
                      ),
                    ),
            ),
            const SizedBox(height: 100), // Space for FAB/BottomNav
          ],
        ),
      ),
    );
  }

  // Helper for Bento Card Style
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

  Widget _buildStatContent(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isLoading, {
    String? suffix,
  }) {
    return Stack(
      children: [
        Column(
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
            const SizedBox(height: 16),
            isLoading
                ? Container(
                    height: 28,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      if (suffix != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            suffix,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        // Add Chevron if it's a clickable metric (implied by this method being used in those tiles)
        // We can make this conditional or just added for all stats that use this method
        // For simplicity, we add it top-right.
        Positioned(
          top: 0,
          right: 0,
          child: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey[300],
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildGymBentoCard(LocalizationProvider loc) {
    if (_userProfile?.gymLat == null) return const SizedBox.shrink();

    // Simplified Map Card for Bento
    return _buildBentoCard(
      title: _userProfile?.gymName ?? loc.t('my_gym_label'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                _userProfile!.gymLat!,
                _userProfile!.gymLng!,
              ),
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gymflow.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_userProfile!.gymLat!, _userProfile!.gymLng!),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
    List<WorkoutSession> sessions,
    bool isLoading,
    LocalizationProvider loc,
  ) {
    if (isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      );
    }

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              loc.t('no_workouts_history'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('start_training_msg'),
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Sort by date desc
    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final session = sorted[index];
        final isToday =
            DateTime.now().difference(session.startTime).inDays == 0 &&
            session.startTime.day == DateTime.now().day;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (session.durationSeconds > 0) ...[
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${session.durationSeconds ~/ 60}m',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status/Action
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuickStartMenu(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  Provider.of<LocalizationProvider>(
                        context,
                        listen: false,
                      ).t('quick_start') ??
                      'Quick Start',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<WorkoutTemplate>>(
                  stream: FirestoreService().getUserWorkouts(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('No workouts found'),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                // Optional: Navigate to creator
                              },
                              child: const Text('Create One'),
                            ),
                          ],
                        ),
                      );
                    }

                    final workouts = snapshot.data!;
                    return ListView.builder(
                      itemCount: workouts.length,
                      itemBuilder: (context, index) {
                        final workout = workouts[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            workout.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${workout.exercises.length} exercises • ${workout.category.name}',
                          ),
                          trailing: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.green,
                            size: 32,
                          ),
                          onTap: () {
                            Navigator.pop(ctx); // Close sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ActiveSessionScreen(workout: workout),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
