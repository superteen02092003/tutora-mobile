import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';

/// A single shimmering grey block used to compose skeleton screens.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    super.key,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps skeleton content in a Shimmer with the app's palette.
class SkeletonShimmer extends StatelessWidget {
  const SkeletonShimmer({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.line.withValues(alpha: 0.55),
      highlightColor: AppColors.paper,
      child: child,
    );
  }
}

class TutorDetailSkeleton extends StatelessWidget {
  const TutorDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SkeletonShimmer(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 36, height: 36, shape: BoxShape.circle),
              Row(
                children: [
                  SkeletonBox(width: 36, height: 36, shape: BoxShape.circle),
                  SizedBox(width: 10),
                  SkeletonBox(width: 36, height: 36, shape: BoxShape.circle),
                ],
              ),
            ],
          ),
          SizedBox(height: 18),
          SkeletonBox(width: double.infinity, height: 190, radius: 14),
          SizedBox(height: 20),
          Row(
            children: [
              SkeletonBox(width: 76, height: 76, shape: BoxShape.circle),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: 22),
                    SizedBox(height: 10),
                    SkeletonBox(width: 220, height: 13),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 28),
          SkeletonBox(width: 140, height: 18),
          SizedBox(height: 14),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonBox(width: 240, height: 12),
          SizedBox(height: 28),
          SkeletonBox(width: double.infinity, height: 56, radius: 14),
        ],
      ),
    );
  }
}

/// Skeleton list for the tutor-search / marketplace screen.
class TutorSearchSkeleton extends StatelessWidget {
  const TutorSearchSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const _SearchCardSkeleton(),
      ),
    );
  }
}

class _SearchCardSkeleton extends StatelessWidget {
  const _SearchCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 56, height: 56, shape: BoxShape.circle),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 16),
                SizedBox(height: 10),
                SkeletonBox(width: double.infinity, height: 11),
                SizedBox(height: 6),
                SkeletonBox(width: 200, height: 11),
                SizedBox(height: 12),
                SkeletonBox(width: 90, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
