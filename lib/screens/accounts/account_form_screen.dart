import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_service.dart';
import '../../widgets/account_type_dropdown.dart';
import '../../widgets/app_widgets.dart';

/// Full-screen form for creating or editing a financial account.
class AccountFormScreen extends ConsumerStatefulWidget {
  final FinancialAccount? account;

  const AccountFormScreen({super.key, this.account});

  bool get isEditing => account != null;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late String _selectedType;
  late String _instapayIdType; // handle | phone
  late String _bankIdType; // account | iban
  late TextEditingController _titleCtrl;
  late TextEditingController _identifierCtrl;
  late TextEditingController _limitCtrl;
  late int _priority;
  late bool _isVisible;

  bool _isSaving = false;
  String? _identifierError;
  String? _limitError;
  String? _generalError;
  String? _typeError;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _selectedType = account?.type.name ?? 'instapay';
    _instapayIdType =
        _selectedType == 'instapay' &&
            account != null &&
            _looksLikePhone(account.accountIdentifier)
        ? 'phone'
        : 'handle';
    _bankIdType =
        _selectedType == 'bank_account' &&
            account != null &&
            _looksLikeIban(account.accountIdentifier)
        ? 'iban'
        : 'account';
    _titleCtrl = TextEditingController(
      text: account?.accountTitle.isNotEmpty == true
          ? account!.accountTitle
          : '',
    );
    _identifierCtrl = TextEditingController(
      text: account?.accountIdentifier ?? '',
    );
    _limitCtrl = TextEditingController(
      text:
          (account?.defaultLimit ??
                  AppConstants.limitForAccountType(_selectedType))
              .toStringAsFixed(0),
    );
    _priority = account?.priority ?? 2;
    _isVisible = account?.isVisible ?? true;
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

    final idError = _validateIdentifier(identifier);
    final parsedLimit = double.tryParse(limitText);

    setState(() {
      _typeError = _selectedType.isEmpty
          ? 'Please select an account type.'
          : null;
      _identifierError = idError;
      _limitError = (parsedLimit == null || parsedLimit <= 0)
          ? 'Enter a valid positive default limit.'
          : null;
      _generalError = null;
    });

    if (_typeError != null ||
        idError != null ||
        parsedLimit == null ||
        parsedLimit <= 0) {
      return;
    }

    // Normalize identifiers
    String normalizedIdentifier = identifier;
    if (_selectedType == 'instapay' && _instapayIdType == 'handle') {
      if (!identifier.toLowerCase().contains('@')) {
        normalizedIdentifier = '$identifier@instapay';
      }
    }
    if (_selectedType == 'bank_account' && _bankIdType == 'iban') {
      normalizedIdentifier = normalizedIdentifier.toUpperCase();
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null)
        throw Exception('Missing user. Please re-authenticate.');

      final notifier = ref.read(accountsProvider.notifier);

      if (widget.account == null) {
        await AccountService().createAccount(
          userId: user.id,
          type: _selectedType,
          accountIdentifier: normalizedIdentifier,
          accountTitle: title.isNotEmpty
              ? title
              : AppConstants.displayLabel(_selectedType),
          defaultLimit: parsedLimit,
          priority: _priority,
        );
      } else {
        final updated = await notifier.updateAccount(
          accountId: widget.account!.id,
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
          throw Exception('Failed to update account. Please try again.');
        }
      }

      await notifier.loadAccounts(user.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _generalError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Account' : 'Add Account')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing
                          ? 'Update your payment account details.'
                          : 'Create a new payment account to receive and send.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 18.h),

                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Account Title',
                        hintText: 'e.g. Emergency Wallet, Travel Card',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 14.h),

                    AccountTypeDropdown(
                      value: _selectedType,
                      isRequired: true,
                      errorText: _typeError,
                      onChanged: (v) {
                        final defaultLimit = AppConstants.limitForAccountType(
                          v,
                        );
                        setState(() {
                          _selectedType = v;
                          _typeError = null;
                          _limitCtrl.text = defaultLimit.toStringAsFixed(0);
                          if (v != 'instapay') _instapayIdType = 'handle';
                          if (v != 'bank_account') _bankIdType = 'account';
                          _identifierError = null;
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
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
                        errorText: _identifierError,
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (_) {
                        if (_identifierError != null) {
                          setState(() => _identifierError = null);
                        }
                      },
                    ),
                    SizedBox(height: 16.h),

                    TextFormField(
                      controller: _limitCtrl,
                      decoration: InputDecoration(
                        labelText: 'Default Limit (EGP)',
                        helperText:
                            'Used by Smart Split to cap how much can be routed.',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        errorText: _limitError,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        if (_limitError != null) {
                          setState(() => _limitError = null);
                        }
                      },
                    ),
                    SizedBox(height: 16.h),

                    if (isEditing) ...[
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Visible on profile',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        value: _isVisible,
                        onChanged: (value) =>
                            setState(() => _isVisible = value),
                      ),
                      SizedBox(height: 8.h),
                    ],

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
                        Text(
                          _priority == 0 ? 'Favorite' : 'Standard',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _priority.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (value) =>
                          setState(() => _priority = value.toInt()),
                    ),

                    if (_generalError != null) ...[
                      SizedBox(height: 12.h),
                      ErrorBanner(message: _generalError!),
                    ],

                    SizedBox(height: 12.h),

                    PrimaryButton(
                      label: isEditing ? 'Save Changes' : 'Save Account',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
