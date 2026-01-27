import 'package:flutter/material.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/friend_detail_screen.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';

class ConnectFriendScreen extends StatefulWidget {
  const ConnectFriendScreen({super.key});

  @override
  State<ConnectFriendScreen> createState() => _ConnectFriendScreenState();
}

class _ConnectFriendScreenState extends State<ConnectFriendScreen> {
  final _codeController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  String? _myFriendCode;

  @override
  void initState() {
    super.initState();
    _loadMyCode();
  }

  Future<void> _loadMyCode() async {
    // Ensure code exists (backfill for legacy users)
    final code = await _auth.ensureFriendCode();
    setState(() {
      _myFriendCode = code ?? 'N/A';
    });
  }

  Future<void> _connectWithFriend() async {
    final loc = Provider.of<LocalizationProvider>(context, listen: false);
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ToastUtils.showInfo(
        context,
        loc.t('enter_friend_code'),
      ); // reusing enter code label or strict "please enter"
      return;
    }

    if (code == _myFriendCode) {
      ToastUtils.showError(context, loc.t('cant_add_self'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _firestore.addFriendByCode(code);
      if (success) {
        if (mounted) {
          ToastUtils.showSuccess(context, loc.t('friend_connected'));
          _codeController.clear();
        }
      } else {
        if (mounted) {
          ToastUtils.showError(context, '${loc.t('friend_not_found')} $code');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '${loc.t('error_connecting')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('connect_friends_title')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // My Friend Code Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    loc.t('your_friend_code'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _myFriendCode ?? 'loading...',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      // Ensure readable on the light red bg, or switch bg.
                      // Theme.of(context).primaryColor is usually dark red/purple, which works on light opacity.
                      // If in dark mode, the container might need adjustment.
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('share_code_msg'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Enter Code Section
            Text(
              loc.t('enter_friend_code'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: loc.t('friend_code_hint'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_add_alt_1),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _connectWithFriend,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      loc.t('connect_btn'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 48),
            Text(
              loc.t('your_friends_list'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<UserProfile?>(
              stream: _auth.getUserProfileStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = snapshot.data!;
                final friendIds = user.friends;

                if (friendIds.isEmpty) {
                  return Center(
                    child: Text(
                      loc.t('no_friends_msg'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return FutureBuilder<List<UserProfile>>(
                  future: _firestore.getUsers(friendIds),
                  builder: (context, friendSnapshot) {
                    if (!friendSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final friends = friendSnapshot.data!;

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friends.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: friend.photoUrl != null
                                ? NetworkImage(friend.photoUrl!)
                                : null,
                            child: friend.photoUrl == null
                                ? Text(friend.displayName[0].toUpperCase())
                                : null,
                          ),
                          title: Text(friend.displayName),
                          subtitle: Text(
                            '@${friend.displayName}',
                          ), // Or real username if we had it
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.privacy_tip_outlined),
                                onPressed: () => _showAccessControl(friend),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FriendDetailScreen(friend: friend),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccessControl(UserProfile friend) {
    showDialog(
      context: context,
      builder: (context) {
        return _AccessControlDialog(friend: friend);
      },
    );
  }
}

class _AccessControlDialog extends StatefulWidget {
  final UserProfile friend;

  const _AccessControlDialog({required this.friend});

  @override
  State<_AccessControlDialog> createState() => _AccessControlDialogState();
}

class _AccessControlDialogState extends State<_AccessControlDialog> {
  bool _shareCalendar = false;
  bool _sharePrograms = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final currentUser = await AuthService().getUserProfile();
    if (currentUser != null && mounted) {
      setState(() {
        _shareCalendar = currentUser.calendarSharedWith.contains(
          widget.friend.id,
        );
        _sharePrograms = currentUser.programsSharedWith.contains(
          widget.friend.id,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(String type, bool value) async {
    // Optimistic update
    setState(() {
      if (type == 'calendar') _shareCalendar = value;
      if (type == 'programs') _sharePrograms = value;
    });

    await FirestoreService().toggleFriendAccess(widget.friend.id, type, value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationProvider>(context);

    return AlertDialog(
      title: Text('${loc.t('privacy_settings')} ${widget.friend.displayName}'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(loc.t('share_calendar')),
                  subtitle: Text(loc.t('share_calendar_sub')),
                  value: _shareCalendar,
                  onChanged: (val) => _toggle('calendar', val),
                ),
                SwitchListTile(
                  title: Text(loc.t('share_programs')),
                  subtitle: Text(loc.t('share_programs_sub')),
                  value: _sharePrograms,
                  onChanged: (val) => _toggle('programs', val),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.t('done')),
        ),
      ],
    );
  }
}
