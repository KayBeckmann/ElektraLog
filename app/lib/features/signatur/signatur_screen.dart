import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

class SignaturScreen extends StatelessWidget {
  const SignaturScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Signatur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signatur',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Abschluss und PDF-Generierung mit Unterschriften-Pad — kommt in Phase 1.',
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
