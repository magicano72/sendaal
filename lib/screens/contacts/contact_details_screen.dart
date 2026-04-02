import 'package:Sendaal/widgets/account_card.dart' show AccountCard;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/access_request_model.dart';
import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../providers/account_provider.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../requests/status_banar.dart';

class ContactDetailsScreen extends ConsumerWidget {
  final User contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final latestRequestAsync = currentUser == null
        ? const AsyncValue<AccessRequest?>.data(null)
        : ref.watch(
            latestRequestBetweenProvider((currentUser.id, contact.id)),
          );
    final accountsAsync = ref.watch(approvedAccountsProvider(contact.id));

    return Scaffold(
      appBar: AppBar(title: Text(contact.displayName)),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildHeader(),
          SizedBox(height: 16.h),
          _buildContactInfoCard(),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Send Money',
                  onPressed: () => _openRecipient(context),
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () => _openRecipient(context),
                  child: Text(
                    'Split Payment',
                    style: TextStyles.bodySmallBold.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'Approved accounts',
            style: TextStyles.bodySmallBold.copyWith(
              fontSize: 15.sp,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorBanner(
              message: 'Could not load accounts: $e',
              onRetry: () => ref.refresh(approvedAccountsProvider(contact.id)),
            ),
            data: (result) {
              final latest = latestRequestAsync.value;
              final isRevoked = latest?.isRevoked == true;
              final isRevoker =
                  isRevoked && latest?.revokerId == currentUser?.id;

              if (isRevoked) {
                return _buildAccessDeniedCard(isRevoker);
              }

              if (!result.hasAccess) {
                return _buildAccessNotApproved();
              }

              final visible = result.accounts
                  .where((a) => a.isVisible)
                  .toList();
              if (visible.isEmpty) {
                return const EmptyState(
                  icon: Icons.account_balance_outlined,
                  title: 'No visible accounts',
                  subtitle: 'This contact has no visible accounts right now.',
                );
              }
              return Column(
                children: visible
                    .map(
                      (a) => AccountCard(
                        account: a,
                        dense: true,
                        onTap: () => _openRecipient(context),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final avatarUrl = contact.avatarUrl;
    final subtitle = contact.phoneNumber?.isNotEmpty == true
        ? contact.phoneNumber!
        : '@${contact.username}';
    final title = (contact.firstName?.isNotEmpty ?? false)
        ? contact.firstName!
        : (contact.displayName.isNotEmpty
              ? contact.displayName
              : contact.username);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28.r,
              backgroundColor: AppTheme.primary.withOpacity(0.12),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      contact.initials,
                      style: TextStyles.bodyBold.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodySmallBold.copyWith(fontSize: 16.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyles.label.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecipient(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.recipient, arguments: contact);
  }

  Widget _buildContactInfoCard() {
    final phone = contact.phoneNumber ?? '';
    final fullName = contact.firstName?.isNotEmpty == true
        ? contact.firstName!
        : (contact.displayName.isNotEmpty
              ? contact.displayName
              : contact.username);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact details',
              style: TextStyles.bodySmallBold.copyWith(
                fontSize: 14.sp,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _infoRow('Full name', fullName),
            SizedBox(height: 8.h),
            _infoRow('Username', '@${contact.username}'),
            if (phone.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _infoRow('Phone', phone),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedCard(bool isRevoker) {
    return Column(
      children: [
        StatusBanner(status: AccessStatus.revoked),
        SizedBox(height: 10.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.block, color: Colors.redAccent, size: 20.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    isRevoker
                        ? 'You revoked access for this contact. Cancel revoke from the requests screen to restore visibility.'
                        : 'Access to this contact is revoked. No data is available.',
                    style: TextStyles.label.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessNotApproved() {
    return const EmptyState(
      icon: Icons.lock_outline,
      title: 'Access not approved',
      subtitle: 'You can view accounts once an access request is approved.',
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyles.captionMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyles.labelBold.copyWith(color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
