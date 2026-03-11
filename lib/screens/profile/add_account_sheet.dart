import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _identifierCtrl = TextEditingController();
  int _priority = 2; // Default priority
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_identifierCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Account identifier is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = ref.read(authProvider).user?.id ?? '';
      final limit = AppConstants.accountTypeLimits[_selectedType] ?? 10000;

      await AccountService().createAccount(
        userId: userId,
        type: _selectedType,
        accountIdentifier: _identifierCtrl.text.trim(),
        defaultLimit: limit,
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
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Add Payment Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Account type dropdown
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Account Type'),
            items: AppConstants.accountTypeLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 16),

          // Identifier field
          TextFormField(
            controller: _identifierCtrl,
            decoration: const InputDecoration(
              labelText: 'Account Number / Phone',
              hintText: 'e.g. 01012345678',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 16),

          // Priority field
          Row(
            children: [
              Expanded(
                child: Text(
                  'Priority: $_priority',
                  style: const TextStyle(
                    fontSize: 14,
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
            const SizedBox(height: 12),
            ErrorBanner(message: _error!),
          ],

          const SizedBox(height: 24),

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
