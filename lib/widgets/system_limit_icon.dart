import 'package:flutter/material.dart';

import '../models/system_limit_model.dart';

/// Reusable system icon that prefers Directus images and falls back to
/// sensible Material icons per system name.
class SystemIcon extends StatelessWidget {
  final SystemLimit system;
  final double size;

  const SystemIcon({super.key, required this.system, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final url = system.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallbackIcon(system.systemName, size),
      );
    }
    return _fallbackIcon(system.systemName, size);
  }
}

/// Helper for cases where only the name is known.
Widget buildSystemIcon({
  SystemLimit? system,
  String? systemName,
  double size = 28,
}) {
  final resolved =
      system ??
      SystemLimit(
        id: -1,
        systemName: systemName ?? '',
        dailyLimit: 0,
        systemImage: null,
      );
  return SystemIcon(system: resolved, size: size);
}

Widget _fallbackIcon(String name, double size) {
  switch (name.toLowerCase()) {
    case 'fiat':
      return Icon(Icons.payments_outlined, size: size);
    case 'crypto':
      return Icon(Icons.currency_bitcoin_outlined, size: size);
    case 'point':
      return Icon(Icons.card_giftcard_outlined, size: size);
    case 'instapay':
      return Icon(Icons.flash_on, size: size);
    case 'digital_wallet':
      return Icon(Icons.account_balance_wallet, size: size);
    case 'bank_account':
      return Icon(Icons.account_balance, size: size);
    case 'telda':
      return Icon(Icons.credit_card, size: size);
    default:
      return Icon(Icons.payment, size: size);
  }
}
