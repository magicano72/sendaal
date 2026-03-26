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
    late final Color color;
    late final String label;
    switch (status) {
      case AccessStatus.pending:
        color = Colors.orange;
        label = 'PENDING';
        break;
      case AccessStatus.approved:
        color = Colors.green;
        label = 'APPROVED';
        break;
      case AccessStatus.rejected:
        color = Colors.red;
        label = 'REJECTED';
        break;
      case AccessStatus.cancelled:
        color = Colors.redAccent;
        label = 'CANCELLED';
        break;
      case AccessStatus.revoked:
      case AccessStatus.revokedByReceiver:
      case AccessStatus.revokedByRequester:
        color = Colors.redAccent;
        label = 'REVOKED';
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
        label,
        style: TextStyles.captionBold.copyWith(color: color, fontSize: 12.sp),
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
      case AccessStatus.cancelled:
        bannerColor = AppTheme.error;
        message = 'Request cancelled.';
        break;
      case AccessStatus.revoked:
      case AccessStatus.revokedByReceiver:
      case AccessStatus.revokedByRequester:
        bannerColor = AppTheme.error;
        message = 'Access revoked';
        break;
      default:
        bannerColor = AppTheme.accent;
        message = 'Unknown status.';
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
