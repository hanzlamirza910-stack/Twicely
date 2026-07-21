import 'package:flutter/material.dart';
import 'shimmer_effect.dart';

class PackageImageCarousel extends StatefulWidget {
  final List<String> images;
  final String fallbackImage;
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const PackageImageCarousel({
    super.key,
    required this.images,
    this.fallbackImage = 'assets/images/package_spa.jpg',
    this.height = double.infinity,
    this.width = double.infinity,
    this.borderRadius = BorderRadius.zero,
    this.onTap,
  });

  @override
  State<PackageImageCarousel> createState() => _PackageImageCarouselState();
}

class _PackageImageCarouselState extends State<PackageImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.images.where((img) => img.isNotEmpty && !img.startsWith('assets/')).toList();
    if (displayImages.isEmpty) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            color: const Color(0xFFE8EFF8),
            child: const Icon(Icons.image_not_supported_rounded, color: Colors.black26, size: 32),
          ),
        ),
      );
    }

    Widget buildImage(String imgUrl) {
      if (imgUrl.startsWith('assets/')) {
        return Image.asset(
          imgUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE8EFF8),
            child: const Icon(Icons.image_not_supported_rounded, color: Colors.black26, size: 32),
          ),
        );
      } else {
        return Image.network(
          imgUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const ShimmerEffect(
              borderRadius: BorderRadius.zero,
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE8EFF8),
            child: const Icon(Icons.image_not_supported_rounded, color: Colors.black26, size: 32),
          ),
        );
      }
    }

    if (displayImages.length <= 1) {
      return GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox(
            height: widget.height,
            width: widget.width,
            child: buildImage(displayImages.first),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: displayImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return buildImage(displayImages[index]);
                },
              ),
              // Dots/Line Indicator
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(displayImages.length, (index) {
                    final isSelected = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 5,
                      width: isSelected ? 12 : 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
