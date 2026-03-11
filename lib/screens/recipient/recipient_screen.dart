import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_account_model.dart';
import '../../providers/account_provider.dart';
import '../../services/smart_split_service.dart';
import '../../widgets/app_widgets.dart';

/// Recipient View Screen
///
/// Shows a recipient's profile + sorted accounts.
/// User enters an amount and triggers the Smart Split algorithm.
class RecipientScreen extends ConsumerStatefulWidget {
  final User recipient;

  const RecipientScreen({super.key, required this.recipient});

  @override
  ConsumerState<RecipientScreen> createState() => _RecipientScreenState();
}

class _RecipientScreenState extends ConsumerState<RecipientScreen> {
  final _amountCtrl = TextEditingController();
  String? _amountError;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _splitAndNavigate(List<FinancialAccount> accounts) {
    final text = _amountCtrl.text.trim();
    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid amount greater than zero');
      return;
    }

    final result = SmartSplitService.split(amount: amount, accounts: accounts);

    if (!result.isSuccess) {
      setState(() => _amountError = result.error);
      return;
    }

    setState(() => _amountError = null);

    Navigator.pushNamed(
      context,
      AppRoutes.transfer,
      arguments: TransferArgs(
        recipient: widget.recipient,
        suggestions: result.suggestions,
        accounts: accounts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(
      recipientAccountsProvider(widget.recipient.id),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipient.displayName ?? "Recipient")),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: ErrorBanner(message: 'Could not load accounts: $e')),
        data: (accounts) {
          // Sort visible accounts by priority before displaying
          final visible = accounts.where((a) => a.isVisible).toList()
            ..sort((a, b) => a.priority.compareTo(b.priority));

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Recipient profile card ────────────────────────────────────
              _RecipientHeader(recipient: widget.recipient),
              const SizedBox(height: 24),

              // ── Accounts ──────────────────────────────────────────────────
              const Text(
                'Payment Accounts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              if (visible.isEmpty)
                const EmptyState(
                  icon: Icons.block_outlined,
                  title: 'No visible accounts',
                  subtitle: 'This user has no visible payment accounts.',
                )
              else
                ...visible.map((a) => AccountCard(account: a)),

              const SizedBox(height: 28),

              // ── Amount Input ──────────────────────────────────────────────
              AmountInputField(
                controller: _amountCtrl,
                errorText: _amountError,
                onChanged: (_) {
                  if (_amountError != null) {
                    setState(() => _amountError = null);
                  }
                },
              ),
              const SizedBox(height: 20),

              // ── Split button ──────────────────────────────────────────────
              PrimaryButton(
                label: 'Split Automatically',
                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                onPressed: visible.isEmpty
                    ? null
                    : () => _splitAndNavigate(visible),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Recipient header ─────────────────────────────────────────────────────────

class _RecipientHeader extends StatelessWidget {
  final User recipient;

  const _RecipientHeader({required this.recipient});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.surfaceVariant,
              backgroundImage: recipient.avatar != null
                  ? NetworkImage(recipient.avatar!)
                  : null,
              child: recipient.avatar == null
                  ? Text(
                      recipient.displayName ??
                          recipient.username?.substring(0, 1).toUpperCase() ??
                          '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.displayName ?? recipient.username ?? 'Recipient',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${recipient.username}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (recipient.isVerified == true)
              const Tooltip(
                message: 'Verified user',
                child: Icon(Icons.verified, color: AppTheme.primary, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
