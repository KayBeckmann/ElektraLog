import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/models/geraet.dart';
import '../pdf/geraete_pdf.dart';

/// Etiketten für ein oder mehrere Geräte über den Systemdruck (Roadmap M7).
/// Ohne getesteten Bluetooth-Drucker bleibt PDF der geräteunabhängige Weg.
Future<void> zeigeEtikettenDialog(BuildContext context, List<Geraet> geraete) => showDialog<void>(
      context: context,
      builder: (_) => _EtikettenDialog(geraete: geraete),
    );

class _EtikettenDialog extends StatefulWidget {
  const _EtikettenDialog({required this.geraete});

  final List<Geraet> geraete;

  @override
  State<_EtikettenDialog> createState() => _EtikettenDialogState();
}

class _EtikettenDialogState extends State<_EtikettenDialog> {
  EtikettFormat _format = EtikettFormat.e50x30;
  bool _mitBezeichnung = false;

  Future<void> _drucken() async {
    final bytes = await etikettenPdf(widget.geraete, format: _format, mitBezeichnung: _mitBezeichnung);
    await Printing.layoutPdf(
      name: widget.geraete.length == 1 ? 'Etikett ${widget.geraete.single.bezeichnung}' : 'Etiketten',
      format: _format == EtikettFormat.a4
          ? PdfPageFormat.a4
          : PdfPageFormat(_format.breiteMm * PdfPageFormat.mm, _format.hoeheMm * PdfPageFormat.mm),
      onLayout: (_) async => bytes,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.geraete.length == 1 ? 'Etikett drucken' : '${widget.geraete.length} Etiketten drucken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<EtikettFormat>(
              key: const Key('etikett-format'),
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Format'),
              items: [for (final f in EtikettFormat.values) DropdownMenuItem(value: f, child: Text(f.bezeichnung))],
              onChanged: (f) => setState(() => _format = f!),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _mitBezeichnung,
              title: const Text('Bezeichnung mitdrucken'),
              onChanged: (v) => setState(() => _mitBezeichnung = v!),
            ),
            const Text(
              'QR-Code mit der vollständigen Geräte-UUID, darunter dieselbe UUID lesbar. '
              'Nachdruck ergibt immer dieselbe UUID.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(key: const Key('etikett-drucken'), onPressed: _drucken, child: const Text('Drucken')),
        ],
      );
}
