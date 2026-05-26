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
          onToggleStatus: (user) => _toggleStatus(context, ref, user),
          onDelete: (user) => _confirmDelete(context, ref, user),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) async {
    final istAktiv = user['status'] == 'aktiv';
    final neuerStatus = istAktiv ? 'gesperrt' : 'aktiv';
    try {
      final result = await ApiService.updateTeamBenutzerStatus(
        user['id'] as String,
        neuerStatus,
      );
      if (result.containsKey('error')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] as String),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        ref.invalidate(_teamProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          'Soll ${user['name']} (${user['email']}) wirklich gelöscht werden?\n\n'
          'Alle Daten dieses Benutzers gehen verloren.',
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name eingeben' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Gültige E-Mail eingeben'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      prefixIcon:
                          const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => obscure = !obscure),
                      ),
                    ),
                    obscureText: obscure,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mindestens 6 Zeichen'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => loading = true);
                      try {
                        final result =
                            await ApiService.createTeamBenutzer(
                          email: emailCtrl.text.trim(),
                          passwort: passCtrl.text,
                          name: nameCtrl.text.trim(),
                        );
                        if (result.containsKey('error')) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(result['error'] as String),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } else {
                          ref.invalidate(_teamProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Fehler: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
}

// ── Team-Liste ─────────────────────────────────────────────────────────────────

class _TeamList extends StatelessWidget {
  const _TeamList({
    required this.users,
    required this.onRefresh,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> users;
  final VoidCallback onRefresh;
  final void Function(Map<String, dynamic>) onToggleStatus;
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
                  Text(
                    'TEAM',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.08 * 12,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mitarbeiterverwaltung',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${users.length} Mitarbeiter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (users.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Noch keine Mitarbeiter.\nLege den ersten an!',
                  textAlign: TextAlign.center,
                ),
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
                      onToggleStatus: () => onToggleStatus(user),
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

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final Map<String, dynamic> user;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final istAktiv = user['status'] == 'aktiv';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: istAktiv
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerHigh,
          child: Text(
            (user['name'] as String).isNotEmpty
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
        title: Text(
          user['name'] as String,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: istAktiv ? null : AppColors.onSurfaceVariant,
              ),
        ),
        subtitle: Text(
          user['email'] as String,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
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
            // Options menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.onSurfaceVariant),
              onSelected: (value) {
                if (value == 'toggle') onToggleStatus();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        istAktiv
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        size: 18,
                        color: istAktiv ? AppColors.error : AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(istAktiv ? 'Sperren' : 'Entsperren'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Löschen',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fehler-Ansicht ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
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
}
