import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

class HistorieScreen extends StatelessWidget {
  const HistorieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historie',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Messungs-Verlauf mit Datum und Ergebnissen — kommt in Phase 1.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
