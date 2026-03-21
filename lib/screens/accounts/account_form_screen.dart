import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/text_style.dart';
import '../../models/account_selection_models.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/account_type_badge.dart';
import '../../widgets/country_flag_icon.dart';
import '../../widgets/provider_logo.dart';

/// Full-screen form for creating or editing a financial account.
/// Implements the new 4-step cascading flow:
/// 1) Country → 2) Account type → 3) Provider → 4) Currency → default limit
class AccountFormScreen extends ConsumerStatefulWidget {
  final FinancialAccount? account;

  const AccountFormScreen({super.key, this.account});

  bool get isEditing => account != null;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _service = AccountService();

  final _titleCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _countrySearchCtrl = TextEditingController();
  final _providerSearchCtrl = TextEditingController();

  List<CountryOption> _countries = [];
  List<AccountTypeOption> _accountTypes = [];
  List<ProviderOption> _providers = [];
  List<CurrencyOption> _currencies = [];

  String? _countryId;
  String? _accountTypeId;
  String? _providerId;
  String? _currency;
  String? _providerAvailabilityId;

  double? _defaultLimit;
  AccountPriority _priority = AccountPriority.medium;
  bool _isVisible = true;
  String? _limitError;

  bool _loadingCountries = true;
  bool _loadingAccountTypes = false;
  bool _loadingProviders = false;
  bool _loadingCurrencies = false;
  bool _loadingLimit = false;
  bool _isSaving = false;

  String? _countryMessage;
  String? _accountTypeMessage;
  String? _providerMessage;
  String? _currencyMessage;
  String? _identifierError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    if (account != null) {
      _countryId = account.countryId.isNotEmpty ? account.countryId : null;
      _accountTypeId = account.accountTypeId.isNotEmpty
          ? account.accountTypeId
          : null;
      _providerId = account.providerId.isNotEmpty ? account.providerId : null;
      _providerAvailabilityId = account.providerAvailabilityId.isNotEmpty
          ? account.providerAvailabilityId
          : null;
      _currency = account.currency?.isNotEmpty == true
          ? account.currency
          : null;
      _defaultLimit = account.defaultLimit;
      _priority = account.priority;
      _isVisible = account.isVisible;
      _titleCtrl.text = account.accountTitle;
      _identifierCtrl.text = account.accountIdentifier;
      if (account.defaultLimit > 0) {
        _limitCtrl.text = account.defaultLimit.toStringAsFixed(0);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCountries());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _identifierCtrl.dispose();
    _limitCtrl.dispose();
    _countrySearchCtrl.dispose();
    _providerSearchCtrl.dispose();
    super.dispose();
  }

  bool get _hasBlockingAvailability =>
      (_countryMessage == _notAvailable && _countries.isEmpty) ||
      (_accountTypeMessage == _notAvailable && _accountTypes.isEmpty) ||
      (_providerMessage == _notAvailable && _providers.isEmpty) ||
      (_currencyMessage == _notAvailable && _currencies.isEmpty);

  bool get _selectionComplete =>
      _countryId != null &&
      _accountTypeId != null &&
      _providerId != null &&
      _providerAvailabilityId != null &&
      _defaultLimit != null;

  bool get _canSubmit =>
      !_isSaving &&
      !_loadingLimit &&
      _selectionComplete &&
      !_hasBlockingAvailability &&
      _identifierCtrl.text.trim().isNotEmpty;

  static const _notAvailable = 'Not available in your selection';

  // ── Data loading helpers ────────────────────────────────────────────────────
  Future<void> _loadCountries() async {
    if (!mounted) return;
    setState(() {
      _loadingCountries = true;
      _countryMessage = null;
      _generalError = null;
    });
    try {
      final countries = await _service.getActiveCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        if (_countryId != null && countries.every((c) => c.id != _countryId)) {
          _countryId = null;
        }
        if (countries.isEmpty) {
          _countryMessage = _notAvailable;
        }
      });

      if (_countryId != null) {
        await _loadAccountTypes();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _countryMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  Future<void> _loadAccountTypes() async {
    if (_countryId == null) return;
    if (!mounted) return;
    setState(() {
      _loadingAccountTypes = true;
      _accountTypes = [];
      _accountTypeMessage = null;
      _resetProviderState();
      _generalError = null;
    });

    try {
      final types = await _service.getAccountTypesForCountry(_countryId!);
      if (!mounted) return;
      setState(() {
        _accountTypes = types;
        if (_accountTypeId != null &&
            types.every((t) => t.id != _accountTypeId)) {
          _accountTypeId = null;
        }
        if (types.isEmpty) {
          _accountTypeMessage = _notAvailable;
        }
      });

      if (_accountTypeId != null && types.isNotEmpty) {
        await _loadProviders();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _accountTypeMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingAccountTypes = false);
    }
  }

  Future<void> _loadProviders() async {
    if (_countryId == null || _accountTypeId == null) return;
    if (!mounted) return;
    setState(() {
      _loadingProviders = true;
      _providers = [];
      _providerMessage = null;
      _resetCurrencyState();
      _generalError = null;
    });

    try {
      final providers = await _service.getProviders(
        countryId: _countryId!,
        accountTypeId: _accountTypeId!,
      );
      if (!mounted) return;
      setState(() {
        _providers = providers;
        if (_providerId != null &&
            providers.every((p) => p.id != _providerId)) {
          _providerId = null;
        }
        if (providers.isEmpty) {
          _providerMessage = _notAvailable;
        }
      });

      if (_providerId != null && providers.isNotEmpty) {
        await _loadCurrencies();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _providerMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  Future<void> _loadCurrencies() async {
    if (_countryId == null || _accountTypeId == null || _providerId == null) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadingCurrencies = true;
      _currencies = [];
      _currencyMessage = null;
      _providerAvailabilityId = null;
      _setLimit(null);
      _generalError = null;
    });

    try {
      final currencies = await _service.getCurrencies(
        countryId: _countryId!,
        accountTypeId: _accountTypeId!,
        providerId: _providerId!,
      );
      if (!mounted) return;
      setState(() {
        _currencies = currencies;
        if (_currency != null &&
            currencies.every((c) => c.currency != _currency)) {
          _currency = null;
          _providerAvailabilityId = null;
        } else if (_currency != null) {
          final match = _firstOrNull(
            currencies,
            (c) => c.currency == _currency,
          );
          _providerAvailabilityId = match?.providerAvailabilityId;
        }
        if (currencies.isEmpty) {
          _currencyMessage = _notAvailable;
        }
      });

      if (_providerAvailabilityId != null) {
        await _fetchLimit();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _currencyMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingCurrencies = false);
    }
  }

  Future<void> _fetchLimit() async {
    if (_countryId == null || _accountTypeId == null || _providerId == null) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadingLimit = true;
      _setLimit(null);
      _generalError = null;
    });

    try {
      final limit = await _service.fetchDefaultLimit(
        countryId: _countryId!,
        accountTypeId: _accountTypeId!,
        providerId: _providerId!,
      );
      if (!mounted) return;
      setState(() {
        _setLimit(limit);
        if (limit == null) {
          _generalError = _notAvailable;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generalError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLimit = false);
    }
  }

  void _resetProviderState() {
    _providers = [];
    _providerMessage = null;
    _providerId = null;
    _resetCurrencyState();
  }

  void _resetCurrencyState() {
    _currencies = [];
    _currencyMessage = null;
    _currency = null;
    _providerAvailabilityId = null;
    _limitError = null;
    _setLimit(null);
  }

  Future<void> _openCountrySheet() async {
    _countrySearchCtrl.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _countrySearchCtrl.text.trim().toLowerCase();
            final filtered = _countries.where((c) {
              if (query.isEmpty) return true;
              return c.name.toLowerCase().contains(query) ||
                  c.code.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                14.h,
                16.w,
                MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SearchField(
                    controller: _countrySearchCtrl,
                    hint: 'Search countries...',
                    onChanged: (_) => setModalState(() {}),
                    onClear: () {
                      _countrySearchCtrl.clear();
                      setModalState(() {});
                    },
                  ),
                  SizedBox(height: 12.h),
                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Text(
                        'No countries found',
                        style: TextStyles.bodySmallBold.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (_, index) {
                          final country = filtered[index];
                          final isSelected = country.id == _countryId;
                          return ListTile(
                            onTap: () {
                              Navigator.of(context).pop();
                              if (!mounted) return;
                              setState(() {
                                _countryId = country.id;
                                _accountTypeId = null;
                                _providerId = null;
                                _currency = null;
                                _providerAvailabilityId = null;
                                _generalError = null;
                              });
                              _loadAccountTypes();
                            },
                            leading: CountryFlagIcon(
                              countryCode: country.code,
                              size: 28.w,
                            ),
                            title: Text(country.name),
                            subtitle: Text(country.code),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: AppTheme.primary)
                                : null,
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: filtered.length,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openProviderSheet() async {
    _providerSearchCtrl.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _providerSearchCtrl.text.trim().toLowerCase();
            final filtered = _providers.where((p) {
              if (query.isEmpty) return true;
              return p.name.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                14.h,
                16.w,
                MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SearchField(
                    controller: _providerSearchCtrl,
                    hint: 'Search providers...',
                    onChanged: (_) => setModalState(() {}),
                    onClear: () {
                      _providerSearchCtrl.clear();
                      setModalState(() {});
                    },
                  ),
                  SizedBox(height: 12.h),
                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Text(
                        'No providers found',
                        style: TextStyles.bodySmallBold.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (_, index) {
                          final provider = filtered[index];
                          final isSelected = provider.id == _providerId;
                          return ListTile(
                            onTap: () {
                              Navigator.of(context).pop();
                              if (!mounted) return;
                              setState(() {
                                _providerId = provider.id;
                                _currency = null;
                                _providerAvailabilityId = null;
                                _generalError = null;
                              });
                              _loadCurrencies();
                            },
                            leading: ProviderLogo(
                              logoUuid: provider.logo,
                              providerName: provider.name,
                              size: 32.w,
                            ),
                            title: Text(provider.name),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: AppTheme.primary)
                                : null,
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: filtered.length,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _setLimit(double? value) {
    _defaultLimit = value;
    _limitCtrl.text = value != null ? value.toStringAsFixed(0) : '';
  }

  T? _firstOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  String _resolvedTitle() {
    final input = _titleCtrl.text.trim();
    if (input.isNotEmpty) return input;
    final providerName = _firstOrNull(
      _providers,
      (p) => p.id == _providerId,
    )?.name;
    final typeName = _firstOrNull(
      _accountTypes,
      (t) => t.id == _accountTypeId,
    )?.type;
    final parts = <String>[
      if (providerName != null && providerName.isNotEmpty)
        providerName
      else if (typeName != null && typeName.isNotEmpty)
        typeName,
      if (_currency != null && _currency!.isNotEmpty) _currency!,
    ];
    return parts.where((p) => p.isNotEmpty).join(' - ').trim().isNotEmpty
        ? parts.where((p) => p.isNotEmpty).join(' - ')
        : 'Financial Account';
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final identifier = _identifierCtrl.text.trim();
    final limitText = _limitCtrl.text.trim();
    final parsedLimit = double.tryParse(limitText);
    setState(() {
      _identifierError = identifier.isEmpty
          ? 'Account identifier is required.'
          : null;
      _limitError = limitText.isEmpty
          ? 'Please enter a limit or keep the default value.'
          : (parsedLimit == null || parsedLimit <= 0)
          ? 'Enter a valid positive limit.'
          : null;
      if (_generalError == _notAvailable) _generalError = null;
    });

    if (!_canSubmit || _identifierError != null || _limitError != null) return;
    if (_providerAvailabilityId == null || _defaultLimit == null) {
      setState(() => _generalError = 'Complete all steps before saving.');
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) {
      setState(() => _generalError = 'Missing user. Please re-authenticate.');
      return;
    }

    setState(() {
      _isSaving = true;
      _generalError = null;
    });

    try {
      final notifier = ref.read(accountsProvider.notifier);
      if (widget.account == null) {
        await _service.createAccount(
          userId: user.id,
          providerAvailabilityId: _providerAvailabilityId!,
          countryId: _countryId!,
          providerId: _providerId!,
          accountTypeId: _accountTypeId!,
          accountIdentifier: identifier,
          accountTitle: _resolvedTitle(),
          limit: parsedLimit!,
          priority: _priority,
        );
      } else {
        final updated = await notifier.updateAccount(
          accountId: widget.account!.id,
          providerAvailabilityId: _providerAvailabilityId!,
          countryId: _countryId!,
          providerId: _providerId!,
          accountTypeId: _accountTypeId!,
          accountIdentifier: identifier,
          accountTitle: _resolvedTitle(),
          limit: parsedLimit!,
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

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Account' : 'Add Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 20.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Update your financial account details.'
                    : 'Add a new financial account using the required steps.',
                style: TextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 18.h),
              if (isEditing) ...[
                Row(
                  children: [
                    ProviderLogo(
                      logoUuid: widget.account?.providerLogo,
                      providerName: widget.account?.providerName,
                      size: 40.w,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.account?.providerName ?? 'Provider',
                                  style: TextStyles.bodySmallBold.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              AccountTypeBadge(
                                type: widget.account?.accountTypeName,
                                iconSize: 14.w,
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              CountryFlagIcon(
                                countryCode: widget.account?.countryCode,
                                size: 28.w,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  widget.account?.countryName ??
                                      widget.account?.countryCode ??
                                      'Country',
                                  style: TextStyles.label.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
              ],

              _buildCountryStep(),
              SizedBox(height: 12.h),
              _buildAccountTypeStep(),
              SizedBox(height: 12.h),
              _buildProviderStep(),
              SizedBox(height: 12.h),
              _buildCurrencyStep(),
              SizedBox(height: 12.h),
              _buildLimitField(),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Title',
                  hintText: 'e.g. Travel Wallet',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 14.h),

              TextFormField(
                controller: _identifierCtrl,
                decoration: InputDecoration(
                  labelText: 'Account Identifier',
                  hintText: 'Enter the identifier provided by your provider',
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

              _buildPrioritySelector(),
              SizedBox(height: 8.h),

              if (isEditing) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Visible on profile',
                    style: TextStyles.bodySmall,
                  ),
                  value: _isVisible,
                  onChanged: (value) => setState(() => _isVisible = value),
                ),
                SizedBox(height: 8.h),
              ],

              if (_generalError != null) ...[
                ErrorBanner(message: _generalError!),
                SizedBox(height: 12.h),
              ],

              PrimaryButton(
                label: isEditing ? 'Save Changes' : 'Save Account',
                isLoading: _isSaving,
                onPressed: _canSubmit ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryStep() {
    final selected = _countries.firstWhere(
      (c) => c.id == _countryId,
      orElse: () =>
          const CountryOption(id: '', name: '', code: '', isActive: true),
    );
    final selectedCode =
        selected.code.isNotEmpty ? selected.code : widget.account?.countryCode;
    final selectedName = selected.name.isNotEmpty
        ? selected.name
        : (widget.account?.countryName ??
            selectedCode ??
            '');

    return _StepCard(
      title: 'Step 1 — Country',
      child: _SelectorField(
        label: 'Select country',
        enabled: !_loadingCountries,
        loading: _loadingCountries,
        value: _countryId != null
            ? Row(
                children: [
                  CountryFlagIcon(countryCode: selectedCode, size: 28.w),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      selectedName.isNotEmpty ? selectedName : 'Country',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(
                'Tap to choose',
                style: TextStyles.label.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
        onTap: _loadingCountries ? null : _openCountrySheet,
      ),
      message: _countryMessage,
      helper: _countries.isEmpty && !_loadingCountries
          ? 'No countries loaded yet.'
          : null,
    );
  }

  Widget _buildAccountTypeStep() {
    final enabled = _countryId != null && _accountTypeMessage != _notAvailable;
    return _StepCard(
      title: 'Step 2 — Account Type',
      child: _loadingAccountTypes && _accountTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _accountTypes.map((t) {
                final selected = _accountTypeId == t.id;
                return ChoiceChip(
                  label: AccountTypeBadge(type: t.type, iconSize: 16.w),
                  selected: selected,
                  onSelected: enabled && !_loadingAccountTypes
                      ? (_) {
                          if (t.id == _accountTypeId) return;
                          setState(() {
                            _accountTypeId = t.id;
                            _providerId = null;
                            _currency = null;
                            _providerAvailabilityId = null;
                            _generalError = null;
                          });
                          _loadProviders();
                        }
                      : null,
                  selectedColor: AppTheme.primary.withOpacity(0.12),
                  backgroundColor: AppTheme.surface,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
      message: _accountTypeMessage,
      helper: !_loadingAccountTypes && _accountTypes.isEmpty
          ? 'Select a country to load account types.'
          : null,
    );
  }

  Widget _buildProviderStep() {
    final enabled = _accountTypeId != null && _providerMessage != _notAvailable;
    final selected = _providers.firstWhere(
      (p) => p.id == _providerId,
      orElse: () => const ProviderOption(id: '', name: ''),
    );
    return _StepCard(
      title: 'Step 3 — Provider',
      child: _SelectorField(
        label: enabled ? 'Select provider' : 'Complete previous steps',
        enabled: enabled,
        loading: _loadingProviders,
        value: _providerId != null
            ? Row(
                children: [
                  ProviderLogo(
                    logoUuid: selected.logo,
                    providerName: selected.name,
                    size: 32.w,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      selected.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(
                'Tap to choose',
                style: TextStyles.label.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
        onTap: enabled && !_loadingProviders ? _openProviderSheet : null,
      ),
      message: _providerMessage,
      helper: !_loadingProviders && _providers.isEmpty
          ? 'Select an account type to load providers.'
          : null,
    );
  }

  Widget _buildCurrencyStep() {
    final enabled = _providerId != null && _currencyMessage != _notAvailable;
    return _StepCard(
      title: 'Step 4 — Currency',
      child: DropdownButtonFormField<String>(
        value: _currency,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: enabled ? 'Select currency' : 'Complete previous steps',
          suffixIcon: _loadingCurrencies
              ? Padding(
                  padding: EdgeInsets.all(10.w),
                  child: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        items: _currencies
            .map(
              (c) =>
                  DropdownMenuItem(value: c.currency, child: Text(c.currency)),
            )
            .toList(),
        onChanged: enabled && !_loadingCurrencies
            ? (value) {
                setState(() {
                  _currency = value;
                  _providerAvailabilityId = _firstOrNull(
                    _currencies,
                    (c) => c.currency == value,
                  )?.providerAvailabilityId;
                  _generalError = null;
                });
                if (value != null) {
                  _fetchLimit();
                } else {
                  _setLimit(null);
                }
              }
            : null,
      ),
      message: _currencyMessage,
      helper: !_loadingCurrencies && _currencies.isEmpty
          ? 'Select a provider to load currencies.'
          : null,
    );
  }

  Widget _buildLimitField() {
    final limitMessage = _generalError == _notAvailable
        ? _notAvailable
        : (_defaultLimit == null && !_loadingLimit
              ? 'Awaiting selection'
              : null);
    return _StepCard(
      title: 'Step 5 — Limit',
      child: TextFormField(
        controller: _limitCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) {
          if (_limitError != null) {
            setState(() => _limitError = null);
          }
        },
        decoration: InputDecoration(
          labelText: 'Default Limit',
          helperText:
              'Auto-fetched from system limits. You can keep it or override it.',
          hintText: _defaultLimit != null
              ? 'Default: ${_defaultLimit!.toStringAsFixed(0)}'
              : null,
          prefixIcon: const Icon(Icons.payments_outlined),
          suffixText: _currency ?? '',
          errorText: _limitError,
          suffixIcon: _loadingLimit
              ? Padding(
                  padding: EdgeInsets.all(10.w),
                  child: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
      ),
      message: limitMessage,
    );
  }

  Widget _buildPrioritySelector() {
    return _StepCard(
      title: 'Priority',
      child: Wrap(
        spacing: 8.w,
        children: AccountPriority.values.map((p) {
          final selected = _priority == p;
          String label;
          switch (p) {
            case AccountPriority.low:
              label = 'Low';
            case AccountPriority.medium:
              label = 'Medium';
              break;

            case AccountPriority.high:
              label = 'High';
              break;
          }
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _priority = p),
            selectedColor: p == AccountPriority.high
                ? AppTheme.error.withOpacity(0.14)
                : p == AccountPriority.low
                ? AppTheme.primary.withOpacity(0.12)
                : AppTheme.border.withOpacity(0.4),
            labelStyle: TextStyles.bodySmallBold.copyWith(
              color: selected
                  ? (p == AccountPriority.high
                        ? AppTheme.error
                        : p == AccountPriority.low
                        ? AppTheme.primary
                        : AppTheme.textPrimary)
                  : AppTheme.textSecondary,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  final Widget value;
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  const _SelectorField({
    required this.value,
    required this.label,
    required this.enabled,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: loading
              ? Padding(
                  padding: EdgeInsets.all(10.w),
                  child: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: value,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String? helper;
  final String? message;

  const _StepCard({
    required this.title,
    required this.child,
    this.helper,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.labelBold.copyWith(color: AppTheme.textSecondary),
        ),
        SizedBox(height: 6.h),
        child,
        if (message != null) ...[
          SizedBox(height: 6.h),
          Text(
            message!,
            style: TextStyles.captionMedium.copyWith(color: AppTheme.error),
          ),
        ] else if (helper != null) ...[
          SizedBox(height: 6.h),
          Text(
            helper!,
            style: TextStyles.captionRegular.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
