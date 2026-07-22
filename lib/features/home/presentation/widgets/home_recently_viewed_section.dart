import 'package:flutter/material.dart';
import '../../../../core/widgets/marketplace_package_card.dart';

class HomeRecentlyViewedSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic> package) onPackageTap;

  const HomeRecentlyViewedSection({
    super.key,
    required this.items,
    required this.onPackageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'RECENTLY VIEWED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.black45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(items.length.clamp(0, 2), (index) {
                final pkg = items[index];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == 0 && items.length > 1 ? 14.0 : 0.0,
                    ),
                    child: MarketplacePackageCard(
                      package: pkg,
                      isFavorite: pkg['hasHeart'] == true,
                      onTap: () => onPackageTap(pkg),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
