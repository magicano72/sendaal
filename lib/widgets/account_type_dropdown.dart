import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/text_style.dart';
import '../models/system_limit_model.dart';
import 'system_limit_icon.dart';

class AccountTypeOption {
  final String key;
  final String label;
  final SystemLimit system;

  const AccountTypeOption({
    required this.key,
    required this.label,
    required this.system,
  });
}

/// Fintech-styled, searchable dropdown for selecting an account type.
class AccountTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? errorText;
  final bool isRequired;
  final bool enabled;

  const AccountTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Account Type',
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
  });

  List<AccountTypeOption> _buildOptions() {
    final keys = AppConstants.accountTypeLimits.keys.isNotEmpty
        ? AppConstants.accountTypeLimits.keys
        : AppConstants.accountTypeLabels.keys;

    return keys
        .map(
          (key) => AccountTypeOption(
            key: key,
            label: AppConstants.displayLabel(key),
            system: AppConstants.systemLimitFor(key) ??
                SystemLimit(
                  id: -1,
                  systemName: key,
                  dailyLimit: 0,
                  systemImage: null,
                ),
          ),
        )
        .toList();
  }

  AccountTypeOption? _findOption(
    List<AccountTypeOption> options,
    String? key,
  ) {
    if (key == null) return null;
    for (final option in options) {
      if (option.key == key) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildOptions();
    final selected = _findOption(options, value);
    final displayError = errorText ??
        (isRequired && (value == null || value!.isEmpty)
            ? 'Please select an account type.'
            : null);
    final hasError = displayError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.labelBold.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: enabled
                ? () async {
                    final chosen = await _openPicker(context, options, value);
                    if (chosen != null && chosen != value) {
                      onChanged(chosen);
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: hasError ? AppTheme.error : AppTheme.border,
                  width: hasError ? 1.3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _IconBadge(
                    system: selected?.system,
                    fallbackName: selected?.key,
                    isSelected: selected != null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selected?.label ?? 'Select account type',
                          style: TextStyles.bodySmall.copyWith(
                            fontSize: 14.sp,
                            fontWeight: selected != null
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected != null
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tap to choose',
                          style: TextStyles.captionRegular.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                    size: 22.r,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(
            displayError!,
            style: TextStyles.captionMedium.copyWith(
              color: AppTheme.error,
              fontSize: 12.sp,
            ),
          ),
        ],
      ],
    );
  }

  Future<String?> _openPicker(
    BuildContext context,
    List<AccountTypeOption> options,
    String? current,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountTypeSheet(
        options: options,
        initialValue: current,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final SystemLimit? system;
  final String? fallbackName;
  final bool isSelected;

  const _IconBadge({
    this.system,
    this.fallbackName,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(isSelected ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SystemIcon(
        system: system ??
            SystemLimit(
              id: -1,
              systemName: fallbackName ?? '',
              dailyLimit: 0,
              systemImage: null,
            ),
        size: 20.r,
      ),
    );
  }
}

class _AccountTypeSheet extends StatefulWidget {
  final List<AccountTypeOption> options;
  final String? initialValue;

  const _AccountTypeSheet({
    required this.options,
    this.initialValue,
  });

  @override
  State<_AccountTypeSheet> createState() => _AccountTypeSheetState();
}

class _AccountTypeSheetState extends State<_AccountTypeSheet> {
  late List<AccountTypeOption> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _searchCtrl.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_handleSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.options
          : widget.options
              .where(
                (o) =>
                    o.label.toLowerCase().contains(query) ||
                    o.key.toLowerCase().contains(query),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(22.r);

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose Account Type',
                      style: TextStyles.bodyBold.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search account types',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No account types found',
                        style: TextStyles.label.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final option = _filtered[index];
                        final isSelected = option.key == widget.initialValue;

                        return InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => Navigator.pop(context, option.key),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withOpacity(0.08)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                _IconBadge(
                                  system: option.system,
                                  fallbackName: option.key,
                                  isSelected: isSelected,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: TextStyles.bodySmallBold.copyWith(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Tap to select',
                                        style: TextStyles.captionRegular.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 160),
                                  opacity: isSelected ? 1 : 0,
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.primary,
                                    size: 22.r,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
