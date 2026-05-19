import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/einstellungen_provider.dart';
import '../../shared/theme/app_colors.dart';

class EinstellungenScreen extends ConsumerStatefulWidget {
  const EinstellungenScreen({super.key});

  @override
  ConsumerState<EinstellungenScreen> createState() =>
      _EinstellungenScreenState();
}

class _EinstellungenScreenState extends ConsumerState<EinstellungenScreen> {
  final _prueferCtrl = TextEditingController();
  final _firmaCtrl = TextEditingController();
  final _pruefgeraetCtrl = TextEditingController();

  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_prefilled) return;
      final einstellungen = ref.read(einstellungenProvider).valueOrNull;
      if (einstellungen == null) return;
      _prueferCtrl.text = einstellungen.prueferName ?? '';
      _firmaCtrl.text = einstellungen.firma ?? '';
      _pruefgeraetCtrl.text = einstellungen.pruefgeraet ?? '';
      _prefilled = true;
    });
  }

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _firmaCtrl.dispose();
    _pruefgeraetCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    await ref.read(einstellungenProvider.notifier).save(
          _prueferCtrl.text.trim(),
          _firmaCtrl.text.trim(),
          _pruefgeraetCtrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einstellungen gespeichert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: const Text('Einstellungen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('PRÜFER'),
            const SizedBox(height: 8),
            TextField(
              controller: _prueferCtrl,
              decoration: const InputDecoration(
                labelText: 'Name des Prüfers',
                hintText: 'Max Mustermann',
                prefixIcon: Icon(Icons.person_outline, size: 18),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _SectionLabel('UNTERNEHMEN'),
            const SizedBox(height: 8),
            TextField(
              controller: _firmaCtrl,
              decoration: const InputDecoration(
                labelText: 'Firma / Unternehmen',
                hintText: 'Elektro Mustermann GmbH',
                prefixIcon: Icon(Icons.business_outlined, size: 18),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _SectionLabel('PRÜFGERÄT'),
            const SizedBox(height: 8),
            TextField(
              controller: _pruefgeraetCtrl,
              decoration: const InputDecoration(
                labelText: 'Prüfgerät',
                hintText: 'z.B. Metrel MI 3152 / Fluke 1664 FC',
                prefixIcon: Icon(Icons.device_hub_outlined, size: 18),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onSave,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Einstellungen speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      );
}
