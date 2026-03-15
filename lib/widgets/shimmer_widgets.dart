import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final scaledRadius = BorderRadius.only(
      topLeft: Radius.circular(borderRadius.topLeft.x.r),
      topRight: Radius.circular(borderRadius.topRight.x.r),
      bottomLeft: Radius.circular(borderRadius.bottomLeft.x.r),
      bottomRight: Radius.circular(borderRadius.bottomRight.x.r),
    );

    return Shimmer.fromColors(
      baseColor: AppTheme.primary.withOpacity(0.5),
      highlightColor: AppTheme.surface,
      child: Container(
        margin: EdgeInsets.only(
          left: margin.left.w,
          right: margin.right.w,
          top: margin.top.h,
          bottom: margin.bottom.h,
        ),
        height: height.h,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: scaledRadius,
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
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Shimmer.fromColors(
              baseColor: AppTheme.primary.withOpacity(0.5),
              highlightColor: AppTheme.surface,
              child: Container(
                height: 24.h,
                width: 150.w,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
          // Card shimmers
          ...List.generate(count, (_) => ShimmerCard(height: 140.h)),
          SizedBox(height: 16.h),
          // Prompt shimmer
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: AppTheme.primary.withOpacity(0.5),
                  highlightColor: AppTheme.surface,
                  child: Container(
                    height: 32.h,
                    width: 200.w,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Shimmer.fromColors(
                  baseColor: AppTheme.primary.withOpacity(0.5),
                  highlightColor: AppTheme.surface,
                  child: Container(
                    height: 20.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6.r),
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
        children: List.generate(5, (_) => ShimmerCard(height: 150.h)),
      ),
    );
  }
}
