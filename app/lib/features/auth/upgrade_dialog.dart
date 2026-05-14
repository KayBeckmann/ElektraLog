import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../core/sync/sync_service.dart';
import '../../core/database/isar_service.dart';
import '../../shared/theme/app_colors.dart';

/// Shows an upgrade dialog if the user has local data and just logged in.
/// Offers to upload local Sembast data to the backend.
Future<void> showUpgradeDialogIfNeeded(
  BuildContext context,
  WidgetRef ref,
  Database db,
) async {
  // Count local entries
  final snapshots = await StorageService.kundenStore.find(db);
  final count = snapshots.length;
  if (count == 0) return;

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _UpgradeDialog(count: count, db: db, ref: ref),
  );
}

class _UpgradeDialog extends ConsumerStatefulWidget {
  const _UpgradeDialog({
    required this.count,
    required this.db,
    required this.ref,
  });

  final int count;
  final Database db;
  final WidgetRef ref;

  @override
  ConsumerState<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends ConsumerState<_UpgradeDialog> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final synced = await SyncService.syncToBackend(widget.db);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$synced Einträge erfolgreich übertragen.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Übertragen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Lokale Daten übertragen'),
        ],
      ),
      content: Text(
        'Du hast ${widget.count} lokale Einträge.\n'
        'Möchtest du diese in dein Konto übertragen?',
      ),
      actions: [
        TextButton(
          onPressed:
              _syncing ? null : () => Navigator.of(context).pop(),
          child: const Text('Später'),
        ),
        TextButton(
          onPressed: _syncing
              ? null
              : () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lokale Daten behalten.'),
                    ),
                  );
                },
          child: const Text('Nein, leer starten'),
        ),
        FilledButton(
          onPressed: _syncing ? null : _sync,
          child: _syncing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ja, übertragen'),
        ),
      ],
    );
  }
}
