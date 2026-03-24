import 'package:Sendaal/widgets/account_card.dart';
import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../models/financial_account_model.dart';
import '../../models/system_limit_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/system_limits_service.dart';
import '../../widgets/account_type_badge.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/country_flag_icon.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/provider_logo.dart';
import 'account_form_screen.dart';

/// Dedicated Accounts screen for managing payment accounts.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await SystemLimitsService().loadLimits();
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(accountsProvider.notifier).loadAccounts(user.id);
    }
  }

  Future<void> _openAccountForm({FinancialAccount? account}) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AccountFormScreen(account: account),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(
            position: animation.drive(slide),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );

    if (result == true) {
      await _load();
    }
  }

  void _showAccountQuickActions(FinancialAccount account) {
    final rawType = account.accountTypeName.isNotEmpty
        ? account.accountTypeName
        : account.type.name;
    final label = AppConstants.displayLabel(rawType);
    final subtitleParts = <String>[
      account.providerName.isNotEmpty ? account.providerName : label,
      if (account.accountIdentifier.trim().isNotEmpty)
        account.accountIdentifier.trim(),
      if (account.currency?.isNotEmpty == true) account.currency!,
    ];
    final system =
        AppConstants.systemLimitFor(rawType) ??
        SystemLimit(
          id: -1,
          systemName: rawType,
          dailyLimit: account.defaultLimit.toInt(),
          systemImage: null,
        );

    showModalBottomSheet(
      backgroundColor: AppColors.background,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  account.accountTitle.trim().isNotEmpty
                                      ? account.accountTitle.trim()
                                      : label,
                                  style: TextStyles.bodyBold.copyWith(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              AccountTypeBadge(
                                type: account.accountTypeName.isNotEmpty
                                    ? account.accountTypeName
                                    : account.type.name,
                                iconSize: 14.w,
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              CountryFlagIcon(
                                countryCode: account.countryCode,
                                size: 24.w,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  account.countryName ??
                                      account.countryCode ??
                                      'Country',
                                  style: TextStyles.label.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            subtitleParts.join(' • '),
                            style: TextStyles.label.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 8.h,
                  children: [
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label:
                          '${_fmtAmount(account.defaultLimit)} ${account.currency?.isNotEmpty == true ? account.currency : 'EGP'}',
                    ),
                    _InfoChip(
                      icon: Icons.visibility_outlined,
                      label: account.isVisible ? 'Visible' : 'Hidden',
                    ),
                    _InfoChip(
                      icon: Icons.star_rate_rounded,
                      label: account.priority == AccountPriority.high
                          ? 'High'
                          : account.priority == AccountPriority.low
                          ? 'Low'
                          : 'Medium',
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                const Divider(),
                SizedBox(height: 4.h),
                _AccountActionTile(
                  icon: Icons.flag,
                  label: 'Set High priority',
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(accountsProvider.notifier)
                        .updatePriority(account.id, AccountPriority.high);
                  },
                ),
                _AccountActionTile(
                  icon: Icons.flag_outlined,
                  label: 'Set Medium priority',
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(accountsProvider.notifier)
                        .updatePriority(account.id, AccountPriority.medium);
                  },
                ),
                _AccountActionTile(
                  icon: Icons.flag_circle_outlined,
                  label: 'Set Low priority',
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(accountsProvider.notifier)
                        .updatePriority(account.id, AccountPriority.low);
                  },
                ),
                _AccountActionTile(
                  icon: account.isFavourite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: account.isFavourite
                      ? 'Remove from favourites'
                      : 'Add to favourites',
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(accountsProvider.notifier)
                        .toggleFavourite(account.id, account.isFavourite);
                  },
                ),
                _AccountActionTile(
                  icon: Icons.visibility_outlined,
                  label: 'Show on profile',
                  trailing: Switch.adaptive(
                    value: account.isVisible,
                    onChanged: (_) {
                      Navigator.pop(context);
                      ref
                          .read(accountsProvider.notifier)
                          .toggleVisibility(account.id, account.isVisible);
                    },
                    activeColor: AppTheme.primary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(accountsProvider.notifier)
                        .toggleVisibility(account.id, account.isVisible);
                  },
                ),

                _AccountActionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit account',
                  onTap: () {
                    Navigator.pop(context);
                    _openAccountForm(account: account);
                  },
                ),
                _AccountActionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete account',
                  labelColor: AppTheme.error,
                  iconColor: AppTheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(account);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(FinancialAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Delete Account',
        description:
            'This will remove ${account.accountTitle.isNotEmpty ? account.accountTitle : account.accountIdentifier} from your accounts. This action cannot be undone.',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(accountsProvider.notifier).deleteAccount(account.id);
      await _load();
      if (mounted) {
        AppSnackBar.success(context, 'Account deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to delete account.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);
    final searchQuery = _searchController.text.trim().toLowerCase();
    final accounts = state.accounts.where((acc) {
      if (searchQuery.isEmpty) return true;
      final provider = acc.providerName.toLowerCase();
      final country = (acc.countryName ?? acc.countryCode ?? '').toLowerCase();
      final title = acc.accountTitle.toLowerCase();
      return provider.contains(searchQuery) ||
          country.contains(searchQuery) ||
          title.contains(searchQuery);
    }).toList();
    final favouriteAccounts = accounts.where((a) => a.isFavourite).toList();
    final otherAccounts = accounts.where((a) => !a.isFavourite).toList();
    final activeCount = accounts.where((a) => a.isVisible).length;

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        backgroundColor: AppTheme.surface,
        titleSpacing: 0,
        title: AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isSearching
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            'Accounts',
            style: TextStyles.bodyBold.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          secondChild: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 0, 8.h),
            child: _SearchBar(
              controller: _searchController,
              autofocus: true,
              onChanged: () => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
          ),
          sizeCurve: Curves.easeOut,
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching
                ? 'Close search'
                : 'Search by provider or country',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          SizedBox(width: 6.w),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAccountForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: AppTheme.surface),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          children: [
            _AccountsHeader(total: accounts.length, active: activeCount),
            SizedBox(height: 12.h),
            if (state.isLoading && accounts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (state.error != null)
              ErrorBanner(message: state.error!, onRetry: _load)
            else if (accounts.isEmpty)
              searchQuery.isNotEmpty
                  ? EmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No accounts match your search',
                      subtitle: 'Try a different provider or country name.',
                    )
                  : const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No accounts yet',
                      subtitle: 'Add your first account to get started.',
                    )
            else ...[
              if (favouriteAccounts.isNotEmpty) ...[
                // Padding(
                //   padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 8.h),
                //   child: Text(
                //     'Favourites',
                //     style: TextStyles.bodySmallBold.copyWith(
                //       color: AppTheme.textPrimary,
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                // ),
                ...favouriteAccounts.map(
                  (account) => AccountCard(
                    account: account,
                    dense: true,
                    showToggle: true,
                    showStar: true,
                    onStar: () => ref
                        .read(accountsProvider.notifier)
                        .toggleFavourite(account.id, account.isFavourite),
                    onTap: () => _showAccountQuickActions(account),
                    onToggleVisibility: (_) => ref
                        .read(accountsProvider.notifier)
                        .toggleVisibility(account.id, account.isVisible),
                    onEdit: () => _openAccountForm(account: account),
                    onDelete: () => _confirmDelete(account),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              if (otherAccounts.isNotEmpty && favouriteAccounts.isNotEmpty)
                // Padding(
                //   padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 8.h),
                //   child: Text(
                //     'All accounts',
                //     style: TextStyles.bodySmallBold.copyWith(
                //       color: AppTheme.textSecondary,
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                // ),
                ...otherAccounts.map(
                  (account) => AccountCard(
                    account: account,
                    dense: true,
                    showToggle: true,
                    showStar: true,
                    onStar: () => ref
                        .read(accountsProvider.notifier)
                        .toggleFavourite(account.id, account.isFavourite),
                    onTap: () => _showAccountQuickActions(account),
                    onToggleVisibility: (_) => ref
                        .read(accountsProvider.notifier)
                        .toggleVisibility(account.id, account.isVisible),
                    onEdit: () => _openAccountForm(account: account),
                    onDelete: () => _confirmDelete(account),
                  ),
                ),
            ],
            SizedBox(height: 72.h),
          ],
        ),
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _AccountActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.labelColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primary).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.primary,
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyles.bodySmallBold.copyWith(
                      color: labelColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyles.captionRegular.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    this.autofocus = false,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
            spreadRadius: -2,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: 'Search by provider or country...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.primary),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }
}

class _AccountsHeader extends StatelessWidget {
  final int total;
  final int active;

  const _AccountsHeader({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected Accounts'.toUpperCase(),
                style: TextStyles.captionBold.copyWith(
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$total accounts',
                style: TextStyles.bodySmallBold.copyWith(
                  fontSize: 15.sp,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '$active Active',
            style: TextStyles.labelBold.copyWith(color: AppTheme.primary),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.r, color: AppTheme.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyles.captionMedium.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

String _fmtAmount(num value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final hasExact = value % 1000 == 0;
    return '${(value / 1000).toStringAsFixed(hasExact ? 0 : 1)}K';
  }
  return value.toStringAsFixed(0);
}
