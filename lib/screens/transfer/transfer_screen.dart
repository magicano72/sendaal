import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/split_suggestion_model.dart';
import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Transfer Instructions Screen
///
/// Displays the split result with copy-to-clipboard actions for each account.
/// This replaces deep linking for the MVP phase.
class TransferScreen extends ConsumerWidget {
  final TransferArgs args;

  const TransferScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = args.suggestions;
    final recipient = args.recipient;

    // Calculate total
    final total = suggestions.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Instructions')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Summary card ──────────────────────────────────────────────────
          _SummaryCard(recipient: recipient, total: total),
          const SizedBox(height: 20),

          // ── Instructions ──────────────────────────────────────────────────
          const Text(
            'Follow these steps to complete your transfer:',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),

          // ── Transfer tiles ────────────────────────────────────────────────
          ...suggestions.asMap().entries.map(
            (entry) =>
                _TransferTile(step: entry.key + 1, suggestion: entry.value),
          ),

          const SizedBox(height: 28),

          // ── Done button ───────────────────────────────────────────────────
          PrimaryButton(
            label: 'Done',
            backgroundColor: AppTheme.success,
            onPressed: () {
              // Pop all the way back to the main shell
              Navigator.of(
                context,
              ).popUntil((route) => route.settings.name == AppRoutes.home);
            },
          ),

          const SizedBox(height: 16),

          // Disclaimer
          const Center(
            child: Text(
              'Complete transfers manually in each payment app.',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final User recipient;
  final double total;

  const _SummaryCard({required this.recipient, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.surfaceVariant,
              child: Text(
                recipient.displayName.isNotEmpty
                    ? recipient.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '@${recipient.username}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                ),
                Text(
                  '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} EGP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual transfer tile ─────────────────────────────────────────────────

class _TransferTile extends StatelessWidget {
  final int step;
  final SplitSuggestion suggestion;

  const _TransferTile({required this.step, required this.suggestion});

  String get _label =>
      AppConstants.accountTypeLabels[suggestion.accountType] ??
      suggestion.accountType;

  String get _amountStr {
    final v = suggestion.amount;
    return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} EGP';
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Amount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _amountStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Copy row: Account number
            _CopyRow(
              icon: Icons.tag,
              label: 'Account / Phone',
              value: suggestion.accountIdentifier,
              onCopy: () => _copy(
                context,
                suggestion.accountIdentifier,
                'Account number',
              ),
            ),
            const SizedBox(height: 8),

            // Copy row: Amount
            _CopyRow(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: _amountStr,
              onCopy: () => _copy(context, _amountStr, 'Amount'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy, size: 14),
          label: const Text('Copy', style: TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        ),
      ],
    );
  }
}
