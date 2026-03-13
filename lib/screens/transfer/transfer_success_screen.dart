import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_widgets.dart';

class TransferSuccessScreen extends ConsumerWidget {
  const TransferSuccessScreen({super.key});

  void _goHome(BuildContext context, WidgetRef ref) {
    // Clear search state so home shows the default requests view
    ref.read(searchProvider.notifier).clear();

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Complete'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 88, color: AppTheme.success),
            const SizedBox(height: 18),
            const Text(
              'Transfer instructions generated',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You can now complete payments in your apps.\nTap below to return home.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () => _goHome(context, ref),
              backgroundColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
