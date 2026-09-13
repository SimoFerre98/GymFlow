import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/invite.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/providers/invite_provider.dart';
import 'package:gymflow/src/ui/screens/friend_detail_screen.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
/// US-087: l'amico per codice non crea più un'amicizia istantanea (non ha
/// mai funzionato: scriveva sul documento di un altro utente, negato dalle
/// regole). Inserire un codice crea un invito in sospeso, che l'altra
/// persona deve accettare — lo stesso meccanismo del legame trainer↔cliente.
const double _kTitleFontSize = 28;
class ConnectFriendScreen extends ConsumerStatefulWidget {
  const ConnectFriendScreen({super.key});
  @override
  ConsumerState<ConnectFriendScreen> createState() => _ConnectFriendScreenState();
}
class _ConnectFriendScreenState extends ConsumerState<ConnectFriendScreen> {
  final _codeController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isSending = false;
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
    // Backfill per gli utenti registrati prima di US-087: genera anche lo
    // specchio pubblico in invite_codes se manca.
    final code = await _auth.ensureFriendCode();
    if (mounted) setState(() => _myFriendCode = code ?? 'N/A');
  }
  Future<void> _sendInvite(UserProfile myProfile) async {
    final loc = ref.read(localizationNotifierProvider);
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ToastUtils.showInfo(context, loc.t('enter_friend_code'));
      return;
    }
    if (code == _myFriendCode) {
      ToastUtils.showError(context, loc.t('cant_add_self'));
      return;
    }
    setState(() => _isSending = true);
    try {
      final invite = await ref.read(firestoreServiceProvider).createInvite(
        code: code,
        fromUserId: myProfile.id,
        fromDisplayName: myProfile.displayName,
        fromRole: myProfile.role.name,
        relationshipType: RelationshipType.friend,
      );
      if (!mounted) return;
      if (invite != null) {
        ToastUtils.showSuccess(context, loc.t('invite_sent_msg'));
        _codeController.clear();
      } else {
        ToastUtils.showError(context, loc.t('invite_code_not_found'));
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '${loc.t('error_connecting')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
  Future<void> _respond(Invite invite, bool accept) async {
    final loc = ref.read(localizationNotifierProvider);
    try {
      await ref.read(firestoreServiceProvider).respondToInvite(invite.id, accept);
      if (mounted) {
        ToastUtils.showSuccess(
          context,
          accept ? loc.t('invite_accepted_msg') : loc.t('invite_declined_msg'),
        );
      }
    } catch (e) {
      // Il caso più comune: l'invito è scaduto fra il caricamento della
      // lista e il tocco su "Accetta" — la regola lo nega, non un bug.
      if (mounted) ToastUtils.showError(context, '${loc.t('error_connecting')}: $e');
    }
  }
  Future<void> _cancelOutgoing(Invite invite) async {
    final loc = ref.read(localizationNotifierProvider);
    try {
      await ref.read(firestoreServiceProvider).revokeInvite(invite.id);
      if (mounted) ToastUtils.showSuccess(context, loc.t('invite_cancelled_msg'));
    } catch (e) {
      if (mounted) ToastUtils.showError(context, '${loc.t('error_connecting')}: $e');
    }
  }
  Future<void> _dissolve(Invite invite, String otherName) async {
    final loc = ref.read(localizationNotifierProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(loc.t('confirm_dissolve_msg').replaceFirst('%s', otherName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel_invite')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('dissolve_connection')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(firestoreServiceProvider).revokeInvite(invite.id);
      if (mounted) ToastUtils.showSuccess(context, loc.t('connection_dissolved_msg'));
    } catch (e) {
      if (mounted) ToastUtils.showError(context, '${loc.t('error_connecting')}: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    final myUserId = ref.watch(currentUserIdProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('home')),
                  SizedBox(width: t.spacing.md),
                  Text(
                    loc.t('connect_friends_title').toUpperCase(),
                    style: t.typography.headline?.copyWith(
                      fontSize: _kTitleFontSize,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(t.spacing.md),
                child: StreamBuilder<UserProfile?>(
                  stream: _auth.getUserProfileStream(),
                  builder: (context, profileSnap) {
                    final myProfile = profileSnap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMyCodeCard(t, scheme, loc),
                        SizedBox(height: t.spacing.xxl),
                        _buildEnterCodeSection(t, scheme, loc, myProfile),
                        SizedBox(height: t.spacing.xxl),
                        if (myUserId != null) ...[
                          _buildIncomingInvites(t, scheme, loc, myUserId),
                          SizedBox(height: t.spacing.xxl),
                          _buildOutgoingInvites(t, scheme, loc, myUserId),
                          SizedBox(height: t.spacing.xxl),
                          _buildConnections(t, scheme, loc, myUserId),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMyCodeCard(ImmersivoTokens t, ColorScheme scheme, Localization loc) {
    return Container(
      padding: EdgeInsets.all(t.spacing.xl),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          Text(
            loc.t('your_friend_code').toUpperCase(),
            style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
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
    );
  }
  Widget _buildEnterCodeSection(
    ImmersivoTokens t,
    ColorScheme scheme,
    Localization loc,
    UserProfile? myProfile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.t('enter_friend_code').toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.md),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            border: Border(left: BorderSide(color: scheme.outline, width: 3)),
          ),
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(t.spacing.md),
              hintText: loc.t('friend_code_hint'),
              prefixIcon: Icon(Icons.person_add_alt_1, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        SizedBox(height: t.spacing.xl),
        InkWell(
          onTap: (_isSending || myProfile == null)
              ? null
              : () => _sendInvite(myProfile),
          child: Container(
            height: t.sizing.minTouchTarget,
            color: scheme.primary,
            alignment: Alignment.center,
            child: _isSending
                ? SizedBox(
                    width: t.sizing.iconMd,
                    height: t.sizing.iconMd,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                  )
                : Text(
                    loc.t('send_invite_btn').toUpperCase(),
                    style: t.typography.title?.copyWith(color: scheme.onPrimary),
                  ),
          ),
        ),
      ],
    );
  }
  Widget _buildIncomingInvites(
    ImmersivoTokens t,
    ColorScheme scheme,
    Localization loc,
    String myUserId,
  ) {
    final invites = ref.watch(incomingInvitesProvider).value ?? const <Invite>[];
    if (invites.isEmpty) return const SizedBox.shrink();
    return _buildSection(
      t,
      scheme,
      title: loc.t('incoming_invites_title'),
      children: invites
          .map(
            (invite) => _InviteTile(
              title: invite.fromDisplayName,
              subtitle: invite.isExpired
                  ? loc.t('invite_expired_label')
                  : loc.t('invited_you_msg').replaceFirst('%s', invite.fromDisplayName),
              actions: [
                TextButton(
                  onPressed: () => _respond(invite, false),
                  child: Text(loc.t('decline_invite')),
                ),
                // Un invito scaduto si può solo rifiutare: le regole negano
                // l'accettazione, mostrare il pulsante sarebbe promettere
                // qualcosa che verrebbe negato al tocco.
                if (!invite.isExpired)
                  FilledButton(
                    onPressed: () => _respond(invite, true),
                    child: Text(loc.t('accept_invite')),
                  ),
              ],
            ),
          )
          .toList(),
    );
  }
  Widget _buildOutgoingInvites(
    ImmersivoTokens t,
    ColorScheme scheme,
    Localization loc,
    String myUserId,
  ) {
    final invites = ref.watch(outgoingInvitesProvider).value ?? const <Invite>[];
    if (invites.isEmpty) return const SizedBox.shrink();
    return _buildSection(
      t,
      scheme,
      title: loc.t('outgoing_invites_title'),
      children: invites
          .map(
            (invite) => _InviteTile(
              title: invite.toDisplayName,
              subtitle: loc.t('invite_pending_msg'),
              actions: [
                TextButton(
                  onPressed: () => _cancelOutgoing(invite),
                  child: Text(loc.t('cancel_invite')),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
  Widget _buildConnections(
    ImmersivoTokens t,
    ColorScheme scheme,
    Localization loc,
    String myUserId,
  ) {
    final invites = ref.watch(acceptedRelationshipsProvider).value ?? const <Invite>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.t('your_friends_list').toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.md),
        if (invites.isEmpty)
          Center(
            child: Text(
              loc.t('no_friends_msg'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invites.length,
            separatorBuilder: (_, _) => SizedBox(height: t.spacing.sm),
            itemBuilder: (context, index) {
              final invite = invites[index];
              final isFromMe = invite.fromUserId == myUserId;
              final otherId = isFromMe ? invite.toUserId : invite.fromUserId;
              final otherName = isFromMe ? invite.toDisplayName : invite.fromDisplayName;
              return DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FriendDetailScreen(
                        connectionId: otherId,
                        displayName: otherName,
                        since: invite.respondedAt ?? invite.createdAt,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(t.spacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.surfaceContainer,
                          child: Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : '?'),
                        ),
                        SizedBox(width: t.spacing.md),
                        Expanded(
                          child: Text(
                            otherName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.link_off, color: scheme.onSurfaceVariant),
                          onPressed: () => _dissolve(invite, otherName),
                        ),
                        Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  Widget _buildSection(
    ImmersivoTokens t,
    ColorScheme scheme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: t.spacing.md),
        ...children,
      ],
    );
  }
}
class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.title,
    required this.subtitle,
    required this.actions,
  });
  final String title;
  final String subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: t.spacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
        child: Padding(
          padding: EdgeInsets.all(t.spacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
