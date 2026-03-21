import 'package:flutter/material.dart';

import '../../models/financial_account_model.dart';
import 'account_form_screen.dart';

/// Wrapper kept for backward compatibility; delegates to the new cascading form.
class EditAccountScreen extends StatelessWidget {
  final FinancialAccount account;

  const EditAccountScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return AccountFormScreen(account: account);
  }
}
