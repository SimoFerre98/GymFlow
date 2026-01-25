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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Workouts',
                  sessions.length.toString(),
                  Icons.fitness_center,
                  Colors.blue,
                  isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Current Streak',
                  '$streak Days',
                  Icons.local_fire_department,
                  Colors.orange,
                  isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gym Info Card
          _buildGymInfoCard(), // Could also be skeletonized, but relies on Profile which is async too... leave for now or fix if verified slow.
          const SizedBox(height: 24),
          const Text(
            'Weekly Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Activity Chart
          isLoading
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                )
              : ActivityChart(weeklyData: weeklyData),
          const SizedBox(height: 24),
          const Text(
            'Workout Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Pie Chart
          isLoading
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12), // Circle for pie?
                  ),
                )
              : WorkoutTypePieChart(
                  data: StatisticsHelper.getWorkoutTypeDistribution(sessions),
                ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGymInfoCard() {
    if (_userProfile?.gymName == null && _userProfile?.gymLat == null) {
      return const SizedBox.shrink();
    }

    final daysLeft = _userProfile?.subscriptionExpiry
        ?.difference(DateTime.now())
        .inDays;

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (_userProfile?.gymLat != null && _userProfile?.gymLng != null)
            SizedBox(
              height: 150,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    _userProfile!.gymLat!,
                    _userProfile!.gymLng!,
                  ),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ), // Static map
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gymflow.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _userProfile!.gymLat!,
                          _userProfile!.gymLng!,
                        ),
                        width: 80,
                        height: 80,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile?.gymName ?? 'My Gym',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userProfile?.gymAddress != null)
                  Text(
                    _userProfile!.gymAddress!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 10),
                if (daysLeft != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: daysLeft > 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      daysLeft > 0
                          ? '$daysLeft Days Remaining'
                          : 'Subscription Expired',
                      style: TextStyle(
                        color: daysLeft > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isLoading,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            isLoading
                ? Container(
                    height: 24,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
