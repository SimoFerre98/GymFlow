import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:intl/intl.dart';

/// Altezza della barra a pillola delle scheda: geometria di questa
/// schermata, non una misura condivisa.
const double _kAltezzaBarraTab = 50;

/// Raggio del ritratto grande in cima al profilo dell'amico.
const double _kRaggioAvatarProfilo = 60;

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
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
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
      appBar: AppBar(
        title: Text(widget.friend.displayName),
        leading: BackPill(label: loc.t('connect_friends_title')),
        leadingWidth: BackPill.leadingWidth,
      ),
      body: Column(
        children: [
          // Pill TabBar
          if (tabs.length > 1)
            Container(
              height: _kAltezzaBarraTab,
              margin: EdgeInsets.all(t.spacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: t.shape.cornerFull,
                boxShadow: t.elevation.level2(scheme.shadow),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: t.shape.cornerFull,
                  color: scheme.primary,
                  boxShadow: t.elevation.level1(scheme.primary),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: scheme.onPrimary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
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
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.all(t.spacing.xl),
      child: Column(
        children: [
          CircleAvatar(
            radius: _kRaggioAvatarProfilo,
            backgroundImage: widget.friend.photoUrl != null
                ? NetworkImage(widget.friend.photoUrl!)
                : null,
            child: widget.friend.photoUrl == null
                ? Text(
                    widget.friend.displayName.isNotEmpty
                        ? widget.friend.displayName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                : null,
          ),
          SizedBox(height: t.spacing.xl),
          Text(
            widget.friend.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          if (widget.friend.gymName != null) ...[
            SizedBox(height: t.spacing.sm),
            Text(
              '${loc.t('gym_label')}: ${widget.friend.gymName}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: t.spacing.xxl),
          _buildStatCard(
            context,
            loc.t('streak_label'),
            '${widget.friend.streakDays} ${loc.t('days_label')}',
            Icons.local_fire_department,
            AppPalette.categoryOrange,
          ),
          SizedBox(height: t.spacing.md),
          if (!_canViewCalendar && !_canViewPrograms)
            Padding(
              padding: EdgeInsets.only(top: t.spacing.xl),
              child: Text(
                loc
                    .t('friend_no_shared_content')
                    .replaceFirst('%s', widget.friend.displayName),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
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
          padding: EdgeInsets.all(t.spacing.md),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              margin: EdgeInsets.only(bottom: t.spacing.sm),
              child: ListTile(
                leading: Icon(Icons.history, color: scheme.onSurfaceVariant),
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
    final t = context.expressive;
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
          padding: EdgeInsets.all(t.spacing.md),
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final program = programs[index];
            return Card(
              margin: EdgeInsets.only(bottom: t.spacing.sm),
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
          ref
              .read(localizationNotifierProvider)
              .t('import_program_confirm')
              .replaceFirst('%s', program.name),
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
          ToastUtils.showError(
            context,
            '${ref.read(localizationNotifierProvider).t('import_failed')}: $e',
          );
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
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: t.shape.cornerMd,
        boxShadow: t.elevation.level2(scheme.shadow),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(t.spacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: t.shape.cornerSm,
            ),
            child: Icon(icon, color: color, size: t.sizing.iconLg),
          ),
          SizedBox(width: t.spacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
