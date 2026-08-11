import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/friend_detail_screen.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';

/// Altezza del contenuto del dialogo mentre carica le impostazioni di
/// condivisione: geometria di questo dialogo.
const double _kAltezzaCaricamentoDialogo = 100;

class ConnectFriendScreen extends ConsumerStatefulWidget {
  const ConnectFriendScreen({super.key});

  @override
  ConsumerState<ConnectFriendScreen> createState() => _ConnectFriendScreenState();
}

class _ConnectFriendScreenState extends ConsumerState<ConnectFriendScreen> {
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCode() async {
    // Ensure code exists (backfill for legacy users)
    final code = await _auth.ensureFriendCode();
    setState(() {
      _myFriendCode = code ?? 'N/A';
    });
  }

  Future<void> _connectWithFriend() async {
    final loc = ref.read(localizationNotifierProvider);
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
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;

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
        padding: EdgeInsets.all(t.spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // My Friend Code Section
            Container(
              padding: EdgeInsets.all(t.spacing.xl),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: t.shape.cornerMd,
                border: Border.all(color: scheme.outline),
              ),
              child: Column(
                children: [
                  Text(
                    loc.t('your_friend_code'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: t.spacing.sm),
                  SelectableText(
                    _myFriendCode ?? 'loading...',
                    style: t.typography.metricLarge?.copyWith(
                      color: scheme.onSurface,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: t.spacing.sm),
                  Text(
                    loc.t('share_code_msg'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            SizedBox(height: t.spacing.xxl),

            // Enter Code Section
            Text(
              loc.t('enter_friend_code'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: t.spacing.md),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: loc.t('friend_code_hint'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_add_alt_1),
              ),
            ),
            SizedBox(height: t.spacing.xl),
            ElevatedButton(
              onPressed: _isLoading ? null : _connectWithFriend,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: t.spacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: t.shape.cornerSm,
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: t.sizing.iconMd,
                      height: t.sizing.iconMd,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      loc.t('connect_btn'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(height: t.spacing.xxl),
            Text(
              loc.t('your_friends_list'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: t.spacing.md),
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
                      style: TextStyle(color: scheme.onSurfaceVariant),
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
                      separatorBuilder: (_, _) => SizedBox(height: t.spacing.sm),
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

class _AccessControlDialog extends ConsumerStatefulWidget {
  final UserProfile friend;

  const _AccessControlDialog({required this.friend});

  @override
  ConsumerState<_AccessControlDialog> createState() => _AccessControlDialogState();
}

class _AccessControlDialogState extends ConsumerState<_AccessControlDialog> {
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
    final loc = ref.watch(localizationNotifierProvider);

    return AlertDialog(
      title: Text('${loc.t('privacy_settings')} ${widget.friend.displayName}'),
      content: _isLoading
          ? const SizedBox(
              height: _kAltezzaCaricamentoDialogo,
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
