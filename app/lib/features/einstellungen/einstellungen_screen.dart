import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/einstellungen_provider.dart';
import '../../core/router.dart';
import '../../shared/theme/app_colors.dart';

class EinstellungenScreen extends ConsumerStatefulWidget {
  const EinstellungenScreen({super.key});

  @override
  ConsumerState<EinstellungenScreen> createState() =>
      _EinstellungenScreenState();
}

class _EinstellungenScreenState extends ConsumerState<EinstellungenScreen> {
  final _prueferCtrl      = TextEditingController();
  final _firmaCtrl        = TextEditingController();
  final _strasseCtrl      = TextEditingController();
  final _plzCtrl          = TextEditingController();
  final _ortCtrl          = TextEditingController();
  final _pruefgeraetCtrl  = TextEditingController();
  final _serverUrlCtrl    = TextEditingController();
  final _altesPasswortCtrl = TextEditingController();
  final _neuesPasswortCtrl = TextEditingController();

  bool _prefilled        = false;
  bool _savingPasswort   = false;
  bool _showAltesPasswort = false;
  bool _showNeuesPasswort = false;

  void _fillControllers(Einstellungen e) {
    _prueferCtrl.text     = e.prueferName   ?? '';
    _firmaCtrl.text       = e.firma         ?? '';
    _strasseCtrl.text     = e.firmaStrasse  ?? '';
    _plzCtrl.text         = e.firmaPlz      ?? '';
    _ortCtrl.text         = e.firmaOrt      ?? '';
    _pruefgeraetCtrl.text = e.pruefgeraet   ?? '';
    _serverUrlCtrl.text   = e.serverUrl     ?? '';
    _prefilled = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_prefilled) return;
      final e = ref.read(einstellungenProvider).valueOrNull;
      if (e != null) _fillControllers(e);
    });
  }

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _firmaCtrl.dispose();
    _strasseCtrl.dispose();
    _plzCtrl.dispose();
    _ortCtrl.dispose();
    _pruefgeraetCtrl.dispose();
    _serverUrlCtrl.dispose();
    _altesPasswortCtrl.dispose();
    _neuesPasswortCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    await ref.read(einstellungenProvider.notifier).save(
      prueferName:   _prueferCtrl.text.trim(),
      firma:         _firmaCtrl.text.trim(),
      firmaStrasse:  _strasseCtrl.text.trim(),
      firmaPlz:      _plzCtrl.text.trim(),
      firmaOrt:      _ortCtrl.text.trim(),
      pruefgeraet:   _pruefgeraetCtrl.text.trim(),
      serverUrl:     _serverUrlCtrl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einstellungen gespeichert')),
      );
    }
  }

  Future<void> _onChangePassword() async {
    final altes = _altesPasswortCtrl.text.trim();
    final neues = _neuesPasswortCtrl.text.trim();
    if (altes.isEmpty || neues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte beide Felder ausfüllen')),
      );
      return;
    }
    setState(() => _savingPasswort = true);
    try {
      await ApiService.changeOwnPassword(
        altesPasswort: altes,
        neuesPasswort: neues,
      );
      _altesPasswortCtrl.clear();
      _neuesPasswortCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kennwort erfolgreich geändert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPasswort = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Felder nachfüllen wenn der Provider nach dem Login neu geladen wurde
    ref.listen(einstellungenProvider, (_, next) {
      final e = next.valueOrNull;
      if (e != null && !_prefilled) _fillControllers(e);
    });

    final modusAsync = ref.watch(appModusProvider);
    final isCompany = modusAsync.valueOrNull == AppModus.company;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ──────────────────────────────────────────────
            Text(
              'EINSTELLUNGEN',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.08 * 12,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Konfiguration',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 32),

            // ── Prüfer ───────────────────────────────────────────────────
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

            // ── Unternehmen ──────────────────────────────────────────────
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
            const SizedBox(height: 10),
            TextField(
              controller: _strasseCtrl,
              decoration: const InputDecoration(
                labelText: 'Straße und Hausnummer',
                hintText: 'Musterstraße 1',
                prefixIcon: Icon(Icons.home_outlined, size: 18),
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
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _plzCtrl,
                    decoration: const InputDecoration(
                      labelText: 'PLZ',
                      hintText: '12345',
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.outlineVariant),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ort',
                      hintText: 'Musterstadt',
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.outlineVariant),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Prüfgerät ────────────────────────────────────────────────
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
            const SizedBox(height: 16),

            // ── Server ───────────────────────────────────────────────────
            _SectionLabel('SERVER'),
            const SizedBox(height: 8),
            TextField(
              controller: _serverUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend-URL',
                hintText: 'https://meinserver.de:8080',
                helperText: 'Leer lassen für Standardwert (Web-App: automatisch)',
                prefixIcon: Icon(Icons.cloud_outlined, size: 18),
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
              keyboardType: TextInputType.url,
              autocorrect: false,
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

            const SizedBox(height: 40),
            const Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 24),

            // ── Konto ────────────────────────────────────────────────────
            _SectionLabel('KONTO'),
            const SizedBox(height: 12),

            if (isCompany) ...[
              // Company-Modus: Status-Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined,
                        size: 20, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company-Modus aktiv',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.secondary,
                                    ),
                          ),
                          Text(
                            'Daten werden synchronisiert',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Kennwort ändern ──────────────────────────────────────
              _SectionLabel('KENNWORT ÄNDERN'),
              const SizedBox(height: 8),
              TextField(
                controller: _altesPasswortCtrl,
                obscureText: !_showAltesPasswort,
                decoration: InputDecoration(
                  labelText: 'Aktuelles Kennwort',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showAltesPasswort
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setState(
                        () => _showAltesPasswort = !_showAltesPasswort),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _neuesPasswortCtrl,
                obscureText: !_showNeuesPasswort,
                decoration: InputDecoration(
                  labelText: 'Neues Kennwort (mind. 6 Zeichen)',
                  prefixIcon: const Icon(Icons.lock_reset_outlined, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNeuesPasswort
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setState(
                        () => _showNeuesPasswort = !_showNeuesPasswort),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savingPasswort ? null : _onChangePassword,
                  icon: _savingPasswort
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.key_outlined, size: 18),
                  label: const Text('Kennwort ändern'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Abmelden ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(appModusProvider.notifier).logout();
                    if (context.mounted) context.go('/');
                  },
                  icon: const Icon(Icons.logout_outlined, size: 18),
                  label: const Text('Abmelden'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              // Solo-Modus: Mit Konto verbinden
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outlined,
                        size: 20, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solo-Modus',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'Daten werden nur lokal gespeichert',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.auth),
                  icon: const Icon(Icons.cloud_outlined, size: 18),
                  label: const Text('Mit Konto verbinden'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
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
