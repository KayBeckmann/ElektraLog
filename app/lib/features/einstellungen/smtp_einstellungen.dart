import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/versand_api.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../shared/email.dart';
import '../../shared/theme/app_colors.dart';

/// SMTP-Zugang der Firma für den Protokollversand (Roadmap 20.11.2026).
/// Nur im Company-Modus und nur für den Firmenadmin bedienbar — der Server
/// setzt das zusätzlich durch. Das Passwort wird nie zurückgelesen: leer
/// lassen behält das gespeicherte.
class SmtpEinstellungen extends ConsumerWidget {
  const SmtpEinstellungen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompany = ref.watch(appModusProvider).valueOrNull == AppModus.company;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    final Widget inhalt;
    if (!isCompany) {
      inhalt = const _Hinweis('Protokollversand per E-Mail gibt es nur mit Firmenkonto. '
          'Im Solo-Modus Protokolle über „PDF teilen“ weitergeben.');
    } else if (!isAdmin) {
      inhalt = const _Hinweis('Den SMTP-Zugang für den Protokollversand richtet der Firmenadmin ein.');
    } else {
      inhalt = const _SmtpFormular();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: inhalt,
    );
  }
}

class _Hinweis extends StatelessWidget {
  const _Hinweis(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
      );
}

const _tlsModi = {
  'starttls': 'STARTTLS (meist Port 587)',
  'ssl': 'SSL/TLS (meist Port 465)',
  'keine': 'Unverschlüsselt (nur internes Netz)',
};

class _SmtpFormular extends ConsumerStatefulWidget {
  const _SmtpFormular();

  @override
  ConsumerState<_SmtpFormular> createState() => _SmtpFormularState();
}

class _SmtpFormularState extends ConsumerState<_SmtpFormular> {
  VersandApi get _api => ref.read(versandApiProvider);

  final _formKey = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '587');
  final _absender = TextEditingController();
  final _absenderName = TextEditingController();
  final _benutzer = TextEditingController();
  final _passwort = TextEditingController();
  String _tls = 'starttls';
  bool _konfiguriert = false;
  bool _passwortGesetzt = false;
  bool _laedt = true;
  bool _arbeitet = false;
  String? _ladeFehler;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  @override
  void dispose() {
    for (final c in [_host, _port, _absender, _absenderName, _benutzer, _passwort]) {
      c.dispose();
    }
    super.dispose();
  }

  void _uebernehmen(Map<String, dynamic> d) {
    _konfiguriert = d['konfiguriert'] == true;
    _passwortGesetzt = d['passwortGesetzt'] == true;
    if (!_konfiguriert) return;
    _host.text = d['host'] as String? ?? '';
    _port.text = '${d['port'] ?? 587}';
    _tls = d['tlsModus'] as String? ?? 'starttls';
    _absender.text = d['absenderEmail'] as String? ?? '';
    _absenderName.text = d['absenderName'] as String? ?? '';
    _benutzer.text = d['benutzer'] as String? ?? '';
  }

  Future<void> _laden() async {
    try {
      final d = await _api.getSmtp();
      if (!mounted) return;
      setState(() {
        _uebernehmen(d);
        _laedt = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _ladeFehler = '$e';
          _laedt = false;
        });
      }
    }
  }

  void _meldung(String text, {bool fehler = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: fehler ? AppColors.error : null,
    ));
  }

  Future<void> _arbeiten(Future<void> Function() aufgabe) async {
    setState(() => _arbeitet = true);
    try {
      await aufgabe();
    } catch (e) {
      if (mounted) _meldung('$e', fehler: true);
    } finally {
      if (mounted) setState(() => _arbeitet = false);
    }
  }

  String? _leer(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    await _arbeiten(() async {
      final d = await _api.putSmtp(
        host: _host.text.trim(),
        port: int.parse(_port.text.trim()),
        tlsModus: _tls,
        absenderEmail: _absender.text.trim(),
        absenderName: _leer(_absenderName),
        benutzer: _leer(_benutzer),
        // Leer = gespeichertes Passwort behalten.
        passwort: _leer(_passwort),
      );
      if (!mounted) return;
      setState(() {
        _uebernehmen(d);
        _passwort.clear();
      });
      _meldung('SMTP-Zugang gespeichert.');
    });
  }

  Future<void> _passwortEntfernen() => _arbeiten(() async {
        final d = await _api.putSmtp(
          host: _host.text.trim(),
          port: int.parse(_port.text.trim()),
          tlsModus: _tls,
          absenderEmail: _absender.text.trim(),
          absenderName: _leer(_absenderName),
          benutzer: _leer(_benutzer),
          passwort: '',
        );
        if (mounted) setState(() => _uebernehmen(d));
      });

  Future<void> _entfernen() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SMTP-Zugang entfernen?'),
        content: const Text('Danach können keine Protokolle mehr per E-Mail versendet werden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Entfernen')),
        ],
      ),
    );
    if (ok != true) return;
    await _arbeiten(() async {
      await _api.deleteSmtp();
      if (!mounted) return;
      setState(() {
        _konfiguriert = false;
        _passwortGesetzt = false;
        for (final c in [_host, _absender, _absenderName, _benutzer, _passwort]) {
          c.clear();
        }
        _port.text = '587';
        _tls = 'starttls';
      });
    });
  }

  Future<void> _testen() async {
    final an = await showDialog<String>(context: context, builder: (_) => const _TestEmpfaengerDialog());
    if (an == null) return;
    await _arbeiten(() async {
      await _api.testSmtp(an);
      if (mounted) _meldung('Testnachricht an $an gesendet.');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_laedt) return const Center(child: CircularProgressIndicator());
    if (_ladeFehler != null) return _Hinweis('SMTP-Einstellungen nicht ladbar: $_ladeFehler');
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _konfiguriert
                ? 'Protokolle werden über diesen Zugang vom Server versendet.'
                : 'Noch kein SMTP-Zugang eingerichtet — Protokolle lassen sich erst danach per E-Mail versenden.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('smtp-host'),
            controller: _host,
            decoration: const InputDecoration(labelText: 'SMTP-Server *', hintText: 'smtp.example.de'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'SMTP-Server fehlt' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // Neuer Key bei geändertem Modus (z. B. nach „Entfernen“), weil
            // initialValue nur beim Aufbau gelesen wird.
            key: ValueKey('smtp-tls-$_tls'),
            initialValue: _tls,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Verschlüsselung'),
            items: [
              for (final e in _tlsModi.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() {
              final vorher = _tls;
              _tls = v!;
              // Standardport mitziehen, wenn noch der des alten Modus drinsteht.
              if (_port.text == (vorher == 'ssl' ? '465' : '587')) _port.text = _tls == 'ssl' ? '465' : '587';
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('smtp-port'),
            controller: _port,
            decoration: const InputDecoration(labelText: 'Port *'),
            keyboardType: TextInputType.number,
            validator: (v) {
              final p = int.tryParse((v ?? '').trim());
              return p == null || p < 1 || p > 65535 ? 'Port 1–65535' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('smtp-absender'),
            controller: _absender,
            decoration: const InputDecoration(labelText: 'Absender-E-Mail *', hintText: 'protokolle@firma.de'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => emailGueltig((v ?? '').trim()) ? null : 'Keine gültige E-Mail-Adresse',
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('smtp-absender-name'),
            controller: _absenderName,
            decoration: const InputDecoration(labelText: 'Absendername', hintText: 'Firmenname'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('smtp-benutzer'),
            controller: _benutzer,
            decoration: const InputDecoration(labelText: 'Benutzername', hintText: 'meist die Absender-E-Mail'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('smtp-passwort'),
            controller: _passwort,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Passwort',
              helperText: _passwortGesetzt
                  ? 'Gespeichert — leer lassen, um es zu behalten'
                  : 'Kein Passwort gespeichert',
            ),
          ),
          if (_passwortGesetzt)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('smtp-passwort-entfernen'),
                onPressed: _arbeitet ? null : _passwortEntfernen,
                child: const Text('Gespeichertes Passwort entfernen'),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('smtp-speichern'),
                onPressed: _arbeitet ? null : _speichern,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('SMTP speichern'),
              ),
              if (_konfiguriert) ...[
                OutlinedButton.icon(
                  key: const Key('smtp-testen'),
                  onPressed: _arbeitet ? null : _testen,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Testnachricht'),
                ),
                TextButton(
                  key: const Key('smtp-entfernen'),
                  onPressed: _arbeitet ? null : _entfernen,
                  child: const Text('Entfernen'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TestEmpfaengerDialog extends StatefulWidget {
  const _TestEmpfaengerDialog();

  @override
  State<_TestEmpfaengerDialog> createState() => _TestEmpfaengerDialogState();
}

class _TestEmpfaengerDialogState extends State<_TestEmpfaengerDialog> {
  final _ctrl = TextEditingController();
  String? _fehler;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ok() {
    final t = _ctrl.text.trim();
    if (!emailGueltig(t)) {
      setState(() => _fehler = 'Keine gültige E-Mail-Adresse');
      return;
    }
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Testnachricht senden'),
        content: TextField(
          key: const Key('smtp-test-empfaenger'),
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: 'An', errorText: _fehler),
          onSubmitted: (_) => _ok(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(onPressed: _ok, child: const Text('Senden')),
        ],
      );
}
