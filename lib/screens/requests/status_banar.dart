import 'package:Sendaal/models/access_request_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart' show AppTheme;
import '../../core/theme/text_style.dart';

class StatusChip extends StatelessWidget {
  final AccessStatus status;

  const StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case AccessStatus.pending:
        color = Colors.orange;
        break;
      case AccessStatus.approved:
        color = Colors.green;
        break;
      case AccessStatus.rejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyles.captionBold.copyWith(
          color: color,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

class StatusBanner extends StatelessWidget {
  final AccessStatus status;

  const StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bannerColor;
    String message;

    switch (status) {
      case AccessStatus.pending:
        bannerColor = AppTheme.accent;
        message = 'Waiting for approval...';
        break;
      case AccessStatus.approved:
        bannerColor = AppTheme.success;
        message = 'Access granted.';
        break;
      case AccessStatus.rejected:
        bannerColor = AppTheme.error;
        message = 'Request rejected.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: bannerColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            status == AccessStatus.approved
                ? Icons.verified_outlined
                : status == AccessStatus.pending
                ? Icons.hourglass_bottom_outlined
                : Icons.block_outlined,
            color: bannerColor,
            size: 20.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: bannerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
