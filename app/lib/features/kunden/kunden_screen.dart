import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

class KundenScreen extends StatelessWidget {
  const KundenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kunden'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kunden',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kundenliste als Cards mit Suche und Filter — kommt in Phase 1.',
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
