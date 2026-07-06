import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package_detail_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Generate mock packages for this category
    final mockPackages = [
      {
        'title': 'Premium 5-Session Pass for $categoryName',
        'originalPrice': 'S\$250.00',
        'resalePrice': 'S\$120.00',
        'discount': '52% OFF',
        'tag': 'FOR HER • $categoryName',
        'image': 'assets/images/package_yoga.jpg',
      },
      {
        'title': 'Introductory Session Package ($categoryName)',
        'originalPrice': 'S\$80.00',
        'resalePrice': 'S\$45.00',
        'discount': '43% OFF',
        'tag': 'GENERAL • $categoryName',
        'image': 'assets/images/package_spa.jpg',
      },
      {
        'title': 'Weekend Special Pass ($categoryName)',
        'originalPrice': 'S\$150.00',
        'resalePrice': 'S\$90.00',
        'discount': '40% OFF',
        'tag': 'FOR HIM • $categoryName',
        'image': 'assets/images/package_gym.jpg',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EA),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Recoleta Alt',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category info header banner
            Container(
              color: const Color(0xFFFFF8EA),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(categoryIcon, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore $categoryName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Verified resale deals from our trusted community.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Search Bar inside category
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search within $categoryName...',
                    hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),

            // Deals List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockPackages.length,
                itemBuilder: (context, index) {
                  final pkg = mockPackages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PackageDetailScreen(package: pkg),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Package Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                pkg['image'] as String,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Content details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        pkg['tag'] as String,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF27B6E),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF176),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          pkg['discount'] as String,
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pkg['title'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        pkg['originalPrice'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black38,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        pkg['resalePrice'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
