import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum PillStatus { passed, failed, offen, inBearbeitung }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final PillStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case PillStatus.passed:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        icon = Icons.check_circle_outline;
        label = 'PASSED';
      case PillStatus.failed:
        bg = AppColors.errorContainer;
        fg = AppColors.error;
        icon = Icons.error_outline;
        label = 'FAILED';
      case PillStatus.offen:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.onSurfaceVariant;
        icon = Icons.pending_outlined;
        label = 'OFFEN';
      case PillStatus.inBearbeitung:
        bg = AppColors.secondaryContainer;
        fg = AppColors.secondary;
        icon = Icons.pending_outlined;
        label = 'IN BEARBEITUNG';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.05 * 11,
            ),
          ),
        ],
      ),
    );
  }
}
