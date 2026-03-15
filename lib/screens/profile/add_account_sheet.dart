import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_service.dart';
import '../../widgets/app_widgets.dart';

/// Bottom sheet for adding a new financial account
class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  String _selectedType = 'instapay';
  String _instapayIdType = 'handle'; // 'handle' | 'phone'
  String _bankIdType = 'account'; // 'account' | 'iban'
  final _titleCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  double _defaultLimit = AppConstants.limitForAccountType('instapay');
  int _priority = 2; // Default priority
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _limitCtrl.text = _defaultLimit.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _identifierCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String value) {
    if (value.isEmpty) return 'Account identifier is required.';

    switch (_selectedType) {
      case 'telda':
      case 'digital_wallet':
        // Egyptian mobile: 11 digits starting 010/011/012/015
        if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(value)) {
          return 'Enter 11-digit mobile starting 010/011/012/015.';
        }
        return null;
      case 'bank_account':
        if (_bankIdType == 'iban') {
          final iban = value.toUpperCase();
          if (!RegExp(r'^EG\d{27}$').hasMatch(iban)) {
            return 'IBAN must start with EG followed by 27 digits.';
          }
          return null;
        } else {
          if (!RegExp(r'^[0-9]{8,30}$').hasMatch(value)) {
            return 'Bank account should be 8-30 digits.';
          }
          return null;
        }
      case 'instapay':
        if (_instapayIdType == 'phone') {
          if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(value)) {
            return 'Enter 11-digit mobile starting 010/011/012/015.';
          }
          return null;
        } else {
          final lower = value.toLowerCase();
          if (lower.contains('@')) {
            final parts = value.split('@');
            if (parts.length != 2 || parts[1].toLowerCase() != 'instapay.com') {
              return 'Only @instapay.com is allowed for InstaPay handles.';
            }
            if (!RegExp(r'^(?=.*[a-z])[a-z0-9._-]{3,30}$').hasMatch(parts[0])) {
              return 'Handle must be 3-30 lowercase letters/numbers/._-';
            }
            return null;
          }
          if (!RegExp(r'^(?=.*[a-z])[a-z0-9._-]{3,30}$').hasMatch(value)) {
            return 'Use 3-30 lowercase letters/numbers/._- for InstaPay handle.';
          }
          return null;
        }
      default:
        if (!RegExp(r'^[+0-9A-Za-z._-]{6,32}$').hasMatch(value)) {
          return 'Use 6-32 letters/numbers/+ . _ -';
        }
        return null;
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    var identifier = _identifierCtrl.text.trim();
    final limitText = _limitCtrl.text.trim();

    final idError = _validateIdentifier(identifier);
    if (idError != null) {
      setState(() => _error = idError);
      return;
    }

    // Normalize InstaPay: append @instapay only for non-numeric handles
    String normalizedIdentifier = identifier;
    if (_selectedType == 'instapay' && _instapayIdType == 'handle') {
      if (!identifier.toLowerCase().contains('@')) {
        normalizedIdentifier = '$identifier@instapay';
      }
    }
    if (_selectedType == 'bank_account' && _bankIdType == 'iban') {
      normalizedIdentifier = normalizedIdentifier.toUpperCase();
    }

    final parsedLimit = double.tryParse(limitText);
    if (parsedLimit == null || parsedLimit <= 0) {
      setState(() => _error = 'Enter a valid positive default limit.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = ref.read(authProvider).user?.id ?? '';

      await AccountService().createAccount(
        userId: userId,
        type: _selectedType,
        accountIdentifier: normalizedIdentifier,
        accountTitle:
            title.isNotEmpty ? title : AppConstants.displayLabel(_selectedType),
        defaultLimit: parsedLimit,
        priority: _priority,
      );

      // Reload accounts in the provider
      await ref.read(accountsProvider.notifier).loadAccounts(userId);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Handle bar
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
            'Add Payment Account',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),

          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Account Title',
              hintText: 'e.g. Emergency Wallet, Travel Card',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 14.h),

          // Account type dropdown
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Account Type'),
            items: AppConstants.accountTypeLimits.keys
                .map(
                  (key) => DropdownMenuItem(
                    value: key,
                    child: Text(AppConstants.displayLabel(key)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              final newDefault = AppConstants.limitForAccountType(v);
              setState(() {
                _selectedType = v;
                _defaultLimit = newDefault;
                _limitCtrl.text = newDefault.toStringAsFixed(0);
                if (v != 'instapay') {
                  _instapayIdType = 'handle';
                }
                if (v != 'bank_account') {
                  _bankIdType = 'account';
                }
              });
            },
          ),
          SizedBox(height: 16.h),

          if (_selectedType == 'instapay') ...[
            DropdownButtonFormField<String>(
              value: _instapayIdType,
              decoration: const InputDecoration(
                labelText: 'InstaPay Identifier Type',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'handle',
                  child: Text('Username @instapay'),
                ),
                DropdownMenuItem(
                  value: 'phone',
                  child: Text('Phone (11-digit)'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _instapayIdType = v;
                });
              },
            ),
            SizedBox(height: 12.h),
          ],

          if (_selectedType == 'bank_account') ...[
            DropdownButtonFormField<String>(
              value: _bankIdType,
              decoration: const InputDecoration(
                labelText: 'Bank Identifier Type',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'account',
                  child: Text('Account Number'),
                ),
                DropdownMenuItem(value: 'iban', child: Text('IBAN')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _bankIdType = v;
                });
              },
            ),
            SizedBox(height: 12.h),
          ],

          // Identifier field
          TextFormField(
            controller: _identifierCtrl,
            decoration: InputDecoration(
              labelText: 'Account Identifier',
              hintText: _selectedType == 'instapay'
                  ? (_instapayIdType == 'handle'
                        ? 'e.g. x or x@instapay'
                        : 'e.g. 01012345678')
                  : _selectedType == 'bank_account'
                  ? (_bankIdType == 'iban'
                        ? 'EG380019000500000000263180002'
                        : 'e.g. 1234567890')
                  : 'e.g. 01012345678',
              prefixIcon: const Icon(Icons.tag),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 16.h),

          // Default limit field
          TextFormField(
            controller: _limitCtrl,
            decoration: const InputDecoration(
              labelText: 'Default Limit (EGP)',
              helperText:
                  'Used by Smart Split to cap how much can be routed here.',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 16.h),

          // Priority field
          Row(
            children: [
              Expanded(
                child: Text(
                  'Priority: $_priority',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _priority.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (value) => setState(() => _priority = value.toInt()),
          ),

          if (_error != null) ...[
            SizedBox(height: 12.h),
            ErrorBanner(message: _error!),
          ],

          SizedBox(height: 24.h),

          PrimaryButton(
            label: 'Save Account',
            isLoading: _isLoading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
