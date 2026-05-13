import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/messungen_provider.dart';
import '../../shared/theme/app_colors.dart';

class SignaturScreen extends ConsumerStatefulWidget {
  const SignaturScreen({super.key});

  @override
  ConsumerState<SignaturScreen> createState() => _SignaturScreenState();
}

class _SignaturScreenState extends ConsumerState<SignaturScreen> {
  final _prueferCtrl = TextEditingController();
  final _ortCtrl = TextEditingController();
  final List<Offset?> _points = [];

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _ortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messungenAsync = ref.watch(alleMessungenProvider);

    final total = messungenAsync.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final bestanden = messungenAsync.when(
      data: (list) =>
          list.where((m) => m.ergebnis == 'bestanden').length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final maengel = messungenAsync.when(
      data: (list) =>
          list.where((m) => m.ergebnis == 'nicht_bestanden').length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ───────────────────────────────────────────────
            Text(
              'SIGNATUR',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.08 * 12,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Protokoll abschließen',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 20),

            // ── Status Banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: total > 0
                    ? AppColors.successContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      total > 0 ? AppColors.success : AppColors.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    total > 0
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color:
                        total > 0 ? AppColors.success : AppColors.outline,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    total > 0
                        ? '$total Messungen erfasst'
                        : 'Noch keine Messungen vorhanden',
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: total > 0
                                  ? AppColors.success
                                  : AppColors.onSurfaceVariant,
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Bento-Grid Zusammenfassung ────────────────────────────────
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isDesktop = constraints.maxWidth >= 600;
                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(child: _StatCard(total: total)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _ErgebnisCard(
                        bestanden: bestanden,
                        maengel: maengel,
                      )),
                    ],
                  );
                }
                return Column(
                  children: [
                    _StatCard(total: total),
                    const SizedBox(height: 16),
                    _ErgebnisCard(
                        bestanden: bestanden, maengel: maengel),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // ── Prüfer + Ort ──────────────────────────────────────────────
            _BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Angaben zur Prüfung',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _prueferCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prüfer Name',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                    ),
                    minLines: 1,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ort',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          size: 18),
                    ),
                    minLines: 1,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Unterschriften-Pad ────────────────────────────────────────
            _BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Unterschrift',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _points.clear()),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Löschen'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() => _points
                              .add(details.localPosition));
                        },
                        onPanUpdate: (details) {
                          setState(() => _points
                              .add(details.localPosition));
                        },
                        onPanEnd: (_) {
                          setState(() => _points.add(null));
                        },
                        child: CustomPaint(
                          painter:
                              _SignaturePainter(points: _points),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '─────────────────────',
                      style: TextStyle(
                        color: AppColors.outlineVariant,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Unterschrift Prüfer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── PDF Button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onPdfButton,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text(
                    'Protokoll abschließen und PDF generieren'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPdfButton() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('PDF-Export kommt in Phase 2'),
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.inversePrimary,
          onPressed: () {},
        ),
      ),
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GESAMT',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.primary,
                  fontSize: 40,
                ),
          ),
          Text(
            'Messungen',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErgebnisCard extends StatelessWidget {
  const _ErgebnisCard(
      {required this.bestanden, required this.maengel});

  final int bestanden;
  final int maengel;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ERGEBNISSE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                '$bestanden bestanden',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                '$maengel Mängel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: child,
    );
  }
}

// ── Signature Painter ─────────────────────────────────────────────────────────

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.points});

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Dashed baseline
    final baselinePaint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dashWidth = 8.0;
    const dashGap = 4.0;
    final baselineY = size.height * 0.75;
    double x = 8;
    while (x < size.width - 8) {
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(
            (x + dashWidth).clamp(0.0, size.width - 8), baselineY),
        baselinePaint,
      );
      x += dashWidth + dashGap;
    }

    // Signature
    final signPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, signPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
