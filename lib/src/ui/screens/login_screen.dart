import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/ui/screens/register_screen.dart'; // Will create next
const double _kTitleFontSize = 34;
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await AuthService().signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Navigation is handled by AuthWrapper usually, or we pop
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
  Future<void> _resetPassword() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>(); // Local key for the dialog form
    final t = context.immersivo;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.read(localizationNotifierProvider).t('reset_password')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ref.read(localizationNotifierProvider).t('reset_password_hint'),
              ),
              SizedBox(height: t.spacing.md),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                labelText: ref.read(localizationNotifierProvider).t('email_label'),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : ref.read(localizationNotifierProvider).t('invalid_email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.read(localizationNotifierProvider).t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await AuthService().sendPasswordResetEmail(
                    emailController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ref.read(localizationNotifierProvider).t('password_reset_sent')),
                        backgroundColor: AppPalette.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${ref.read(localizationNotifierProvider).t('error_prefix')}: ${e.toString()}'),
                        backgroundColor: AppPalette.danger,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(ref.read(localizationNotifierProvider).t('send_btn')),
          ),
        ],
      ),
    );
    emailController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // `watch` e non `read`: `read` non crea un'iscrizione, quindi cambiando
    // lingua questa schermata resterebbe quella di prima finche qualcos'altro
    // non la ricostruisce. E lo stesso difetto trovato in US-093 sul cronometro.
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(t.spacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.t('login_welcome_back').toUpperCase(),
                  style: t.typography.headline?.copyWith(
                    fontSize: _kTitleFontSize,
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: t.spacing.xxl),
                _AuthField(
                  controller: _emailController,
                  label: loc.t('email_label'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : loc.t('invalid_email'),
                ),
                SizedBox(height: t.spacing.md),
                _AuthField(
                  controller: _passwordController,
                  label: loc.t('password_label'),
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) => value != null && value.length >= 6
                      ? null
                      : loc.t('password_too_short'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(loc.t('forgot_password')),
                  ),
                ),
                SizedBox(height: t.spacing.xl),
                InkWell(
                  onTap: _isLoading ? null : _login,
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
                            loc.t('login_btn').toUpperCase(),
                            style: t.typography.title?.copyWith(color: scheme.onPrimary),
                          ),
                  ),
                ),
                SizedBox(height: t.spacing.md),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(loc.t('no_account_signup')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/// Un campo email/password: bordo sottile e accento a sinistra, lo stesso
/// linguaggio dei campi editabili altrove — non il default Material di
/// prima.
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
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
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
