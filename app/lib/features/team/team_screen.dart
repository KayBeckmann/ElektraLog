import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_service.dart';
import '../../shared/theme/app_colors.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _teamProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ApiService.getTeamBenutzer();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(_teamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: const Text('Mitarbeiter'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_teamProvider),
        ),
        data: (users) => _TeamList(
          users: users,
          onRefresh: () => ref.invalidate(_teamProvider),
          onEdit: (user) => _showEditDialog(context, ref, user),
          onToggleStatus: (user) => _toggleStatus(context, ref, user),
          onToggleAdmin: (user) => _toggleAdmin(context, ref, user),
          onDelete: (user) => _confirmDelete(context, ref, user),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) async {
    final istAktiv = user['status'] == 'aktiv';
    try {
      final result = await ApiService.updateTeamBenutzerStatus(
        user['id'] as String,
        istAktiv ? 'gesperrt' : 'aktiv',
      );
      if (result.containsKey('error') && context.mounted) {
        _showError(context, result['error'] as String);
      } else {
        ref.invalidate(_teamProvider);
      }
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> _toggleAdmin(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) async {
    final istAdmin = user['istAdmin'] as bool? ?? false;
    final name = user['name'] as String;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(istAdmin ? 'Admin-Rechte entziehen' : 'Admin-Rechte vergeben'),
        content: Text(
          istAdmin
              ? '$name verliert die Admin-Rechte und kann die Teamverwaltung nicht mehr nutzen.'
              : '$name erhält Admin-Rechte und kann das Team verwalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(istAdmin ? 'Entziehen' : 'Vergeben'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await ApiService.updateTeamBenutzerRolle(
        user['id'] as String,
        !istAdmin,
      );
      if (result.containsKey('error') && context.mounted) {
        _showError(context, result['error'] as String);
      } else {
        ref.invalidate(_teamProvider);
      }
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mitarbeiter entfernen'),
        content: Text(
          '${user['name']} (${user['email']}) wirklich löschen?\n\n'
          'Dieser Vorgang kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ApiService.deleteTeamBenutzer(user['id'] as String);
      ref.invalidate(_teamProvider);
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // ── Dialoge ────────────────────────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Mitarbeiter anlegen'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Field(ctrl: nameCtrl, label: 'Name', icon: Icons.person_outline, cap: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name eingeben' : null),
                  const SizedBox(height: 12),
                  _Field(ctrl: emailCtrl, label: 'E-Mail', icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Gültige E-Mail eingeben' : null),
                  const SizedBox(height: 12),
                  _PasswordField(
                    ctrl: passCtrl, obscure: obscure,
                    onToggle: () => setState(() => obscure = !obscure),
                    validator: (v) => (v == null || v.length < 6) ? 'Mindestens 6 Zeichen' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: loading ? null : () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => loading = true);
                try {
                  final result = await ApiService.createTeamBenutzer(
                    email: emailCtrl.text.trim(),
                    passwort: passCtrl.text,
                    name: nameCtrl.text.trim(),
                  );
                  if (result.containsKey('error')) {
                    if (ctx.mounted) _showError(ctx, result['error'] as String);
                  } else {
                    ref.invalidate(_teamProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) _showError(ctx, e.toString());
                } finally {
                  if (ctx.mounted) setState(() => loading = false);
                }
              },
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) async {
    final nameCtrl = TextEditingController(text: user['name'] as String? ?? '');
    final emailCtrl = TextEditingController(text: user['email'] as String? ?? '');
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Mitarbeiter bearbeiten'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Field(ctrl: nameCtrl, label: 'Name', icon: Icons.person_outline, cap: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name eingeben' : null),
                  const SizedBox(height: 12),
                  _Field(ctrl: emailCtrl, label: 'E-Mail', icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Gültige E-Mail eingeben' : null),
                  const SizedBox(height: 12),
                  _PasswordField(
                    ctrl: passCtrl, obscure: obscure,
                    labelText: 'Neues Passwort (optional)',
                    onToggle: () => setState(() => obscure = !obscure),
                    validator: (v) => (v != null && v.isNotEmpty && v.length < 6) ? 'Mindestens 6 Zeichen' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: loading ? null : () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => loading = true);
                try {
                  final result = await ApiService.updateTeamBenutzer(
                    user['id'] as String,
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    passwort: passCtrl.text.isNotEmpty ? passCtrl.text : null,
                  );
                  if (result.containsKey('error')) {
                    if (ctx.mounted) _showError(ctx, result['error'] as String);
                  } else {
                    ref.invalidate(_teamProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) _showError(ctx, e.toString());
                } finally {
                  if (ctx.mounted) setState(() => loading = false);
                }
              },
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
  }

  void _showError(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }
}

// ── Team-Liste ─────────────────────────────────────────────────────────────────

class _TeamList extends StatelessWidget {
  const _TeamList({
    required this.users,
    required this.onRefresh,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onToggleAdmin,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> users;
  final VoidCallback onRefresh;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onToggleStatus;
  final void Function(Map<String, dynamic>) onToggleAdmin;
  final void Function(Map<String, dynamic>) onDelete;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEAM',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.08 * 12,
                          )),
                  const SizedBox(height: 2),
                  Text('Mitarbeiterverwaltung',
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('${users.length} Mitarbeiter',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          )),
                ],
              ),
            ),
          ),
          if (users.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Noch keine Mitarbeiter.\nLege den ersten an!',
                    textAlign: TextAlign.center),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = users[index];
                    return _UserTile(
                      user: user,
                      onEdit: () => onEdit(user),
                      onToggleStatus: () => onToggleStatus(user),
                      onToggleAdmin: () => onToggleAdmin(user),
                      onDelete: () => onDelete(user),
                    );
                  },
                  childCount: users.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── User-Kachel ────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onToggleAdmin,
    required this.onDelete,
  });

  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onToggleAdmin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final istAktiv = user['status'] == 'aktiv';
    final istAdmin = user['istAdmin'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: istAktiv
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerHigh,
          child: Text(
            (user['name'] as String? ?? '?').isNotEmpty
                ? (user['name'] as String)[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: istAktiv
                  ? AppColors.onSecondaryContainer
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user['name'] as String? ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: istAktiv ? null : AppColors.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (istAdmin) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Admin',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          user['email'] as String? ?? '',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status-Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: istAktiv
                    ? AppColors.secondaryContainer
                    : AppColors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                istAktiv ? 'aktiv' : 'gesperrt',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: istAktiv
                          ? AppColors.onSecondaryContainer
                          : AppColors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.onSurfaceVariant),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'toggle') onToggleStatus();
                if (v == 'admin') onToggleAdmin();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Bearbeiten'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'admin',
                  child: Row(children: [
                    Icon(
                      istAdmin ? Icons.manage_accounts : Icons.admin_panel_settings_outlined,
                      size: 18,
                      color: istAdmin ? AppColors.error : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      istAdmin ? 'Admin-Rechte entziehen' : 'Admin-Rechte vergeben',
                      style: TextStyle(
                        color: istAdmin ? AppColors.error : null,
                      ),
                    ),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      istAktiv ? Icons.block_outlined : Icons.check_circle_outline,
                      size: 18,
                      color: istAktiv ? AppColors.onSurfaceVariant : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(istAktiv ? 'Sperren' : 'Entsperren'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Text('Löschen', style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hilfs-Widgets ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.cap = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization cap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
        ),
        keyboardType: keyboardType,
        textCapitalization: cap,
        validator: validator,
      );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.ctrl,
    required this.obscure,
    required this.onToggle,
    this.labelText = 'Passwort',
    this.validator,
  });

  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;
  final String labelText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: const Icon(Icons.lock_outline, size: 18),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
            ),
            onPressed: onToggle,
          ),
        ),
        obscureText: obscure,
        validator: validator,
      );
}

// ── Fehler-Ansicht ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Fehler beim Laden',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
}
