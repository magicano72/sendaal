import 'package:flutter/material.dart';
import 'package:sendaal/models/access_request_model.dart';

import '../../core/theme/app_theme.dart' show AppTheme;

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
        bannerColor = AppTheme.warning;
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
          ),
          const SizedBox(width: 10),
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
