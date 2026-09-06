import 'package:flutter/material.dart';
import 'shimmer_effect.dart';

class PackageImageCarousel extends StatefulWidget {
  final List<String> images;
  final String fallbackImage;
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool showThumbnails;

  const PackageImageCarousel({
    super.key,
    required this.images,
    this.fallbackImage = 'assets/images/package_spa.jpg',
    this.height = double.infinity,
    this.width = double.infinity,
    this.borderRadius = BorderRadius.zero,
    this.onTap,
    this.showThumbnails = true,
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
    var displayImages = widget.images.where((img) => img.trim().isNotEmpty).toList();
    if (displayImages.isEmpty && widget.fallbackImage.isNotEmpty) {
      displayImages = [widget.fallbackImage];
    }
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

    Widget mainSlider = GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: displayImages.length <= 1
              ? buildImage(displayImages.first)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
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
                    // Counter badge (Top Right e.g. 1/3)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPage + 1}/${displayImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Dots Indicator
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(displayImages.length, (index) {
                          final isSelected = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: isSelected ? 16 : 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 3,
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

    if (displayImages.length <= 1 || !widget.showThumbnails) {
      return mainSlider;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        mainSlider,
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayImages.length,
            itemBuilder: (context, idx) {
              final isSelected = idx == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    idx,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF232D52) : Colors.black.withValues(alpha: 0.12),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        buildImage(displayImages[idx]),
                        if (!isSelected)
                          Container(
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
