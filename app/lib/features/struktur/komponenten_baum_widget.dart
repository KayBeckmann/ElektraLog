import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_service.dart';
import '../../core/models/verteiler_komponente.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../core/providers/messungen_provider.dart';
import '../../features/messungen/messung_formular.dart';
import '../../features/messungen/messungen_liste.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/status_pill.dart';
import '../../shared/theme/app_theme.dart';

class KomponentenBaumWidget extends ConsumerStatefulWidget {
  const KomponentenBaumWidget({
    super.key,
    required this.verteilerUuid,
    required this.onAddKomponente,
    required this.onEditKomponente,
  });

  final String verteilerUuid;
  final void Function(String? parentUuid) onAddKomponente;
  final void Function(VerteilerKomponente k) onEditKomponente;


  @override
  ConsumerState<KomponentenBaumWidget> createState() =>
      _KomponentenBaumWidgetState();
}

class _KomponentenBaumWidgetState
    extends ConsumerState<KomponentenBaumWidget> {
  // Global expand/collapse state — null = each node decides independently
  bool _allExpanded = true;
  // Incrementing key forces node rebuild when global expand/collapse changes
  int _expandKey = 0;

  @override
  Widget build(BuildContext context) {
    final komponentenAsync =
        ref.watch(komponentenByVerteilerProvider(widget.verteilerUuid));

    return komponentenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Fehler: $e'),
      data: (komponenten) {
        if (komponenten.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                const Icon(Icons.account_tree_outlined,
                    size: 48, color: AppColors.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  'Noch keine Komponenten',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => widget.onAddKomponente(null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Erste Komponente hinzufügen'),
                ),
              ],
            ),
          );
        }

        final roots =
            komponenten.where((k) => k.parentUuid == null).toList();
        roots.sort((a, b) => a.position.compareTo(b.position));

        final hasChildren = komponenten.any((k) => k.parentUuid != null);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Toolbar ─────────────────────────────────────────────────────
            if (hasChildren)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Alle einklappen / ausklappen
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _allExpanded = !_allExpanded;
                        _expandKey++;
                      }),
                      icon: Icon(
                        _allExpanded
                            ? Icons.unfold_less
                            : Icons.unfold_more,
                        size: 14,
                      ),
                      label: Text(
                          _allExpanded ? 'Alle einklappen' : 'Alle ausklappen'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nach BMK sortieren
                    OutlinedButton.icon(
                      onPressed: () =>
                          _sortierNachBmk(ref, komponenten),
                      icon: const Icon(Icons.sort_by_alpha, size: 14),
                      label: const Text('Nach BMK sortieren'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            ...roots.map((root) => _KomponentenNode(
                  key: ValueKey('${root.uuid}_$_expandKey'),
                  komponente: root,
                  allKomponenten: komponenten,
                  depth: 0,
                  verteilerUuid: widget.verteilerUuid,
                  onAddChild: widget.onAddKomponente,
                  onEditKomponente: widget.onEditKomponente,
                  isLast: root == roots.last,
                  initialExpanded: _allExpanded,
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => widget.onAddKomponente(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Wurzel-Element hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sortierNachBmk(
    WidgetRef ref,
    List<VerteilerKomponente> alle,
  ) async {
    final repo = ref.read(komponentenRepositoryProvider);
    // Für jede Elternebene separat nach BMK sortieren
    final parentUuids = <String?>{};
    for (final k in alle) {
      parentUuids.add(k.parentUuid);
    }
    for (final parentUuid in parentUuids) {
      final siblings = alle
          .where((k) => k.parentUuid == parentUuid)
          .toList()
        ..sort((a, b) {
          final bmkA = a.betriebsmittelkennzeichen;
          final bmkB = b.betriebsmittelkennzeichen;
          if (bmkA.isEmpty && bmkB.isEmpty) {
            return a.zielbezeichnung.compareTo(b.zielbezeichnung);
          }
          if (bmkA.isEmpty) return 1;
          if (bmkB.isEmpty) return -1;
          return bmkA.compareTo(bmkB);
        });
      for (int i = 0; i < siblings.length; i++) {
        if (siblings[i].position != i) {
          await repo.save(siblings[i].copyWith(position: i));
        }
      }
    }
  }
}

// ── Node Widget ───────────────────────────────────────────────────────────────

class _KomponentenNode extends ConsumerStatefulWidget {
  const _KomponentenNode({
    super.key,
    required this.komponente,
    required this.allKomponenten,
    required this.depth,
    required this.verteilerUuid,
    required this.onAddChild,
    required this.onEditKomponente,
    required this.isLast,
    required this.initialExpanded,
  });

  final VerteilerKomponente komponente;
  final List<VerteilerKomponente> allKomponenten;
  final int depth;
  final String verteilerUuid;
  final void Function(String? parentUuid) onAddChild;
  final void Function(VerteilerKomponente k) onEditKomponente;
  final bool isLast;
  final bool initialExpanded;

  @override
  ConsumerState<_KomponentenNode> createState() => _KomponentenNodeState();
}

class _KomponentenNodeState extends ConsumerState<_KomponentenNode> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded;
  }

  /// Alle UUIDs der Komponente selbst und ihrer Nachkommen.
  Set<String> _descendants(VerteilerKomponente k) {
    final result = <String>{k.uuid};
    for (final child
        in widget.allKomponenten.where((c) => c.parentUuid == k.uuid)) {
      result.addAll(_descendants(child));
    }
    return result;
  }

  Future<void> _showLoeschenDialog(
      BuildContext context, VerteilerKomponente k) async {
    final descs = _descendants(k);
    final childCount = descs.length - 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bauteil löschen'),
        content: Text(
          childCount > 0
              ? '"${k.bezeichnung}" und $childCount Unterkomponente(n) wirklich löschen?\n\nAlle zugehörigen Messungen werden ebenfalls entfernt.'
              : '"${k.bezeichnung}" wirklich löschen?\n\nAlle zugehörigen Messungen werden ebenfalls entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final kompRepo = ref.read(komponentenRepositoryProvider);
    final messRepo = ref.read(messungenRepositoryProvider);
    for (final uuid in descs) {
      await messRepo.deleteByKomponente(uuid);
      await kompRepo.delete(uuid);
    }
    // Server informieren — fire-and-forget; 401 im Offline-Modus ist erwartet
    for (final uuid in descs) {
      ApiService.deleteKomponente(uuid).catchError((_) {});
    }
  }

  Future<void> _showVerschiebenDialog(
      BuildContext context, VerteilerKomponente k) async {
    final descs = _descendants(k);
    // Potenzielle neue Parents: alle anderen Komponenten, die kein Nachkomme sind
    final potenzielleParents = widget.allKomponenten
        .where((c) => !descs.contains(c.uuid))
        .toList();

    String? neuerParentUuid = k.parentUuid;
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('"${k.bezeichnung}" verschieben'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                RadioListTile<String?>(
                  title: const Text('Kein übergeordnetes Element (Wurzel)'),
                  value: null,
                  groupValue: neuerParentUuid,
                  onChanged: (v) => setStateDialog(() => neuerParentUuid = v),
                ),
                const Divider(),
                ...potenzielleParents.map((p) => RadioListTile<String?>(
                      title: Text(p.bezeichnung),
                      subtitle: Text(
                        p.typ.replaceAll('_', ' '),
                        style: AppTheme.dataMono(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant),
                      ),
                      value: p.uuid,
                      groupValue: neuerParentUuid,
                      onChanged: (v) =>
                          setStateDialog(() => neuerParentUuid = v),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, neuerParentUuid ?? '__root__'),
              child: const Text('Verschieben'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final neuerParent = result == '__root__' ? null : result;
    if (neuerParent == k.parentUuid) return;
    final verschoben = VerteilerKomponente(
      uuid: k.uuid,
      verteilerUuid: k.verteilerUuid,
      parentUuid: neuerParent,
      typ: k.typ,
      betriebsmittelkennzeichen: k.betriebsmittelkennzeichen,
      zielbezeichnung: k.zielbezeichnung,
      position: k.position,
      eigenschaftenJson: k.eigenschaftenJson,
      erstelltAm: k.erstelltAm,
    );
    await ref.read(komponentenRepositoryProvider).save(verschoben);
  }

  void _showMessungenSheet(BuildContext context, VerteilerKomponente k) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                k.bezeichnung,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              MessungenListe(
                komponenteUuid: k.uuid,
                verteilerUuid: widget.verteilerUuid,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveKomponente(
    WidgetRef ref,
    VerteilerKomponente k,
    int delta,
    List<VerteilerKomponente> all,
  ) async {
    final siblings = all
        .where((c) =>
            c.parentUuid == k.parentUuid && c.verteilerUuid == k.verteilerUuid)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // Positionen normalisieren falls Duplikate existieren (z.B. alle 0)
    final repo = ref.read(komponentenRepositoryProvider);
    bool needsNorm = false;
    for (int i = 0; i < siblings.length; i++) {
      if (siblings[i].position != i) needsNorm = true;
    }
    if (needsNorm) {
      for (int i = 0; i < siblings.length; i++) {
        await repo.save(siblings[i].copyWith(position: i));
        siblings[i] = siblings[i].copyWith(position: i);
      }
    }

    final idx = siblings.indexWhere((c) => c.uuid == k.uuid);
    final newIdx = idx + delta;
    if (newIdx < 0 || newIdx >= siblings.length) return;

    final other = siblings[newIdx];
    await repo.save(k.copyWith(position: other.position));
    await repo.save(other.copyWith(position: k.position));
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.komponente;
    final children = widget.allKomponenten
        .where((c) => c.parentUuid == k.uuid)
        .toList();
    children.sort((a, b) => a.position.compareTo(b.position));
    final hasChildren = children.isNotEmpty;

    final messungenAsync =
        ref.watch(messungenByKomponenteProvider(k.uuid));
    final status = messungenAsync.when(
      data: (list) {
        if (list.isEmpty) return PillStatus.offen;
        final last = list.first;
        if (last.ergebnis == 'bestanden') return PillStatus.passed;
        if (last.ergebnis == 'nicht_bestanden') return PillStatus.failed;
        return PillStatus.offen;
      },
      loading: () => PillStatus.offen,
      error: (_, __) => PillStatus.offen,
    );

    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Vertical line for tree branches ───────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.depth > 0)
                  Container(
                    width: 2,
                    color: AppColors.outlineVariant,
                  ),
                if (widget.depth > 0) const SizedBox(width: 18),

                // ── Node itself ─────────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              // Expand/collapse chevron
                              SizedBox(
                                width: 20,
                                child: hasChildren
                                    ? GestureDetector(
                                        onTap: () => setState(
                                            () => _expanded = !_expanded),
                                        child: Icon(
                                          _expanded
                                              ? Icons.expand_more
                                              : Icons.chevron_right,
                                          size: 18,
                                          color:
                                              AppColors.onSurfaceVariant,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              // Type icon
                              _TypIcon(typ: k.typ),
                              const SizedBox(width: 8),

                              // BMK + Zielbezeichnung + technische Daten
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (k.betriebsmittelkennzeichen.isNotEmpty)
                                      Text(
                                        k.betriebsmittelkennzeichen,
                                        style: AppTheme.dataMono(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    Text(
                                      k.zielbezeichnung.isNotEmpty
                                          ? k.zielbezeichnung
                                          : k.betriebsmittelkennzeichen,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    _TechnischeDaten(k: k),
                                  ],
                                ),
                              ),

                              // Status pill
                              StatusPill(status: status),
                              const SizedBox(width: 4),

                              // QR button
                              IconButton(
                                onPressed: () => context.push(
                                  '/qr/${k.uuid}',
                                ),
                                icon: const Icon(
                                  Icons.qr_code_outlined,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: 'QR-Code',
                              ),

                              // More menu
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant),
                                padding: EdgeInsets.zero,
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'messungen',
                                    child: Row(children: [
                                      Icon(Icons.bar_chart_outlined, size: 14),
                                      SizedBox(width: 8),
                                      Text('Messungen'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'bearbeiten',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 14),
                                      SizedBox(width: 8),
                                      Text('Bearbeiten'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'add_child',
                                    child: Row(children: [
                                      Icon(Icons.add, size: 14),
                                      SizedBox(width: 8),
                                      Text('Unterkomponente'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'messung',
                                    child: Row(children: [
                                      Icon(Icons.science_outlined, size: 14),
                                      SizedBox(width: 8),
                                      Text('Messung hinzufügen'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'nach_oben',
                                    child: Row(children: [
                                      Icon(Icons.arrow_upward_outlined,
                                          size: 14),
                                      SizedBox(width: 8),
                                      Text('Nach oben'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'nach_unten',
                                    child: Row(children: [
                                      Icon(Icons.arrow_downward_outlined,
                                          size: 14),
                                      SizedBox(width: 8),
                                      Text('Nach unten'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'verschieben',
                                    child: Row(children: [
                                      Icon(Icons.drive_file_move_outlined,
                                          size: 14),
                                      SizedBox(width: 8),
                                      Text('Verschieben'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'loeschen',
                                    child: Row(children: [
                                      Icon(Icons.delete_outlined,
                                          size: 14, color: AppColors.error),
                                      SizedBox(width: 8),
                                      Text('Löschen',
                                          style: TextStyle(
                                              color: AppColors.error)),
                                    ]),
                                  ),
                                ],
                                onSelected: (v) async {
                                  if (v == 'messungen') {
                                    _showMessungenSheet(context, k);
                                  } else if (v == 'bearbeiten') {
                                    widget.onEditKomponente(k);
                                  } else if (v == 'add_child') {
                                    widget.onAddChild(k.uuid);
                                  } else if (v == 'messung') {
                                    Map<String, dynamic>? props;
                                    if (k.eigenschaftenJson != null) {
                                      try {
                                        props = jsonDecode(k.eigenschaftenJson!)
                                            as Map<String, dynamic>;
                                      } catch (_) {}
                                    }
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor:
                                          AppColors.surfaceContainerLowest,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      builder: (_) => MessungFormular(
                                        komponenteUuid: k.uuid,
                                        komponenteTyp: k.typ,
                                        komponenteEigenschaften: props,
                                      ),
                                    );
                                  } else if (v == 'nach_oben') {
                                    await _moveKomponente(ref, k, -1,
                                        widget.allKomponenten);
                                  } else if (v == 'nach_unten') {
                                    await _moveKomponente(ref, k, 1,
                                        widget.allKomponenten);
                                  } else if (v == 'verschieben') {
                                    _showVerschiebenDialog(context, k);
                                  } else if (v == 'loeschen') {
                                    _showLoeschenDialog(context, k);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Children ───────────────────────────────────────────────────
          if (hasChildren && _expanded)
            ...children.map((child) => _KomponentenNode(
                  key: ValueKey(child.uuid),
                  komponente: child,
                  allKomponenten: widget.allKomponenten,
                  depth: widget.depth + 1,
                  verteilerUuid: widget.verteilerUuid,
                  onAddChild: widget.onAddChild,
                  onEditKomponente: widget.onEditKomponente,
                  isLast: child == children.last,
                  initialExpanded: widget.initialExpanded,
                )),
        ],
      ),
    );
  }
}

// ── Type Icon ─────────────────────────────────────────────────────────────────

class _TypIcon extends StatelessWidget {
  const _TypIcon({required this.typ});

  final String typ;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (typ) {
      case 'hauptschalter':
        icon = Icons.corporate_fare;
        color = AppColors.primary;
      case 'rcd':
        icon = Icons.electrical_services;
        color = AppColors.secondary;
      case 'ls_schalter':
        icon = Icons.power;
        color = AppColors.secondary;
      case 'fi_ls':
        icon = Icons.power;
        color = AppColors.warning;
      case 'vorsicherung':
        icon = Icons.flash_on;
        color = AppColors.warning;
      case 'nh_sicherung':
        icon = Icons.flash_on;
        color = AppColors.error;
      case 'neozed':
        icon = Icons.bolt;
        color = AppColors.error;
      case 'diazed':
        icon = Icons.bolt;
        color = AppColors.warning;
      case 'ueberspannung':
        icon = Icons.shield_outlined;
        color = AppColors.tertiary;
      case 'sammelschiene':
        icon = Icons.linear_scale;
        color = AppColors.onSurfaceVariant;
      default:
        icon = Icons.settings_outlined;
        color = AppColors.onSurfaceVariant;
    }

    return Icon(icon, size: 18, color: color);
  }
}

// ── Technical Data ────────────────────────────────────────────────────────────

class _TechnischeDaten extends StatelessWidget {
  const _TechnischeDaten({required this.k});

  final VerteilerKomponente k;

  @override
  Widget build(BuildContext context) {
    if (k.eigenschaftenJson == null) return const SizedBox.shrink();

    try {
      final data = jsonDecode(k.eigenschaftenJson!) as Map<String, dynamic>;
      final parts = <String>[];

      if (data['nennstrom'] != null) {
        parts.add('${data['nennstrom']} A');
      }
      if (data['pole'] != null) {
        parts.add('${data['pole']}-polig');
      }
      if (data['charakteristik'] != null) {
        parts.add('Char. ${data['charakteristik']}');
      }
      if (data['auslösestrom'] != null) {
        parts.add('I∆n ${data['auslösestrom']} mA');
      }

      if (parts.isEmpty) return const SizedBox.shrink();

      return Text(
        parts.join(' · '),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.onSurfaceVariant,
          height: 1.4,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
