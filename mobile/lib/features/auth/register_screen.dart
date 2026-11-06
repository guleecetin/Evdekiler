import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import 'auth_controller.dart';
import 'widgets/app_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            displayName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Başarılı olursa router otomatik olarak ana sayfaya geçer
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(size: 88, showName: false),
                  const SizedBox(height: 32),

                  Text(
                    'Aramıza hoş geldin 🎉',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bir dakikada hesabını oluştur, buzdolabın hep cebinde olsun.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Adın',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return 'Adını gir';
                      if (name.length > 100) return 'En fazla 100 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Geçerli bir e-posta gir'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      helperText: 'En az 8 karakter',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 8)
                        ? 'Şifre en az 8 karakter olmalı'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Şifre tekrar',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? 'Şifreler eşleşmiyor'
                        : null,
                  ),
                  const SizedBox(height: 28),

                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colors.primary,
                            ),
                          )
                        : const Text('Hesabımı oluştur'),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zaten hesabın var mı?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Giriş yap'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
