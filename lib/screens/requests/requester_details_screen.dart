import 'package:Sendaal/screens/requests/status_banar.dart';
import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../models/access_request_account_model.dart';
import '../../models/access_request_model.dart';
import '../../models/financial_account_model.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/country_flag_icon.dart';
import '../../widgets/provider_logo.dart';

enum _ActionType { approve, reject }

/// Displays full requester details fetched by ID, with status actions.
class RequesterDetailsScreen extends ConsumerStatefulWidget {
  final AccessRequest request;

  const RequesterDetailsScreen({super.key, required this.request});

  @override
  ConsumerState<RequesterDetailsScreen> createState() =>
      _RequesterDetailsScreenState();
}

class _RequesterDetailsScreenState
    extends ConsumerState<RequesterDetailsScreen> {
  bool _isProcessing = false;
  _ActionType? _pendingAction;
  AccessStatus? _localStatus;
  String? _localApprovedAccessType;
  String _receiverAccessType = 'full';
  final Set<String> _receiverSelectedAccounts = {};
  List<AccessRequestAccount> _requesterSharedAccounts = [];
  List<AccessRequestAccount> _receiverSharedAccounts = [];
  bool _accountsLoading = false;
  String? _accountsError;

  AccessRequest get _request => widget.request.copyWith(
    status: _localStatus ?? widget.request.status,
    approvedAccessType:
        _localApprovedAccessType ?? widget.request.approvedAccessType,
  );

  @override
  void initState() {
    super.initState();
    _receiverAccessType = widget.request.approvedAccessType ?? 'full';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null && currentUser.id == widget.request.receiverId) {
      await ref.read(accountsProvider.notifier).loadAccounts(currentUser.id);
    }
    await _fetchRequestAccounts();
  }

  Future<void> _fetchRequestAccounts() async {
    setState(() {
      _accountsLoading = true;
      _accountsError = null;
    });

    try {
      final notifier = ref.read(accessRequestProvider.notifier);
      if (_request.requestAccessType == 'custom') {
        _requesterSharedAccounts = await notifier.getRequestAccounts(
          requestId: _request.id,
          side: 'requester',
        );
      } else {
        _requesterSharedAccounts = [];
      }

      if (_request.status == AccessStatus.approved &&
          _request.approvedAccessType == 'custom') {
        _receiverSharedAccounts = await notifier.getRequestAccounts(
          requestId: _request.id,
          side: 'receiver',
        );
      } else {
        _receiverSharedAccounts = [];
      }
    } catch (e) {
      _accountsError = 'Unable to load shared accounts';
    } finally {
      if (mounted) {
        setState(() => _accountsLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isReceiver = currentUser?.id == _request.receiverId;
    final isRequester = currentUser?.id == _request.requesterId;
    final profileUserId = isRequester
        ? _request.receiverId
        : _request.requesterId;
    final accountsState = ref.watch(accountsProvider);
    final userAsync = ref.watch(userProvider(profileUserId));

    final isRevoked = _request.isRevoked;
    final isRevoker =
        _request.revokerId != null && _request.revokerId == currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Access Request'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: Center(child: StatusChip(status: _request.status)),
          ),
        ],
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Padding(
            padding: EdgeInsets.all(20.w),
            child: ErrorBanner(
              message: 'Unable to load requester details.',
              onRetry: () => ref.refresh(userProvider(profileUserId)),
            ),
          ),
          data: (user) => RefreshIndicator(
            onRefresh: () async {
              await _fetchRequestAccounts();
              final me = ref.read(authProvider).user;
              if (me != null && me.id == _request.receiverId) {
                await ref.read(accountsProvider.notifier).loadAccounts(me.id);
              }
            },
            child: _buildBody(
              context,
              user,
              accountsState,
              isReceiver: isReceiver,
              isRevoked: isRevoked,
              isRevoker: isRevoker,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    User user,
    AccountsState accountsState, {
    required bool isReceiver,
    required bool isRevoked,
    required bool isRevoker,
  }) {
    if (isRevoked) {
      return _buildRevokedBody(context, user, isRevoker: isRevoker);
    }

    final canAct = isReceiver && _request.status == AccessStatus.pending;
    final otherName = _displayName(user);

    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        _buildProfileHeader(user),
        SizedBox(height: 12.h),
        StatusBanner(status: _request.status),
        SizedBox(height: 12.h),
        _buildRequestSummary(otherName),
        if (_request.requestAccessType == 'custom') ...[
          SizedBox(height: 12.h),
          _buildRequesterAccountsSection(otherName, isReceiver: isReceiver),
        ],
        if (canAct) ...[
          SizedBox(height: 8.h),
          _buildReceiverResponse(accountsState),
        ],
        if (_request.status == AccessStatus.approved) ...[
          SizedBox(height: 8.h),
          _buildSharedSections(otherUserName: _displayName(user)),
        ],
        if (_request.status == AccessStatus.rejected) ...[
          SizedBox(height: 8.h),
          Text(
            'This request was rejected.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(height: 12.h),
        Text(
          'Only information you are allowed to see is shown here.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRevokedBody(
    BuildContext context,
    User user, {
    required bool isRevoker,
  }) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        _buildRevokedProfileHeader(user),
        SizedBox(height: 12.h),
        StatusBanner(status: _request.status),
        SizedBox(height: 12.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  isRevoker
                      ? 'You revoked access for this user. Cancel revoke to restore full visibility.'
                      : 'This connection has been revoked. You cannot view any data for this user.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (isRevoker) ...[
          SizedBox(height: 14.h),
          FilledButton(
            onPressed: _isProcessing ? null : _handleCancelRevoke,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: AppTheme.primary,
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 18.r,
                    width: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Cancel Revoke'),
          ),
        ],
      ],
    );
  }

  Widget _buildRevokedProfileHeader(User user) {
    final name = _displayName(user);
    final avatarUrl = user.avatarUrl;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36.r,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    final name = _displayName(user);
    final avatarUrl = user.avatarUrl;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final phone = (user.phoneNumber ?? '').trim();
    final email = (user.email ?? '').trim();

    Widget infoRow(IconData icon, String value) => Row(
      children: [
        Icon(icon, size: 18.r, color: AppTheme.primary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'Not provided',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40.r,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 10.h),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4.h),
            Text(
              '@${user.username}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            infoRow(Icons.phone_outlined, phone),
            SizedBox(height: 6.h),
            infoRow(Icons.email_outlined, email),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSummary(String otherName) {
    final isCustom = _request.requestAccessType == 'custom';
    final chipColor = isCustom ? Colors.orange.shade50 : Colors.green.shade50;
    final chipTextColor = isCustom
        ? Colors.orange.shade800
        : Colors.green.shade800;

    return SizedBox(height: 2.h);
  }

  Widget _buildRequesterAccountsSection(
    String otherName, {
    required bool isReceiver,
  }) {
    if (_accountsLoading && _requesterSharedAccounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_accountsError != null) {
      return Text(
        _accountsError!,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.red),
      );
    }

    if (_requesterSharedAccounts.isEmpty) {
      final requesterName = isReceiver ? otherName : 'You';
      final verb = isReceiver ? 'hasn\'t' : 'haven\'t';
      return Text(
        '$requesterName $verb attached any accounts yet.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SizedBox(height: 2.h)],
    );
  }

  Widget _buildReceiverResponse(AccountsState accountsState) {
    final needsSelection = _receiverAccessType == 'custom';
    final disableApprove =
        _isProcessing ||
        (_receiverAccessType == 'custom' && _receiverSelectedAccounts.isEmpty);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your response',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10.h),
            _receiverAccessChips(),
            if (needsSelection) ...[
              SizedBox(height: 10.h),
              _buildReceiverAccountSelection(accountsState),
            ],
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleAction(approve: false),
                    icon: _pendingAction == _ActionType.reject && _isProcessing
                        ? SizedBox(
                            width: 14.w,
                            height: 14.w,
                            child: CircularProgressIndicator(strokeWidth: 2.w),
                          )
                        : Icon(Icons.close, size: 18.r),
                    label: Text(
                      _pendingAction == _ActionType.reject && _isProcessing
                          ? 'Rejecting...'
                          : 'Reject',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: disableApprove
                        ? null
                        : () => _handleAction(approve: true),
                    icon: _pendingAction == _ActionType.approve && _isProcessing
                        ? SizedBox(
                            width: 14.w,
                            height: 14.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.check, size: 18.r),
                    label: Text(
                      _pendingAction == _ActionType.approve && _isProcessing
                          ? 'Approving...'
                          : 'Approve',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiverAccessChips() {
    Widget card(
      String label,
      String value,
      String subtitle,
      IconData icon,
      double width,
    ) {
      final selected = _receiverAccessType == value;
      final bg = selected ? AppTheme.primary : Colors.white;
      final fg = selected ? Colors.white : AppTheme.textPrimary;
      final subFg = selected
          ? Colors.white.withOpacity(0.9)
          : AppTheme.textSecondary;
      return SizedBox(
        width: width,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () {
            setState(() {
              _receiverAccessType = value;
              if (value == 'full') _receiverSelectedAccounts.clear();
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: selected ? AppTheme.primary : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.18)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    size: 18.r,
                    color: selected ? Colors.white : AppTheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: subFg),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18.r,
                  color: selected ? Colors.white : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.w;
        final isNarrow = constraints.maxWidth < 360;
        final cardWidth = isNarrow
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: 12.h,
          children: [
            card(
              'Full Access',
              'full',
              'Share all your accounts',
              Icons.all_inclusive,
              cardWidth,
            ),
            card(
              'Custom',
              'custom',
              'Pick specific accounts',
              Icons.tune,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiverAccountSelection(AccountsState accountsState) {
    if (accountsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (accountsState.error != null) {
      return Text(
        accountsState.error!,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.red),
      );
    }

    if (accountsState.accounts.isEmpty) {
      return Text(
        'You have no accounts to share yet.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select accounts to share',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        ...accountsState.accounts.map((a) => _receiverAccountTile(a)).toList(),
        if (_receiverSelectedAccounts.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              'Pick at least one account.',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _receiverAccountTile(FinancialAccount account) {
    final selected = _receiverSelectedAccounts.contains(account.id);
    final title = account.accountTitle.isNotEmpty
        ? account.accountTitle
        : account.providerName;

    return InkWell(
      onTap: () => _toggleReceiverAccount(account.id),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProviderLogo(
              logoUuid: account.providerLogo,
              providerName: account.providerName,
              size: 44.w,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      CountryFlagIcon(
                        countryCode: account.countryCode,
                        size: 18.w,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        account.providerName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          account.accountTypeName.isNotEmpty
                              ? account.accountTypeName
                              : account.type.name,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (account.accountIdentifier.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      account.accountIdentifier,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => _toggleReceiverAccount(account.id),
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedSections({required String otherUserName}) {
    final receiverAccessType =
        _request.approvedAccessType ?? _receiverAccessType;
    final currentUser = ref.read(authProvider).user;
    final isRequester = currentUser?.id == _request.requesterId;
    final requesterTitle = isRequester
        ? 'Shared by you'
        : 'Shared by $otherUserName';
    final receiverTitle = isRequester
        ? 'Shared by $otherUserName'
        : 'Shared by you';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shared accounts',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10.h),
        _buildSharedSection(
          title: requesterTitle,
          accessType: _request.requestAccessType,
          accounts: _request.requestAccessType == 'custom'
              ? _requesterSharedAccounts
              : const [],
          loading: _accountsLoading && _request.requestAccessType == 'custom',
        ),
        SizedBox(height: 12.h),
        _buildSharedSection(
          title: receiverTitle,
          accessType: receiverAccessType,
          accounts: receiverAccessType == 'custom'
              ? _receiverSharedAccounts
              : const [],
          loading: _accountsLoading && receiverAccessType == 'custom',
        ),
      ],
    );
  }

  Widget _buildSharedSection({
    required String title,
    required String accessType,
    required List<AccessRequestAccount> accounts,
    required bool loading,
  }) {
    final isFull = accessType == 'full';
    final chipColor = isFull ? Colors.green.shade50 : Colors.orange.shade50;
    final chipTextColor = isFull
        ? Colors.green.shade800
        : Colors.orange.shade800;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (isFull)
              Text(
                'Full access to all accounts.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              )
            else if (accounts.isEmpty)
              Text(
                'No accounts shared yet.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              )
            else
              ...accounts
                  .map((a) => _sharedAccountTile(a.financialAccount))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _sharedAccountTile(FinancialAccount account) {
    final title = account.accountTitle.isNotEmpty
        ? account.accountTitle
        : account.providerName;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ProviderLogo(
            logoUuid: account.providerLogo,
            providerName: account.providerName,
            size: 44.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    CountryFlagIcon(
                      countryCode: account.countryCode,
                      size: 18.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      account.providerName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        account.accountTypeName.isNotEmpty
                            ? account.accountTypeName
                            : account.type.name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (account.accountIdentifier.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    account.accountIdentifier,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelRevoke() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final updated = await ref
        .read(accessRequestProvider.notifier)
        .cancelRevoke(_request.id);

    if (!mounted) return;

    if (updated != null) {
      setState(() {
        _localStatus = updated.status;
        _localApprovedAccessType = updated.approvedAccessType;
        _isProcessing = false;
      });

      await _fetchRequestAccounts();

      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        await Future.wait([
          ref.read(accessRequestProvider.notifier).loadReceivedRequests(
                currentUser.id,
              ),
          ref.read(accessRequestProvider.notifier).loadSentRequests(
                currentUser.id,
              ),
        ]);
      }

      if (!mounted) return;
      AppSnackBar.success(context, 'Access restored.');
      ref.invalidate(
        latestRequestBetweenProvider((
          _request.requesterId,
          _request.receiverId,
        )),
      );
    } else {
      final msg =
          ref.read(accessRequestProvider).error ?? 'Unable to cancel revoke';
      setState(() => _isProcessing = false);
      AppSnackBar.error(context, msg);
    }
  }

  Future<void> _handleAction({required bool approve}) async {
    if (_isProcessing) return;

    if (approve &&
        _receiverAccessType == 'custom' &&
        _receiverSelectedAccounts.isEmpty) {
      AppSnackBar.warning(
        context,
        'Please select at least one account to approve with custom access.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _pendingAction = approve ? _ActionType.approve : _ActionType.reject;
    });

    final notifier = ref.read(accessRequestProvider.notifier);
    final success = approve
        ? await notifier.approveRequest(
            _request.id,
            approvedAccessType: _receiverAccessType,
            selectedAccountIds: _receiverAccessType == 'custom'
                ? _receiverSelectedAccounts.toList()
                : const [],
          )
        : await notifier.rejectRequest(_request.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _localStatus = approve ? AccessStatus.approved : AccessStatus.rejected;
        if (approve) _localApprovedAccessType = _receiverAccessType;
        _isProcessing = false;
        _pendingAction = null;
      });

      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        await Future.wait([
          notifier.loadReceivedRequests(currentUser.id),
          notifier.loadSentRequests(currentUser.id),
        ]);
      }

      if (approve) {
        await _fetchRequestAccounts();
      }

      if (!mounted) return;
      AppSnackBar.success(
        context,
        approve ? 'Request approved successfully.' : 'Request rejected.',
      );
    } else {
      final errorMsg =
          ref.read(accessRequestProvider).error ?? 'Something went wrong';
      setState(() {
        _isProcessing = false;
        _pendingAction = null;
      });
      if (!mounted) return;
      AppSnackBar.error(context, errorMsg);
    }
  }

  void _toggleReceiverAccount(String accountId) {
    setState(() {
      if (_receiverSelectedAccounts.contains(accountId)) {
        _receiverSelectedAccounts.remove(accountId);
      } else {
        _receiverSelectedAccounts.add(accountId);
      }
    });
  }

  String _displayName(User user) {
    if ((user.firstName ?? '').isNotEmpty) return user.firstName!;
    if (user.displayName.isNotEmpty) return user.displayName;
    return user.username;
  }
}

String _displayuserName(User user) {
  if ((user.username ?? '').isNotEmpty) return user.username;
  if (user.username.isNotEmpty) return user.username;
  return user.username;
}
