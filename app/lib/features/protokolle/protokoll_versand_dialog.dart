import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_service.dart';
import '../../core/api/versand_api.dart';
import '../../shared/email.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

Future<void> _pdfZeigen(Uint8List bytes, String dateiname) =>
    Printing.layoutPdf(onLayout: (_) async => bytes, name: dateiname);

enum _Empfaenger { standort, kunde, andere }

/// Versand eines archivierten Protokolls per E-Mail (Roadmap 20./21.11.2026).
///
/// Vorgeschlagen wird die E-Mail des Standorts, zu dem das Protokoll gehört.
/// Kunden-E-Mail oder eine andere Adresse nur nach bewusster Auswahl, nie
/// automatisch. Vor dem Senden bestätigt der Nutzer Empfänger und die
/// archivierte PDF-Fassung; der Server verschickt genau diese. Liefert
/// die Empfängeradresse nach erfolgreichem Versand, sonst `null`.
class ProtokollVersandDialog extends ConsumerStatefulWidget {
  const ProtokollVersandDialog({
    super.key,
    required this.protokollId,
    required this.titel,
    this.pdfAnzeigen = _pdfZeigen,
    this.erwarteterPdfHash,
  });

  final String protokollId;
  final String titel;
  final Future<void> Function(Uint8List bytes, String dateiname) pdfAnzeigen;

  /// Prüfsumme des gerade erzeugten PDFs (Versand direkt aus der
  /// Erstellung): weicht die archivierte Fassung ab, bleibt Senden gesperrt.
  final String? erwarteterPdfHash;

  @override
  ConsumerState<ProtokollVersandDialog> createState() => _ProtokollVersandDialogState();
}

class _ProtokollVersandDialogState extends ConsumerState<ProtokollVersandDialog> {
  final _andereCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  Map<String, dynamic>? _info;
  String? _ladeFehler;
  _Empfaenger? _wahl;
  bool _sendet = false;
  bool _pdfLaedt = false;
  String? _fehler;

  /// Bleibt nach einem Verbindungsabbruch für dieselben Empfänger erhalten,
  /// damit „Erneut versuchen“ serverseitig nicht doppelt verschickt.
  String? _anfrageId;
  String? _anfrageFuer;

  VersandApi get _api => ref.read(versandApiProvider);

  Map<String, dynamic>? get _standort => _info?['standort'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _kunde => _info?['kunde'] as Map<String, dynamic>?;
  String? get _standortEmail => _standort?['kontaktEmail'] as String?;
  bool get _hashAbweichung =>
      widget.erwarteterPdfHash != null && _info?['pdfHash'] != widget.erwarteterPdfHash;

  String? get _kundeEmail {
    final e = _kunde?['kontaktEmail'] as String?;
    return e == null || e == _standortEmail ? null : e;
  }

  @override
  void initState() {
    super.initState();
    _laden();
  }

  @override
  void dispose() {
    _andereCtrl.dispose();
    _ccCtrl.dispose();
    super.dispose();
  }

  Future<void> _laden() async {
    try {
      final info = await _api.info(widget.protokollId);
      if (!mounted) return;
      setState(() {
        _info = info;
        _ladeFehler = null;
        // Nur die Standort-E-Mail wird vorgeschlagen.
        _wahl ??= _standortEmail != null ? _Empfaenger.standort : null;
      });
    } catch (e) {
      if (mounted) setState(() => _ladeFehler = '$e');
    }
  }

  String? get _empfaenger => switch (_wahl) {
        _Empfaenger.standort => _standortEmail,
        _Empfaenger.kunde => _kundeEmail,
        _Empfaenger.andere => _andereCtrl.text.trim(),
        null => null,
      };

  List<String> get _cc =>
      [for (final t in _ccCtrl.text.split(RegExp(r'[,;\s]+'))) if (t.trim().isNotEmpty) t.trim()];

  Future<void> _pdfAnsehen() async {
    setState(() => _pdfLaedt = true);
    try {
      final bytes = await _api.pdf(widget.protokollId);
      if (sha256.convert(bytes).toString() != _info!['pdfHash']) {
        throw StateError('Das geladene PDF entspricht nicht der archivierten Fassung.');
      }
      await widget.pdfAnzeigen(bytes, _info!['dateiname'] as String);
    } catch (e) {
      if (mounted) setState(() => _fehler = 'PDF nicht ladbar: $e');
    } finally {
      if (mounted) setState(() => _pdfLaedt = false);
    }
  }

  Future<void> _senden() async {
    final an = _empfaenger;
    final cc = _cc;
    if (an == null || !emailGueltig(an)) {
      setState(() => _fehler = 'Bitte einen Empfänger mit gültiger E-Mail-Adresse wählen.');
      return;
    }
    final falsch = cc.where((c) => !emailGueltig(c)).toList();
    if (falsch.isNotEmpty) {
      setState(() => _fehler = 'CC-Adresse ungültig: ${falsch.join(', ')}');
      return;
    }
    final hash = _info!['pdfHash'] as String;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Protokoll versenden?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('An: $an', key: const Key('versand-bestaetigen-an')),
            if (cc.isNotEmpty) Text('CC: ${cc.join(', ')}'),
            const SizedBox(height: 8),
            Text('Anhang: ${_info!['dateiname']}'),
            Text(
              'Archivierte Fassung, Prüfsumme ${hash.substring(0, 12)}…',
              style: AppTheme.dataMono(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(
            key: const Key('versand-bestaetigen'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Jetzt senden'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final signatur = '$an|${cc.join(',')}';
    if (_anfrageFuer != signatur) {
      _anfrageId = const Uuid().v4();
      _anfrageFuer = signatur;
    }
    setState(() {
      _sendet = true;
      _fehler = null;
    });
    try {
      await _api.senden(
        protokollId: widget.protokollId,
        anfrageId: _anfrageId!,
        empfaenger: an,
        cc: cc,
        pdfHash: hash,
      );
      if (mounted) Navigator.pop(context, an);
    } on ApiException catch (e) {
      // Antwort erhalten: endgültig gescheitert, nächster Versuch ist neu.
      _anfrageId = null;
      _anfrageFuer = null;
      if (!mounted) return;
      setState(() => _fehler = e.message);
      await _laden();
    } catch (e) {
      if (mounted) {
        setState(() => _fehler = 'Verbindung unterbrochen — ob die E-Mail raus ist, ist unklar. '
            '„Senden“ mit denselben Empfängern verschickt sie nicht doppelt.');
      }
    } finally {
      if (mounted) setState(() => _sendet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Protokoll per E-Mail', style: theme.textTheme.titleLarge),
      content: SizedBox(
        width: 520,
        child: _info == null
            ? (_ladeFehler == null
                ? const Center(heightFactor: 2, child: CircularProgressIndicator())
                : Text('Versanddaten nicht ladbar: $_ladeFehler', style: const TextStyle(color: AppColors.error)))
            : SingleChildScrollView(child: _inhalt(theme)),
      ),
      actions: [
        TextButton(onPressed: _sendet ? null : () => Navigator.pop(context), child: const Text('Schließen')),
        if (_info != null)
          FilledButton.icon(
            key: const Key('versand-senden'),
            onPressed: _sendet || _info!['smtpKonfiguriert'] != true || _wahl == null || _hashAbweichung
                ? null
                : _senden,
            icon: _sendet
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_outlined, size: 18),
            label: const Text('Senden …'),
          ),
      ],
    );
  }

  Widget _inhalt(ThemeData theme) {
    final klein = theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant);
    final standort = _standort;
    final verlauf = (_info!['verlauf'] as List).cast<Map<String, dynamic>>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titel, style: theme.textTheme.titleSmall),
        if (standort != null)
          Text('Standort: ${standort['bezeichnung']}', key: const Key('versand-standort'), style: klein),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(_info!['dateiname'] as String, style: klein, overflow: TextOverflow.ellipsis)),
            TextButton.icon(
              key: const Key('versand-pdf-ansehen'),
              onPressed: _pdfLaedt ? null : _pdfAnsehen,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('PDF ansehen'),
            ),
          ],
        ),
        if (_hashAbweichung)
          const _Hinweis(
            key: Key('versand-hash-abweichung'),
            text: 'Die archivierte Fassung entspricht nicht dem gerade erzeugten PDF — '
                'Versand gesperrt. Bitte das Protokoll in der Dokumentenablage prüfen.',
          ),
        if (_info!['smtpKonfiguriert'] != true)
          const _Hinweis(
            key: Key('versand-kein-smtp'),
            text: 'Für die Firma ist noch kein SMTP-Server eingerichtet. Der Firmenadmin '
                'trägt ihn unter Einstellungen → Protokollversand ein.',
          ),
        const Divider(height: 24),
        Text('Empfänger', style: theme.textTheme.titleSmall),
        if (standort == null)
          const _Hinweis(text: 'Diesem Protokoll ist kein Standort zugeordnet — bitte den Empfänger bewusst wählen.')
        else if (_standortEmail == null)
          _Hinweis(
            key: const Key('versand-standort-ohne-email'),
            text: 'Für den Standort „${standort['bezeichnung']}“ ist keine E-Mail hinterlegt. '
                'Sie lässt sich beim Standort ergänzen.',
          ),
        RadioGroup<_Empfaenger>(
          groupValue: _wahl,
          onChanged: _sendet ? (_) {} : (v) => setState(() => _wahl = v),
          child: Column(
            children: [
              if (_standortEmail != null)
                RadioListTile<_Empfaenger>(
                  key: const Key('versand-empfaenger-standort'),
                  value: _Empfaenger.standort,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_standortEmail!),
                  subtitle: Text([
                    'Standort ${standort!['bezeichnung']}',
                    if (standort['kontaktPerson'] != null) standort['kontaktPerson'],
                  ].join(' · ')),
                ),
              if (_kundeEmail != null)
                RadioListTile<_Empfaenger>(
                  key: const Key('versand-empfaenger-kunde'),
                  value: _Empfaenger.kunde,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_kundeEmail!),
                  subtitle: Text([
                    'Kunde ${_kunde!['name']} (nicht der Standort)',
                    if (_kunde!['ansprechpartner'] != null) _kunde!['ansprechpartner'],
                  ].join(' · ')),
                ),
              const RadioListTile<_Empfaenger>(
                key: Key('versand-empfaenger-andere'),
                value: _Empfaenger.andere,
                contentPadding: EdgeInsets.zero,
                title: Text('Andere Adresse'),
              ),
            ],
          ),
        ),
        if (_wahl == _Empfaenger.andere)
          TextField(
            key: const Key('versand-andere'),
            controller: _andereCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
          ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('versand-cc'),
          controller: _ccCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'CC (optional)',
            helperText: 'Mehrere Adressen mit Komma trennen',
          ),
        ),
        if (_fehler != null) ...[
          const SizedBox(height: 12),
          Text(_fehler!, key: const Key('versand-fehler'), style: const TextStyle(color: AppColors.error)),
        ],
        if (verlauf.isNotEmpty) ...[
          const Divider(height: 24),
          Text('Bisherige Versendungen', style: theme.textTheme.titleSmall),
          for (final v in verlauf) _VerlaufZeile(v),
        ],
      ],
    );
  }
}

class _Hinweis extends StatelessWidget {
  const _Hinweis({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning)),
      );
}

class _VerlaufZeile extends StatelessWidget {
  const _VerlaufZeile(this.v);
  final Map<String, dynamic> v;

  static String _zeit(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '–';
    String zwei(int n) => n.toString().padLeft(2, '0');
    return '${zwei(d.day)}.${zwei(d.month)}.${d.year} ${zwei(d.hour)}:${zwei(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, farbe, text) = switch (v['status']) {
      'gesendet' => (Icons.check_circle_outline, AppColors.success, 'gesendet'),
      'fehler' => (Icons.error_outline, AppColors.error, 'fehlgeschlagen: ${v['fehler'] ?? ''}'),
      _ => (Icons.help_outline, AppColors.warning, 'Status unklar (abgebrochen)'),
    };
    final cc = (v['cc'] as List?)?.cast<String>() ?? const [];
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: farbe),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_zeit(v['erstelltAm'] as String?)} an ${v['empfaenger']}'
              '${cc.isEmpty ? '' : ' (CC ${cc.join(', ')})'}'
              '${v['benutzer'] == null ? '' : ' · ${v['benutzer']}'} — $text',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
