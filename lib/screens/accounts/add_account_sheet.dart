import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../widgets/app_widgets.dart';
import 'account_form_screen.dart';

/// Lightweight bottom sheet that routes users to the full cascading add flow.
class AddAccountSheet extends ConsumerWidget {
  const AddAccountSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Add Financial Account',
            style: TextStyles.bodyBold.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'The add flow now uses a 4-step country → account type → provider → '
            'currency selector with an auto-fetched limit. Continue to open the full form.',
            style: TextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 22.h),
          PrimaryButton(
            label: 'Open Form',
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const AccountFormScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
