import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_widgets.dart';

class TransferSuccessScreen extends ConsumerWidget {
  const TransferSuccessScreen({super.key});

  void _goHome(BuildContext context, WidgetRef ref) {
    // Clear search state so home shows the default requests view
    ref.read(searchProvider.notifier).clear();

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Complete'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 88.r, color: AppTheme.success),
            SizedBox(height: 18.h),
            Text(
              'Transfer instructions generated',
              style: TextStyles.h2Medium.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'You can now complete payments in your apps.\nTap below to return home.',
              style: TextStyles.bodySmall
                  .copyWith(color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
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
