import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';
const double _kTitleFontSize = 28;
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.athlete;
  bool _isLoading = false;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await AuthService().register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
          role: _selectedRole,
        );
        if (mounted) {
          Navigator.pop(
            context,
          ); // Go back to login or let AuthWrapper handle it
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${ref.read(localizationNotifierProvider).t('error_prefix')}: ${e.toString()}')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('login_btn')),
                  SizedBox(width: t.spacing.md),
                  Text(
                    loc.t('create_account').toUpperCase(),
                    style: t.typography.headline?.copyWith(
                      fontSize: _kTitleFontSize,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(t.spacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.t('join_gymflow').toUpperCase(),
                  style: t.typography.headline?.copyWith(
                    fontSize: _kTitleFontSize + 6,
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: t.spacing.xxl),
                _RegField(
                  controller: _nameController,
                  label: loc.t('full_name'),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : loc.t('name_required'),
                ),
                SizedBox(height: t.spacing.md),
                _RegField(
                  controller: _emailController,
                  label: loc.t('email_label'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : loc.t('invalid_email'),
                ),
                SizedBox(height: t.spacing.md),
                _RegField(
                  controller: _passwordController,
                  label: loc.t('password_label'),
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 6
                      ? null
                      : loc.t('password_too_short_min6'),
                ),
                SizedBox(height: t.spacing.md),
                Text(
                  loc.t('role_label').toUpperCase(),
                  style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: t.spacing.sm),
                Row(
                  children: [
                    for (final role in UserRole.values)
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = role),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                            margin: EdgeInsets.only(
                              right: role != UserRole.values.last ? t.spacing.xs : 0,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: role == _selectedRole ? scheme.primary : null,
                              border: Border.all(color: scheme.outline),
                            ),
                            child: Text(
                              loc.t(switch (role) {
                                UserRole.athlete => 'role_athlete',
                                UserRole.trainer => 'role_trainer',
                                UserRole.both => 'role_both',
                              }).toUpperCase(),
                              textAlign: TextAlign.center,
                              style: t.typography.eyebrow?.copyWith(
                                color: role == _selectedRole
                                    ? scheme.onPrimary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: t.spacing.xl),
                InkWell(
                  onTap: _isLoading ? null : _register,
                  child: Container(
                    height: t.sizing.minTouchTarget,
                    color: scheme.primary,
                    alignment: Alignment.center,
                    child: _isLoading
                        ? SizedBox(
                            width: t.sizing.iconMd,
                            height: t.sizing.iconMd,
                            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                          )
                        : Text(
                            loc.t('signup_btn').toUpperCase(),
                            style: t.typography.title?.copyWith(color: scheme.onPrimary),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// Un campo del modulo di registrazione: bordo sottile e accento a sinistra,
/// lo stesso linguaggio dei campi editabili altrove — non il default
/// Material di prima.
class _RegField extends StatelessWidget {
  const _RegField({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(left: BorderSide(color: scheme.outline, width: 3)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(t.spacing.md),
          labelText: label,
        ),
      ),
    );
  }
}
