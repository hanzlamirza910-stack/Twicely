import 'package:flutter/material.dart';

class ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shapeBorder;

  const ShimmerEffect({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius,
    this.shapeBorder,
  });

  const ShimmerEffect.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shapeBorder = const CircleBorder();

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            shape: widget.shapeBorder ??
                RoundedRectangleBorder(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (t - 0.25).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.25).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PackageCardSkeleton extends StatelessWidget {
  const PackageCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Header Shimmer
          Expanded(
            flex: 46,
            child: ShimmerEffect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.5)),
            ),
          ),
          // Content Metadata Shimmer
          Expanded(
            flex: 54,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag Shimmer
                  ShimmerEffect(width: 80, height: 10, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(height: 6),
                  // Title Shimmer line 1 & 2
                  ShimmerEffect(width: 130, height: 12, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(height: 4),
                  ShimmerEffect(width: 90, height: 12, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(height: 8),
                  // Price Shimmer
                  ShimmerEffect(width: 60, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                  Spacer(),
                  // Merchant Avatar & Name Shimmer
                  Row(
                    children: [
                      ShimmerEffect.circular(size: 16),
                      SizedBox(width: 6),
                      ShimmerEffect(width: 70, height: 10, borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
