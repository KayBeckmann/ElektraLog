import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../shared/theme/app_colors.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Login fields
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;

  // Register fields
  final _registerFormKey = GlobalKey<FormState>();
  final _registerEmailCtrl = TextEditingController();
  final _registerPassCtrl = TextEditingController();
  final _registerNameCtrl = TextEditingController();
  final _registerFirmaCtrl = TextEditingController();
  bool _registerObscure = true;
  bool _registerLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _registerEmailCtrl.dispose();
    _registerPassCtrl.dispose();
    _registerNameCtrl.dispose();
    _registerFirmaCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);
    try {
      final result = await ApiService.login(
        _loginEmailCtrl.text.trim(),
        _loginPassCtrl.text,
      );
      if (result.containsKey('error')) {
        _showError(result['error'] as String);
      } else {
        await ref.read(appModusProvider.notifier).setCompany(
              result['token'] as String,
              result['benutzerId'] as String,
              result['firmaId'] as String,
              result['name'] as String,
            );
        _showSuccess('Willkommen, ${result['name']}!');
        if (mounted) context.go('/');
      }
    } catch (e) {
      _showError('Verbindungsfehler: $e');
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _doRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _registerLoading = true);
    try {
      final result = await ApiService.register(
        _registerEmailCtrl.text.trim(),
        _registerPassCtrl.text,
        _registerNameCtrl.text.trim(),
        _registerFirmaCtrl.text.trim(),
      );
      if (result.containsKey('error')) {
        _showError(result['error'] as String);
      } else {
        await ref.read(appModusProvider.notifier).setCompany(
              result['token'] as String,
              result['benutzerId'] as String,
              result['firmaId'] as String,
              result['name'] as String,
            );
        _showSuccess('Konto erstellt! Willkommen, ${result['name']}!');
        if (mounted) context.go('/');
      }
    } catch (e) {
      _showError('Verbindungsfehler: $e');
    } finally {
      if (mounted) setState(() => _registerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Zurück',
        ),
        title: const Text('Konto'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Anmelden'),
            Tab(text: 'Registrieren'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.electric_bolt,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ElektraLog',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Company-Modus — synchronisierte Datenverwaltung',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Tab bar embedded in card
                    SizedBox(
                      height: 48,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.onSurfaceVariant,
                        indicatorColor: AppColors.primary,
                        tabs: const [
                          Tab(text: 'Anmelden'),
                          Tab(text: 'Registrieren'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab views
                    SizedBox(
                      height: 280,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _LoginForm(
                            formKey: _loginFormKey,
                            emailCtrl: _loginEmailCtrl,
                            passCtrl: _loginPassCtrl,
                            obscure: _loginObscure,
                            loading: _loginLoading,
                            onToggleObscure: () =>
                                setState(() => _loginObscure = !_loginObscure),
                            onSubmit: _doLogin,
                          ),
                          _RegisterForm(
                            formKey: _registerFormKey,
                            emailCtrl: _registerEmailCtrl,
                            passCtrl: _registerPassCtrl,
                            nameCtrl: _registerNameCtrl,
                            firmaCtrl: _registerFirmaCtrl,
                            obscure: _registerObscure,
                            loading: _registerLoading,
                            onToggleObscure: () => setState(
                                () => _registerObscure = !_registerObscure),
                            onSubmit: _doRegister,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Solo mode button
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Solo bleiben (ohne Konto)'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login form
// ─────────────────────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: emailCtrl,
            decoration: const InputDecoration(
              labelText: 'E-Mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Gültige E-Mail eingeben' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passCtrl,
            decoration: InputDecoration(
              labelText: 'Passwort',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleObscure,
              ),
            ),
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mindestens 6 Zeichen' : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Anmelden'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register form
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.nameCtrl,
    required this.firmaCtrl,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController firmaCtrl;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name eingeben' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: firmaCtrl,
              decoration: const InputDecoration(
                labelText: 'Firmenname',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Firmenname eingeben'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Gültige E-Mail eingeben'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passCtrl,
              decoration: InputDecoration(
                labelText: 'Passwort',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon:
                      Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleObscure,
                ),
              ),
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mindestens 6 Zeichen' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Konto erstellen'),
            ),
          ],
        ),
      ),
    );
  }
}
