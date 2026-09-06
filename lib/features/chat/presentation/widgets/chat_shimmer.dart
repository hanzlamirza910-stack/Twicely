import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_effect.dart';

/// Skeleton loader for chat conversation list tiles
class ChatConversationSkeletonList extends StatelessWidget {
  final int itemCount;
  const ChatConversationSkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                const ShimmerEffect.circular(size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          ShimmerEffect(width: 130, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                          ShimmerEffect(width: 45, height: 10, borderRadius: BorderRadius.all(Radius.circular(4))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const ShimmerEffect(width: 90, height: 11, borderRadius: BorderRadius.all(Radius.circular(4))),
                      const SizedBox(height: 6),
                      const ShimmerEffect(width: 180, height: 12, borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for chat detail message screen
class ChatDetailSkeleton extends StatelessWidget {
  const ChatDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Package card skeleton
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                const ShimmerEffect(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(8))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerEffect(width: 140, height: 13, borderRadius: BorderRadius.all(Radius.circular(4))),
                      SizedBox(height: 4),
                      ShimmerEffect(width: 80, height: 11, borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
                  ),
                ),
                const ShimmerEffect(width: 70, height: 22, borderRadius: BorderRadius.all(Radius.circular(14))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Message bubble skeletons
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Received message bubble skeleton
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    ShimmerEffect.circular(size: 28),
                    SizedBox(width: 8),
                    ShimmerEffect(width: 190, height: 42, borderRadius: BorderRadius.all(Radius.circular(16))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sent message bubble skeleton
              const Align(
                alignment: Alignment.centerRight,
                child: ShimmerEffect(width: 160, height: 38, borderRadius: BorderRadius.all(Radius.circular(16))),
              ),
              const SizedBox(height: 16),
              // Received message bubble skeleton
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    ShimmerEffect.circular(size: 28),
                    SizedBox(width: 8),
                    ShimmerEffect(width: 220, height: 50, borderRadius: BorderRadius.all(Radius.circular(16))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sent message bubble skeleton
              const Align(
                alignment: Alignment.centerRight,
                child: ShimmerEffect(width: 130, height: 36, borderRadius: BorderRadius.all(Radius.circular(16))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
