part of '../accounts_screen.dart';

class AccountsEmptyState extends StatelessWidget {
  const AccountsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 32.h),
          _Graphic(),
          SizedBox(height: 24.h),
          Text(
            'No accounts yet',
            style: TextStyles.h2Medium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            'Add your first account to get started.',
            style: TextStyles.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _Graphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.w,
      width: 220.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 180.w,
            width: 180.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.07),
                  Colors.white,
                ],
              ),
            ),
          ),
          _FloatingTile(
            size: 120.w,
            icon: Icons.account_balance_wallet,
            iconColor: AppTheme.primary,
            background: Colors.white,
            elevation: 10,
          ),
          Positioned(
            top: 24.w,
            right: 24.w,
            child: _FloatingTile(
              size: 60.w,
              icon: Icons.add,
              iconColor: AppTheme.primary,
              background: AppTheme.primary.withOpacity(0.08),
              elevation: 6,
            ),
          ),
          Positioned(
            bottom: 18.w,
            left: 12.w,
            child: _FloatingTile(
              size: 56.w,
              icon: Icons.savings_outlined,
              iconColor: AppTheme.primary.withOpacity(0.9),
              background: Colors.white,
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTile extends StatelessWidget {
  final double size;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final double elevation;

  const _FloatingTile({
    required this.size,
    required this.icon,
    required this.iconColor,
    required this.background,
    this.elevation = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: elevation,
            offset: Offset(0, elevation * 0.6),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: size * 0.42),
    );
  }
}
