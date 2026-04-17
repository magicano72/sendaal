import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../models/policy_model.dart';
import '../../services/api_client.dart';
import '../../services/policy_service.dart';

/// Displays a policy document (Privacy Policy, Terms, About, etc.)
///
/// Navigated with: Navigator.pushNamed(context, AppRoutes.policyDetails, arguments: policyType)
/// where policyType is one of: 'privacy', 'terms', 'about'
class PolicyDetailsScreen extends StatefulWidget {
  /// Policy type: 'privacy', 'terms', or 'about'
  final String policyType;

  const PolicyDetailsScreen({super.key, required this.policyType});

  @override
  State<PolicyDetailsScreen> createState() => _PolicyDetailsScreenState();
}

class _PolicyDetailsScreenState extends State<PolicyDetailsScreen> {
  late final PolicyService _policyService;
  Future<PolicyModel?>? _policyFuture;

  @override
  void initState() {
    super.initState();
    _policyService = PolicyService();
    _loadPolicy();
  }

  void _loadPolicy() {
    setState(() {
      _policyFuture = _policyService.getPolicyByType(widget.policyType);
    });
  }

  String _getPolicyTitle() {
    switch (widget.policyType) {
      case 'privacy':
        return 'Privacy Policy';
      case 'terms':
        return 'Terms & Conditions';
      case 'about':
        return 'About';
      default:
        return 'Policy';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPolicyTitle()),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<PolicyModel?>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final errorMessage = error is ApiException
                ? error.message
                : 'Failed to load policy. Please try again.';

            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64.sp,
                      color: AppTheme.error,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error',
                      style: TextStyles.bodyBold.copyWith(
                        fontSize: 18.sp,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: _loadPolicy,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final policy = snapshot.data;
          if (policy == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64.sp,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No policy found',
                      style: TextStyles.bodyBold.copyWith(
                        fontSize: 18.sp,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'The ${_getPolicyTitle().toLowerCase()} is not available at the moment.',
                      textAlign: TextAlign.center,
                      style: TextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Policy title
                Text(
                  policy.title,
                  style: TextStyles.bodyBold.copyWith(
                    fontSize: 20.sp,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12.h),

                // Last updated date (if available)
                if (policy.updatedAt != null)
                  Text(
                    'Last updated: ${_formatDate(policy.updatedAt!)}',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),

                SizedBox(height: 24.h),

                // HTML content
                Html(
                  data: policy.content,
                  style: {
                    'p': Style(
                      fontSize: FontSize(14.sp),
                      color: AppTheme.textPrimary,
                      lineHeight: LineHeight.number(1.5),
                      margin: Margins.symmetric(vertical: 8.h),
                    ),
                    'body': Style(
                      fontSize: FontSize(14.sp),
                      color: AppTheme.textPrimary,
                    ),
                    'h1': Style(
                      fontSize: FontSize(20.sp),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      margin: Margins.symmetric(vertical: 12.h),
                    ),
                    'h2': Style(
                      fontSize: FontSize(18.sp),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      margin: Margins.symmetric(vertical: 10.h),
                    ),
                    'h3': Style(
                      fontSize: FontSize(16.sp),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      margin: Margins.symmetric(vertical: 8.h),
                    ),
                    'h4': Style(
                      fontSize: FontSize(15.sp),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      margin: Margins.symmetric(vertical: 8.h),
                    ),
                    'h5': Style(
                      fontSize: FontSize(14.5.sp),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      margin: Margins.symmetric(vertical: 6.h),
                    ),
                    'h6': Style(
                      fontSize: FontSize(14.sp),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      margin: Margins.symmetric(vertical: 6.h),
                    ),
                    'li': Style(
                      fontSize: FontSize(14.sp),
                      color: AppTheme.textPrimary,
                      margin: Margins.symmetric(vertical: 4.h),
                    ),
                    'ul': Style(margin: Margins.symmetric(vertical: 8.h)),
                    'ol': Style(margin: Margins.symmetric(vertical: 8.h)),
                    'a': Style(
                      color: AppTheme.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                    'strong': Style(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    'em': Style(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textPrimary,
                    ),
                  },
                ),

                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
