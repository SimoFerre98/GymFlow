import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/session.dart';
import '../../core/utils/statistics_helper.dart';
import '../widgets/charts/activity_chart.dart';
import '../widgets/charts/workout_type_pie_chart.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService().getUserProfile();
    if (mounted) {
      setState(() => _userProfile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final userId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: firestore.getUserSessions(userId),
        builder: (context, snapshot) {
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final sessions = snapshot.data ?? [];
          final weeklyData = StatisticsHelper.getWeeklyWorkoutCounts(sessions);
          final streak = StatisticsHelper.calculateCurrentStreak(sessions);

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "Overview"),
                    Tab(text: "History"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Overview Tab
                      _buildOverviewTab(
                        context,
                        sessions,
                        weeklyData,
                        streak,
                        isLoading,
                      ),
                      // History Tab
                      _buildHistoryTab(sessions, isLoading),
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
    List<WorkoutSession> sessions,
    Map<int, int> weeklyData,
    int streak,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
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
                    'Workouts',
                    sessions.length.toString(),
                    Icons.fitness_center,
                    Colors.blue,
                    isLoading,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBentoCard(
                  child: _buildStatContent(
                    'Streak',
                    '$streak Days',
                    Icons.local_fire_department,
                    Colors.orange,
                    isLoading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 1.5: Detailed Volume/RPE Stats
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  child: _buildStatContent(
                    'Total Volume',
                    isLoading
                        ? '0'
                        : '${(StatisticsHelper.calculateTotalVolume(sessions) / 1000).toStringAsFixed(1)}k',
                    Icons.monitor_weight_outlined,
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
                    'Avg RPE',
                    isLoading
                        ? '0'
                        : StatisticsHelper.calculateAverageRPE(
                            sessions,
                          ).toStringAsFixed(1),
                    Icons.speed,
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
            _buildGymBentoCard(),
            const SizedBox(height: 16),
          ],

          // Row 3: Charts (Medium Bento Cards)
          // Using a Column for mobile, but styled as blocks
          _buildBentoCard(
            title: 'Weekly Activity',
            child: SizedBox(
              height: 200,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ActivityChart(weeklyData: weeklyData),
            ),
          ),
          const SizedBox(height: 16),

          _buildBentoCard(
            title: 'Workout Types',
            child: isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : WorkoutTypePieChart(
                    data: StatisticsHelper.getWorkoutTypeDistribution(sessions),
                  ),
          ),
          const SizedBox(height: 100), // Space for FAB/BottomNav
        ],
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
    return Column(
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
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGymBentoCard() {
    if (_userProfile?.gymLat == null) return const SizedBox.shrink();

    // Simplified Map Card for Bento
    return _buildBentoCard(
      title: _userProfile?.gymName ?? 'My Gym',
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

  Widget _buildHistoryTab(List<WorkoutSession> sessions, bool isLoading) {
    if (isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.grey[300]),
              title: Container(height: 16, width: 100, color: Colors.grey[300]),
              subtitle: Container(
                height: 12,
                width: 150,
                color: Colors.grey[300],
              ),
            ),
          );
        },
      );
    }

    if (sessions.isEmpty) {
      return const Center(child: Text("No workouts yet. Start training!"));
    }

    // Sort by date desc
    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final session = sorted[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(
              session.workoutName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('EEEE, MMM d @ HH:mm').format(session.startTime),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Detail view? For now just print or no-op
            },
          ),
        );
      },
    );
  }
}
