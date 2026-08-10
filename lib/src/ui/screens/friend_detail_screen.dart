import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:intl/intl.dart';

class FriendDetailScreen extends ConsumerStatefulWidget {
  final UserProfile friend;

  const FriendDetailScreen({super.key, required this.friend});

  @override
  ConsumerState<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends ConsumerState<FriendDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canViewCalendar = false;
  bool _canViewPrograms = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService().currentUser?.uid;
    _checkPermissions();
    _tabController = TabController(length: _calculateTabCount(), vsync: this);
  }

  void _checkPermissions() {
    if (_currentUserId == null) return;
    setState(() {
      _canViewCalendar = widget.friend.calendarSharedWith.contains(
        _currentUserId,
      );
      _canViewPrograms = widget.friend.programsSharedWith.contains(
        _currentUserId,
      );
    });
  }

  int _calculateTabCount() {
    int count = 1; // Profile always visible
    if (_canViewCalendar) count++;
    if (_canViewPrograms) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    // Re-calc tabs in build in case permissions change (though passed in widget is const)
    // For now assuming static permissions for this session
    final tabs = <Widget>[Tab(text: loc.t('profile_tab'))];
    final views = <Widget>[_buildProfileTab()];

    if (_canViewCalendar) {
      tabs.add(Tab(text: loc.t('calendar_tab')));
      views.add(_buildCalendarTab());
    }
    if (_canViewPrograms) {
      tabs.add(Tab(text: loc.t('programs_tab')));
      views.add(_buildProgramsTab());
    }

    // Update controller if count changed (unlikely in this flow but good practice)
    if (_tabController.length != tabs.length) {
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.friend.displayName)),
      body: Column(
        children: [
          // Pill TabBar
          if (tabs.length > 1)
            Container(
              height: 50,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600], // Visible in light/dark
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                dividerColor: Colors.transparent,
                tabs: tabs,
              ),
            ),

          // Content
          Expanded(
            child: tabs.length > 1
                ? TabBarView(controller: _tabController, children: views)
                : _buildProfileTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: widget.friend.photoUrl != null
                ? NetworkImage(widget.friend.photoUrl!)
                : null,
            child: widget.friend.photoUrl == null
                ? Text(
                    widget.friend.displayName.isNotEmpty
                        ? widget.friend.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 48),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            widget.friend.displayName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (widget.friend.gymName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Gym: ${widget.friend.gymName}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
          const SizedBox(height: 32),
          _buildStatCard(
            context,
            'Streak',
            '${widget.friend.streakDays} Days',
            Icons.local_fire_department,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          if (!_canViewCalendar && !_canViewPrograms)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Text(
                '${widget.friend.displayName} hasn\'t shared any content yet.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return StreamBuilder<List<WorkoutSession>>(
      stream: FirestoreService().getUserSessions(widget.friend.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return Center(child: Text(ref.read(localizationNotifierProvider).t('no_history_shared')));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: Text(session.workoutName),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(session.startTime),
                ),
                trailing: Text(
                  '${session.durationSeconds ~/ 60}m',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgramsTab() {
    return StreamBuilder<List<WorkoutProgram>>(
      stream: FirestoreService().getUserPrograms(widget.friend.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final programs = snapshot.data ?? [];
        if (programs.isEmpty) {
          return Center(child: Text(ref.read(localizationNotifierProvider).t('no_programs_shared')));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final program = programs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(program.name),
                subtitle: Text('${program.workoutIds.length} workouts'),
                trailing: IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => _importProgram(program),
                  tooltip: ref.read(localizationNotifierProvider).t('import_program_tooltip'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _importProgram(WorkoutProgram program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.read(localizationNotifierProvider).t('import_program_title')),
        content: Text(
          'Do you want to add "${program.name}" to your library? This will create a copy of the program and all its workouts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ref.read(localizationNotifierProvider).t('cancel_caps')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ref.read(localizationNotifierProvider).t('import_caps')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_currentUserId == null) return;
      try {
        await FirestoreService().importSharedProgram(program, _currentUserId!);
        if (mounted) {
          ToastUtils.showSuccess(context, ref.read(localizationNotifierProvider).t('program_imported_success'));
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.showError(context, 'Failed to import: $e');
        }
      }
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
