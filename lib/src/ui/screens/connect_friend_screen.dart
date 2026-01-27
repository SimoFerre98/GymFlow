import 'package:flutter/material.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/friend_detail_screen.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';

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
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ToastUtils.showInfo(context, 'Please enter a friend code');
      return;
    }

    if (code == _myFriendCode) {
      ToastUtils.showError(context, "You can't add yourself!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _firestore.addFriendByCode(code);
      if (success) {
        if (mounted) {
          ToastUtils.showSuccess(context, 'Friend connected successfully!');
          _codeController.clear();
        }
      } else {
        if (mounted) {
          ToastUtils.showError(context, 'Friend not found with code: $code');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Error connecting: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect with Friends')),
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
                  const Text(
                    'Your Friend Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _myFriendCode ?? 'loading...',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share this code with your friends so they can add you!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Enter Code Section
            const Text(
              'Enter Friend Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. A1B2C3',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_add_alt_1),
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
                  : const Text(
                      'CONNECT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Your Friends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  return const Center(
                    child: Text(
                      'No friends yet. Add some!',
                      style: TextStyle(color: Colors.grey),
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
                      separatorBuilder: (_, __) => const Divider(),
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
                          trailing: const Icon(Icons.chevron_right),
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
}
