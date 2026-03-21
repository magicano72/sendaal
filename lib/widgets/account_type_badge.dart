import 'package:flutter/material.dart';

class AccountTypeBadge extends StatelessWidget {
  final String? type;
  final double iconSize;

  const AccountTypeBadge({super.key, this.type, this.iconSize = 16});

  @override
  Widget build(BuildContext context) {
    final info = _badgeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: iconSize, color: info.color),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeInfo _badgeInfo(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'fiat':
        return const _BadgeInfo(
          icon: Icons.payments_outlined,
          label: 'Fiat',
          color: Color(0xFF1E88E5),
        );
      case 'crypto':
        return const _BadgeInfo(
          icon: Icons.diamond_outlined,
          label: 'Crypto',
          color: Color(0xFF8E24AA),
        );
      case 'point':
        return const _BadgeInfo(
          icon: Icons.card_giftcard_outlined,
          label: 'Points',
          color: Color(0xFFF9A825),
        );
      default:
        return const _BadgeInfo(
          icon: Icons.account_balance_wallet,
          label: 'Unknown',
          color: Color(0xFF757575),
        );
    }
  }
}

class _BadgeInfo {
  final IconData icon;
  final String label;
  final Color color;
  const _BadgeInfo({required this.icon, required this.label, required this.color});
}
