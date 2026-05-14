import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/kunde.dart';
import '../../core/models/verteiler_komponente.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../shared/theme/app_colors.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'CSV-Import',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.business_center_outlined), text: 'Kunden'),
            Tab(
                icon: Icon(Icons.electrical_services_outlined),
                text: 'Komponenten'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _KundenImportTab(),
          _KomponentenImportTab(),
        ],
      ),
    );
  }
}

// ── Kunden-Import Tab ─────────────────────────────────────────────────────────

class _KundenImportTab extends ConsumerStatefulWidget {
  const _KundenImportTab();

  @override
  ConsumerState<_KundenImportTab> createState() => _KundenImportTabState();
}

class _KundenImportTabState extends ConsumerState<_KundenImportTab> {
  List<List<dynamic>>? _rows;
  List<_ValidationResult> _validationResults = [];
  bool _importing = false;
  double _progress = 0.0;
  String? _errorMessage;

  static const _headers = [
    'name',
    'strasse',
    'plz',
    'ort',
    'kontakt_email',
    'kontakt_telefon',
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final content = utf8.decode(bytes);
      final rows = const CsvToListConverter(eol: '\n').convert(content);

      if (rows.isEmpty) {
        setState(() => _errorMessage = 'Leere CSV-Datei');
        return;
      }

      // Überspringe Header-Zeile wenn vorhanden
      final headerRow = rows.first.map((e) => e.toString().toLowerCase()).toList();
      final dataRows = _isHeaderRow(headerRow) ? rows.skip(1).toList() : rows;

      final results = dataRows
          .map((row) => _validateKundeRow(row))
          .toList();

      setState(() {
        _rows = dataRows;
        _validationResults = results;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Fehler beim Lesen: $e');
    }
  }

  bool _isHeaderRow(List<dynamic> row) {
    return row.isNotEmpty &&
        row.first.toString().toLowerCase().contains('name');
  }

  _ValidationResult _validateKundeRow(List<dynamic> row) {
    final name = row.isNotEmpty ? row[0].toString().trim() : '';
    if (name.isEmpty) {
      return _ValidationResult(
          isValid: false, errorMessage: 'Name ist Pflichtfeld');
    }
    return _ValidationResult(isValid: true);
  }

  Future<void> _importKunden() async {
    if (_rows == null) return;
    final repo = ref.read(kundenRepositoryProvider);
    setState(() {
      _importing = true;
      _progress = 0.0;
    });

    final validRows = <int>[];
    for (var i = 0; i < _validationResults.length; i++) {
      if (_validationResults[i].isValid) validRows.add(i);
    }

    for (var idx = 0; idx < validRows.length; idx++) {
      final row = _rows![validRows[idx]];
      final kunde = Kunde(
        name: row.isNotEmpty ? row[0].toString().trim() : 'Unbekannt',
        strasse: row.length > 1 ? _nullable(row[1].toString()) : null,
        plz: row.length > 2 ? _nullable(row[2].toString()) : null,
        ort: row.length > 3 ? _nullable(row[3].toString()) : null,
        kontaktEmail: row.length > 4 ? _nullable(row[4].toString()) : null,
        kontaktTelefon: row.length > 5 ? _nullable(row[5].toString()) : null,
      );
      await repo.save(kunde);
      setState(() => _progress = (idx + 1) / validRows.length);
    }

    setState(() => _importing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${validRows.length} Kunden importiert'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _rows = null;
        _validationResults = [];
        _progress = 0.0;
      });
    }
  }

  String? _nullable(String s) => s.trim().isEmpty ? null : s.trim();

  void _downloadTemplate() {
    const template = 'name,strasse,plz,ort,kontakt_email,kontakt_telefon\n'
        'Muster GmbH,Musterstraße 1,12345,Berlin,info@muster.de,030-123456\n';
    // Auf Web: DataUri-Download
    _triggerDownload(template, 'kunden_vorlage.csv');
  }

  void _triggerDownload(String content, String filename) {
    // Zeige als Dialog (plattformübergreifend kompatibel)
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('CSV-Vorlage: $filename'),
        content: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCount =
        _validationResults.where((r) => r.isValid).length;
    final invalidCount =
        _validationResults.where((r) => !r.isValid).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Text('Kunden importieren',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Spalten: ${_headers.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // ── Actions ─────────────────────────────────────────────────────
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Vorlage anzeigen'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _importing ? null : _pickFile,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('CSV auswählen'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Error ─────────────────────────────────────────────────────
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // ── Preview ─────────────────────────────────────────────────
          if (_rows != null) ...[
            Row(
              children: [
                Text(
                  '${_rows!.length} Zeilen erkannt',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 12),
                if (validCount > 0)
                  _Pill(
                      label: '$validCount gültig',
                      color: AppColors.success),
                if (invalidCount > 0) ...[
                  const SizedBox(width: 8),
                  _Pill(
                      label: '$invalidCount fehlerhaft',
                      color: AppColors.error),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _PreviewTable(
              rows: _rows!.take(5).toList(),
              headers: _headers,
              validationResults: _validationResults.take(5).toList(),
            ),
            if (_rows!.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... und ${_rows!.length - 5} weitere Zeilen',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            const SizedBox(height: 16),

            // ── Import Button ──────────────────────────────────────────
            if (_importing) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Importiere... ${(_progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (validCount > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _importKunden,
                  icon: const Icon(Icons.check_outlined, size: 16),
                  label: Text('$validCount Kunden importieren'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Komponenten-Import Tab ────────────────────────────────────────────────────

class _KomponentenImportTab extends ConsumerStatefulWidget {
  const _KomponentenImportTab();

  @override
  ConsumerState<_KomponentenImportTab> createState() =>
      _KomponentenImportTabState();
}

class _KomponentenImportTabState
    extends ConsumerState<_KomponentenImportTab> {
  List<List<dynamic>>? _rows;
  List<_ValidationResult> _validationResults = [];
  bool _importing = false;
  double _progress = 0.0;
  String? _errorMessage;

  static const _headers = [
    'verteiler_uuid',
    'typ',
    'bezeichnung',
    'nennstrom',
    'pole',
    'charakteristik',
  ];

  static const _validTypes = [
    'ls_schalter',
    'rcd',
    'fi_ls',
    'hauptschalter',
    'vorsicherung',
    'nh_sicherung',
    'ueberspannung',
    'sammelschiene',
    'sonstige',
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final content = utf8.decode(bytes);
      final rows = const CsvToListConverter(eol: '\n').convert(content);

      if (rows.isEmpty) {
        setState(() => _errorMessage = 'Leere CSV-Datei');
        return;
      }

      final headerRow =
          rows.first.map((e) => e.toString().toLowerCase()).toList();
      final dataRows =
          _isHeaderRow(headerRow) ? rows.skip(1).toList() : rows;

      final results = dataRows.map((row) => _validateRow(row)).toList();

      setState(() {
        _rows = dataRows;
        _validationResults = results;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Fehler beim Lesen: $e');
    }
  }

  bool _isHeaderRow(List<dynamic> row) {
    return row.isNotEmpty &&
        (row.first.toString().toLowerCase().contains('verteiler') ||
            row.first.toString().toLowerCase().contains('typ'));
  }

  _ValidationResult _validateRow(List<dynamic> row) {
    if (row.length < 3) {
      return _ValidationResult(
          isValid: false,
          errorMessage: 'Mindestens verteiler_uuid, typ, bezeichnung');
    }
    final verteilerUuid = row[0].toString().trim();
    final typ = row[1].toString().trim().toLowerCase();
    final bezeichnung = row[2].toString().trim();

    if (verteilerUuid.isEmpty) {
      return _ValidationResult(
          isValid: false, errorMessage: 'verteiler_uuid Pflichtfeld');
    }
    if (bezeichnung.isEmpty) {
      return _ValidationResult(
          isValid: false, errorMessage: 'Bezeichnung Pflichtfeld');
    }
    if (!_validTypes.contains(typ)) {
      return _ValidationResult(
          isValid: false, errorMessage: 'Unbekannter Typ: $typ');
    }
    return _ValidationResult(isValid: true);
  }

  Future<void> _importKomponenten() async {
    if (_rows == null) return;
    final repo = ref.read(komponentenRepositoryProvider);
    setState(() {
      _importing = true;
      _progress = 0.0;
    });

    final validRows = <int>[];
    for (var i = 0; i < _validationResults.length; i++) {
      if (_validationResults[i].isValid) validRows.add(i);
    }

    for (var idx = 0; idx < validRows.length; idx++) {
      final row = _rows![validRows[idx]];
      final nennstrom = row.length > 3 ? row[3].toString().trim() : '';
      final pole = row.length > 4 ? row[4].toString().trim() : '';
      final charakteristik = row.length > 5 ? row[5].toString().trim() : '';

      final eigenschaften = <String, dynamic>{};
      if (nennstrom.isNotEmpty) {
        eigenschaften['nennstrom'] =
            double.tryParse(nennstrom) ?? nennstrom;
      }
      if (pole.isNotEmpty) {
        eigenschaften['pole'] = int.tryParse(pole);
      }
      if (charakteristik.isNotEmpty) {
        eigenschaften['charakteristik'] = charakteristik.toUpperCase();
      }

      final k = VerteilerKomponente(
        verteilerUuid: row[0].toString().trim(),
        typ: row[1].toString().trim().toLowerCase(),
        bezeichnung: row[2].toString().trim(),
        eigenschaftenJson:
            eigenschaften.isEmpty ? null : _jsonEncode(eigenschaften),
      );
      await repo.save(k);
      setState(() => _progress = (idx + 1) / validRows.length);
    }

    setState(() => _importing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${validRows.length} Komponenten importiert'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _rows = null;
        _validationResults = [];
        _progress = 0.0;
      });
    }
  }

  String _jsonEncode(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  void _showTemplate() {
    const template =
        'verteiler_uuid,typ,bezeichnung,nennstrom,pole,charakteristik\n'
        'uuid-hier,ls_schalter,L1 Licht EG,16,1,B\n'
        'uuid-hier,rcd,FI Gruppe 1,25,4,\n';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV-Vorlage: komponenten_vorlage.csv'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                template,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gültige Typen: ls_schalter, rcd, fi_ls, hauptschalter, '
                'vorsicherung, nh_sicherung, ueberspannung, sammelschiene, sonstige',
                style: TextStyle(
                    fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCount = _validationResults.where((r) => r.isValid).length;
    final invalidCount = _validationResults.where((r) => !r.isValid).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Komponenten importieren',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Spalten: ${_headers.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showTemplate,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Vorlage anzeigen'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _importing ? null : _pickFile,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('CSV auswählen'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          if (_rows != null) ...[
            Row(
              children: [
                Text(
                  '${_rows!.length} Zeilen erkannt',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 12),
                if (validCount > 0)
                  _Pill(
                      label: '$validCount gültig',
                      color: AppColors.success),
                if (invalidCount > 0) ...[
                  const SizedBox(width: 8),
                  _Pill(
                      label: '$invalidCount fehlerhaft',
                      color: AppColors.error),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _PreviewTable(
              rows: _rows!.take(5).toList(),
              headers: _headers,
              validationResults: _validationResults.take(5).toList(),
            ),
            if (_rows!.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... und ${_rows!.length - 5} weitere Zeilen',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            const SizedBox(height: 16),

            if (_importing) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Importiere... ${(_progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (validCount > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _importKomponenten,
                  icon: const Icon(Icons.check_outlined, size: 16),
                  label: Text('$validCount Komponenten importieren'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _ValidationResult {
  const _ValidationResult({required this.isValid, this.errorMessage});
  final bool isValid;
  final String? errorMessage;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({
    required this.rows,
    required this.headers,
    required this.validationResults,
  });

  final List<List<dynamic>> rows;
  final List<String> headers;
  final List<_ValidationResult> validationResults;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        children: [
          // Header row
          TableRow(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
            ),
            children: [
              ...headers.map((h) => _cell(h, isHeader: true)),
              _cell('Status', isHeader: true),
            ],
          ),
          // Data rows
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final validation = idx < validationResults.length
                ? validationResults[idx]
                : const _ValidationResult(isValid: true);
            final rowColor = validation.isValid
                ? Colors.transparent
                : AppColors.errorContainer;
            return TableRow(
              decoration: BoxDecoration(color: rowColor),
              children: [
                ...List.generate(
                  headers.length,
                  (i) => _cell(
                      i < row.length ? row[i].toString() : ''),
                ),
                _cell(
                  validation.isValid
                      ? 'OK'
                      : validation.errorMessage ?? 'Fehler',
                  textColor: validation.isValid
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    bool isHeader = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
          color: textColor ??
              (isHeader ? AppColors.primary : AppColors.onSurface),
        ),
      ),
    );
  }
}
