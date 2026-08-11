import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/services/auth_service.dart';

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
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('create_account'))),
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
                  loc.t('join_gymflow'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: t.spacing.xxl),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                        labelText: loc.t('full_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : loc.t('name_required'),
                ),
                SizedBox(height: t.spacing.md),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                        labelText: loc.t('email_label'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : loc.t('invalid_email'),
                ),
                SizedBox(height: t.spacing.md),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                        labelText: loc.t('password_label'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 6
                      ? null
                      : loc.t('password_too_short_min6'),
                ),
                SizedBox(height: t.spacing.xl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? CircularProgressIndicator(color: scheme.onPrimary)
                      : Text(loc.t('signup_btn')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

