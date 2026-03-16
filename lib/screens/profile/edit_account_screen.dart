import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/account_type_dropdown.dart';

/// Full-screen editor for an existing financial account.
class EditAccountScreen extends ConsumerStatefulWidget {
  final FinancialAccount account;

  const EditAccountScreen({super.key, required this.account});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  late String _selectedType;
  late String _instapayIdType;
  late String _bankIdType;
  late TextEditingController _titleCtrl;
  late TextEditingController _identifierCtrl;
  late TextEditingController _limitCtrl;
  late int _priority;
  late bool _isVisible;

  bool _isSaving = false;
  String? _error;
  String? _typeError;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _selectedType = account.type.name;
    _instapayIdType =
        _selectedType == 'instapay' &&
            _looksLikePhone(account.accountIdentifier)
        ? 'phone'
        : 'handle';
    _bankIdType =
        _selectedType == 'bank_account' &&
            _looksLikeIban(account.accountIdentifier)
        ? 'iban'
        : 'account';
    _titleCtrl = TextEditingController(
      text: account.accountTitle.isNotEmpty
          ? account.accountTitle
          : AppConstants.displayLabel(account.type.name),
    );
    _identifierCtrl = TextEditingController(text: account.accountIdentifier);
    _limitCtrl = TextEditingController(
      text: account.defaultLimit.toStringAsFixed(0),
    );
    _priority = account.priority;
    _isVisible = account.isVisible;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _identifierCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  bool _looksLikePhone(String value) =>
      RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(value);
  bool _looksLikeIban(String value) => RegExp(r'^EG\d{27}$').hasMatch(value);

  String? _validateIdentifier(String value) {
    if (value.isEmpty) return 'Account identifier is required.';

    switch (_selectedType) {
      case 'telda':
      case 'digital_wallet':
        if (!_looksLikePhone(value)) {
          return 'Enter 11-digit mobile starting 010/011/012/015.';
        }
        return null;
      case 'bank_account':
        if (_bankIdType == 'iban') {
          if (!_looksLikeIban(value.toUpperCase())) {
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
          if (!_looksLikePhone(value)) {
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

    if (_selectedType.isEmpty) {
      setState(() => _typeError = 'Please select an account type.');
      return;
    }

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
      _isSaving = true;
      _error = null;
    });

    final notifier = ref.read(accountsProvider.notifier);
    final updated = await notifier.updateAccount(
      accountId: widget.account.id,
      type: _selectedType,
      accountIdentifier: normalizedIdentifier,
      accountTitle: title.isNotEmpty
          ? title
          : AppConstants.displayLabel(_selectedType),
      defaultLimit: parsedLimit,
      priority: _priority,
      isVisible: _isVisible,
    );

    if (updated == null) {
      setState(() {
        _isSaving = false;
        _error = 'Failed to update account. Please try again.';
      });
      return;
    }

    final user = ref.read(authProvider).user;
    if (user != null) {
      await notifier.loadAccounts(user.id);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Title',
                hintText: 'e.g. Business Credit, Emergency Fund',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 14.h),

            AccountTypeDropdown(
              value: _selectedType,
              isRequired: true,
              errorText: _typeError,
              onChanged: (v) {
                setState(() {
                  _selectedType = v;
                  _typeError = null;
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

            TextFormField(
              controller: _identifierCtrl,
              decoration: InputDecoration(
                labelText: 'Account Identifier',
                hintText: _selectedType == 'instapay'
                    ? (_instapayIdType == 'handle'
                          ? 'e.g. user or user@instapay'
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

            TextFormField(
              controller: _limitCtrl,
              decoration: const InputDecoration(
                labelText: 'Default Limit (EGP)',
                helperText:
                    'Used by Smart Split to cap how much can be routed.',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            SizedBox(height: 16.h),

            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Visible on profile',
                style: TextStyle(fontSize: 14.sp),
              ),
              value: _isVisible,
              onChanged: (value) => setState(() => _isVisible = value),
            ),
            SizedBox(height: 8.h),

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
              label: 'Save Changes',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
