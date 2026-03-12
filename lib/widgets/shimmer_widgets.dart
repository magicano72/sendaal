import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_theme.dart';

/// Shimmer loading card widget
class ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsets margin;
  final BorderRadius borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant.withOpacity(0.5),
      highlightColor: AppTheme.surface,
      child: Container(
        margin: margin,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Shimmer loading for access request cards
class AccessRequestShimmer extends StatelessWidget {
  final int count;

  const AccessRequestShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header shimmer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Shimmer.fromColors(
              baseColor: AppTheme.surfaceVariant.withOpacity(0.5),
              highlightColor: AppTheme.surface,
              child: Container(
                height: 24,
                width: 150,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Card shimmers
          ...List.generate(count, (_) => const ShimmerCard(height: 140)),
          const SizedBox(height: 16),
          // Prompt shimmer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: AppTheme.surfaceVariant.withOpacity(0.5),
                  highlightColor: AppTheme.surface,
                  child: Container(
                    height: 32,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Shimmer.fromColors(
                  baseColor: AppTheme.surfaceVariant.withOpacity(0.5),
                  highlightColor: AppTheme.surface,
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full page shimmer loader
class FullPageShimmer extends StatelessWidget {
  const FullPageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(5, (_) => const ShimmerCard(height: 150)),
      ),
    );
  }
}
