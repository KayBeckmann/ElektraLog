import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast.dart';

import '../../core/database/isar_service.dart';
import '../../core/models/geraet.dart';
import '../../core/providers/isar_provider.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_meta.dart';
import '../../core/sync/sync_service.dart';
import '../../shared/theme/app_colors.dart';

/// Sync-Konflikte zusammenführen (Roadmap Geräteprüfung M3). Konflikte
/// entstehen nur bei echten gleichzeitigen Änderungen, unbestätigten
/// Ortswechseln von Geräten oder vom Server abgelehnten Datensätzen —
/// alles andere synchronisiert still.
class KonflikteScreen extends ConsumerWidget {
  const KonflikteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final konflikte = ref.watch(syncKonflikteProvider).valueOrNull ?? const [];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Sync-Konflikte'),
        backgroundColor: AppColors.surface,
      ),
      body: konflikte.isEmpty
          ? const Center(child: Text('Keine offenen Konflikte.', key: Key('keine-konflikte')))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final k in konflikte)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppColors.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      child: ListTile(
                        key: Key('konflikt-${k.uuid}'),
                        leading: Icon(_icon(k.art), color: AppColors.warning),
                        title: Text(_titel(k)),
                        subtitle: Text('${typBezeichnung(k.typ)} · ${_artText(k)}'),
                        trailing: const Icon(Icons.arrow_forward, size: 16),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: AppColors.surface,
                          builder: (_) => KonfliktAufloesen(konflikt: k),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  static IconData _icon(String art) => switch (art) {
        'zuordnung' => Icons.swap_horiz,
        'abgelehnt' => Icons.block,
        _ => Icons.call_split,
      };

  static String _titel(SyncKonflikt k) =>
      (k.lokal['bezeichnung'] ?? k.lokal['name'] ?? k.lokal['zielbezeichnung'] ?? k.uuid).toString();

  static String _artText(SyncKonflikt k) => switch (k.art) {
        'zuordnung' => 'Ortswechsel bestätigen',
        'abgelehnt' => 'vom Server abgelehnt: ${k.grund ?? ''}',
        _ => 'auf zwei Geräten geändert',
      };
}

String typBezeichnung(String typ) => switch (typ) {
      'kunden' => 'Kunde',
      'standorte' => 'Standort',
      'verteiler' => 'Verteiler',
      'komponenten' => 'Komponente',
      'messungen' => 'Messung',
      'sichtpruefungen' => 'Sichtprüfung',
      'raeume' => 'Raum',
      'geraete' => 'Gerät',
      _ => typ,
    };

const _feldNamen = {
  'name': 'Name',
  'bezeichnung': 'Bezeichnung',
  'strasse': 'Straße',
  'plz': 'PLZ',
  'ort': 'Ort',
  'kontaktEmail': 'E-Mail',
  'kontaktTelefon': 'Telefon',
  'bemerkung': 'Bemerkung',
  'kundeUuid': 'Kunde',
  'standortUuid': 'Standort',
  'raumUuid': 'Raum',
  'verteilerUuid': 'Verteiler',
  'hersteller': 'Hersteller',
  'typ': 'Type/Typ',
  'seriennummer': 'Seriennummer',
  'inventarnummer': 'Inventarnummer',
  'schutzart': 'Schutzart',
  'schutzklasse': 'Schutzklasse',
  'aktiv': 'Aktiv',
  'inaktivGrund': 'Inaktiv-Grund',
  'pruefintervallMonate': 'Prüfintervall (Monate)',
  'pruefintervallJahre': 'Prüfintervall (Jahre)',
  'pruefungDatum': 'Prüfdatum',
  'prueferName': 'Prüfer',
  'ergebnis': 'Ergebnis',
};

const _ortsFelder = {'kundeUuid', 'standortUuid', 'raumUuid'};

/// Lesbarer Name zu einer Kunden-/Standort-/Raum-/Verteiler-UUID.
final _ortsNameProvider = FutureProvider.family<String, String>((ref, uuid) async {
  final db = await ref.watch(dbProvider.future);
  for (final (store, feld) in [
    (StorageService.kundenStore, 'name'),
    (StorageService.standorteStore, 'bezeichnung'),
    (StorageService.raeumeStore, 'bezeichnung'),
    (StorageService.verteilerStore, 'bezeichnung'),
  ]) {
    final v = await store.record(uuid).get(db);
    if (v != null) return '${v[feld]}';
  }
  return 'unbekannt (nicht synchronisiert)';
});

class KonfliktAufloesen extends ConsumerStatefulWidget {
  const KonfliktAufloesen({super.key, required this.konflikt});

  final SyncKonflikt konflikt;

  @override
  ConsumerState<KonfliktAufloesen> createState() => _KonfliktAufloesenState();
}

class _KonfliktAufloesenState extends ConsumerState<KonfliktAufloesen> {
  /// Feld → true = lokale Fassung übernehmen.
  late final Map<String, bool> _lokal = {
    for (final f in _unterschiede) f: widget.konflikt.art == 'zuordnung' && _ortsFelder.contains(f),
  };

  List<String> get _unterschiede {
    final k = widget.konflikt;
    final server = k.server ?? const {};
    final felder = {...k.lokal.keys, ...server.keys}
      ..removeAll(['uuid', 'erstelltAm', 'aktualisiertAm', 'version', 'statusHistorieJson']);
    return [
      for (final f in felder)
        if ('${k.lokal[f]}' != '${server[f]}') f,
    ];
  }

  Widget _wert(String feld, Object? wert) {
    if (wert == null || '$wert'.isEmpty) return const Text('–');
    if (feld.endsWith('Uuid')) {
      return Text(ref.watch(_ortsNameProvider('$wert')).valueOrNull ?? '…');
    }
    if (wert is bool) return Text(wert ? 'ja' : 'nein');
    return Text('$wert');
  }

  Future<void> _uebernehmen() async {
    final k = widget.konflikt;
    final ergebnis = {...?k.server};
    for (final e in _lokal.entries) {
      if (e.value) ergebnis[e.key] = k.lokal[e.key];
    }
    if (k.typ == 'geraete') {
      // Verlauf (Status/Intervall) beider Seiten behalten.
      ergebnis['statusHistorieJson'] =
          verlaufVereinigen(k.lokal['statusHistorieJson'] as String?, k.server?['statusHistorieJson'] as String?);
    }
    final ortLokal = _ortsFelder.any((f) => _lokal[f] == true);
    final db = await ref.read(dbProvider.future);
    await SyncEngine(db).aufloesen(k, ergebnis, zuordnungBestaetigt: ortLokal);
    SyncService.scheduleSync(db);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.konflikt;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              k.art == 'zuordnung'
                  ? 'Ortswechsel bestätigen'
                  : k.art == 'abgelehnt'
                      ? 'Vom Server abgelehnt'
                      : 'Änderungen zusammenführen',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              switch (k.art) {
                'zuordnung' => 'Kunde, Standort oder Raum dieses Geräts wurde geändert. Neuen Ort bestätigen '
                    'oder den bisherigen behalten. Abgeschlossene Prüfungen behalten ihren damaligen Ort.',
                'abgelehnt' => 'Grund: ${k.grund ?? 'unbekannt'}. Korrigieren und erneut senden oder '
                    'die lokale Fassung verwerfen.',
                _ => 'Derselbe Datensatz wurde hier und auf einem anderen Gerät geändert. '
                    'Wähle je Feld, welche Fassung gilt.',
              },
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (k.art == 'abgelehnt') ...[
              ElevatedButton(
                key: const Key('konflikt-erneut'),
                onPressed: () async {
                  final db = await ref.read(dbProvider.future);
                  await SyncKonfliktRepository(db).delete(k.typ, k.uuid);
                  SyncService.scheduleSync(db);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Erneut senden'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('konflikt-verwerfen'),
                onPressed: () async {
                  final db = await ref.read(dbProvider.future);
                  await SyncEngine(db).verwerfen(k);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Lokale Fassung verwerfen'),
              ),
            ] else ...[
              Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  Expanded(flex: 4, child: Text('Dieses Gerät', style: theme.textTheme.labelLarge)),
                  Expanded(flex: 4, child: Text('Server', style: theme.textTheme.labelLarge)),
                ],
              ),
              const Divider(),
              for (final f in _unterschiede)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: Text(_feldNamen[f] ?? f, style: theme.textTheme.bodySmall)),
                      Expanded(
                        flex: 4,
                        child: _Wahl(
                          key: Key('wahl-lokal-$f'),
                          gewaehlt: _lokal[f] == true,
                          onTap: () => setState(() => _lokal[f] = true),
                          child: _wert(f, k.lokal[f]),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: _Wahl(
                          key: Key('wahl-server-$f'),
                          gewaehlt: _lokal[f] != true,
                          onTap: () => setState(() => _lokal[f] = false),
                          child: _wert(f, k.server?[f]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('konflikt-uebernehmen'),
                onPressed: _uebernehmen,
                child: Text(k.art == 'zuordnung' && _ortsFelder.any((f) => _lokal[f] == true)
                    ? 'Neuen Ort bestätigen'
                    : 'Auswahl übernehmen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Wahl extends StatelessWidget {
  const _Wahl({super.key, required this.gewaehlt, required this.onTap, required this.child});

  final bool gewaehlt;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: gewaehlt ? AppColors.secondaryContainer : null,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: gewaehlt ? AppColors.secondary : AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(gewaehlt ? Icons.radio_button_checked : Icons.radio_button_off, size: 14),
              const SizedBox(width: 4),
              Expanded(child: child),
            ],
          ),
        ),
      );
}
