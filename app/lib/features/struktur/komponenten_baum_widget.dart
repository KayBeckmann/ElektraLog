import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/verteiler_komponente.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../core/providers/messungen_provider.dart';
import '../../features/messungen/messung_formular.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/status_pill.dart';

class KomponentenBaumWidget extends ConsumerWidget {
  const KomponentenBaumWidget({
    super.key,
    required this.verteilerUuid,
    required this.onAddKomponente,
  });

  final String verteilerUuid;
  final void Function(String? parentUuid) onAddKomponente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final komponentenAsync =
        ref.watch(komponentenByVerteilerProvider(verteilerUuid));

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
                  onPressed: () => onAddKomponente(null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Erste Komponente hinzufügen'),
                ),
              ],
            ),
          );
        }

        // Build tree from flat list
        final roots =
            komponenten.where((k) => k.parentUuid == null).toList();
        roots.sort((a, b) => a.position.compareTo(b.position));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...roots.map((root) => _KomponentenNode(
                  komponente: root,
                  allKomponenten: komponenten,
                  depth: 0,
                  onAddChild: onAddKomponente,
                  isLast: root == roots.last,
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => onAddKomponente(null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Wurzel-Element hinzufügen'),
            ),
          ],
        );
      },
    );
  }
}

// ── Node Widget ───────────────────────────────────────────────────────────────

class _KomponentenNode extends ConsumerStatefulWidget {
  const _KomponentenNode({
    required this.komponente,
    required this.allKomponenten,
    required this.depth,
    required this.onAddChild,
    required this.isLast,
  });

  final VerteilerKomponente komponente;
  final List<VerteilerKomponente> allKomponenten;
  final int depth;
  final void Function(String? parentUuid) onAddChild;
  final bool isLast;

  @override
  ConsumerState<_KomponentenNode> createState() => _KomponentenNodeState();
}

class _KomponentenNodeState extends ConsumerState<_KomponentenNode> {
  bool _expanded = true;

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

                              // Name + technical data
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      k.bezeichnung,
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
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'add_child',
                                    child: Row(children: [
                                      const Icon(Icons.add, size: 14),
                                      const SizedBox(width: 8),
                                      const Text('Unterkomponente'),
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'messung',
                                    child: Row(children: [
                                      Icon(Icons.science_outlined,
                                          size: 14),
                                      SizedBox(width: 8),
                                      Text('Messung hinzufügen'),
                                    ]),
                                  ),
                                ],
                                onSelected: (v) {
                                  if (v == 'add_child') {
                                    widget.onAddChild(k.uuid);
                                  } else if (v == 'messung') {
                                    // Eigenschaften parsen für Formular-Vorbelgung
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
                  komponente: child,
                  allKomponenten: widget.allKomponenten,
                  depth: widget.depth + 1,
                  onAddChild: widget.onAddChild,
                  isLast: child == children.last,
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
