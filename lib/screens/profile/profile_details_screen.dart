import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../providers/auth_provider.dart';

class ProfileDetailsScreen extends ConsumerWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Detail'), centerTitle: true),
      body: user == null
          ? const Center(child: Text('No user details available.'))
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              children: [
                _DetailCard(
                  title: 'Full Name',
                  value: _fullName(user.firstName, user.displayName),
                ),
                _DetailCard(title: 'Username', value: '@${user.username}'),
                _DetailCard(
                  title: 'Email',
                  value: _valueOrFallback(user.email),
                ),
                _DetailCard(
                  title: 'Phone Number',
                  value: _valueOrFallback(user.phoneNumber),
                ),
              ],
            ),
    );
  }

  String _fullName(String? firstName, String displayName) {
    final primary = firstName?.trim();
    if (primary != null && primary.isNotEmpty) {
      return primary;
    }

    final fallback = displayName.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Not provided';
  }

  String _valueOrFallback(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return 'Not provided';
    }
    return cleaned;
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;

  const _DetailCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyles.bodyBold.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 15.sp,
            ),
          ),
        ],
      ),
    );
  }
}
