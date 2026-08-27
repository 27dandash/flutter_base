import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../config/res/config_imports.dart';
import '../image_widgets/cached_image.dart';

/// Image carousel built on Flutter's native [PageView]. Replaces the
/// `carousel_slider` package — one less dependency, identical UX.
///
/// Features
///   - auto-play with pause-on-touch
///   - tappable dot indicator
///   - rounded corners + cached network images
class CustomImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double? height;
  final double? width;
  final BoxFit? imageFit;
  final bool autoPlay;
  final Duration autoPlayDuration;
  final Curve autoPlayCurve;
  final Duration autoPlayAnimationDuration;
  final BorderRadius? borderRadius;
  final Color? indicatorActiveColor;
  final Color? indicatorInactiveColor;

  const CustomImageCarousel({
    super.key,
    required this.imageUrls,
    this.height,
    this.width,
    this.imageFit,
    this.autoPlay = true,
    this.autoPlayDuration = const Duration(seconds: 3),
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.autoPlayAnimationDuration = const Duration(milliseconds: 400),
    this.borderRadius,
    this.indicatorActiveColor,
    this.indicatorInactiveColor,
  });

  @override
  State<CustomImageCarousel> createState() => _CustomImageCarouselState();
}

class _CustomImageCarouselState extends State<CustomImageCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.imageUrls.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!mounted) return;
      final next = (_currentIndex + 1) % widget.imageUrls.length;
      _pageController.animateToPage(
        next,
        duration: widget.autoPlayAnimationDuration,
        curve: widget.autoPlayCurve,
      );
    });
  }

  void _pauseAutoPlay() => _autoPlayTimer?.cancel();
  void _resumeAutoPlay() {
    if (widget.autoPlay && widget.imageUrls.length > 1) _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(AppCircular.r2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          width: widget.width ?? double.infinity,
          child: GestureDetector(
            onTapDown: (_) => _pauseAutoPlay(),
            onTapUp: (_) => _resumeAutoPlay(),
            onTapCancel: _resumeAutoPlay,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: radius,
                child: CachedImage(
                  url: widget.imageUrls[index],
                  width: widget.width ?? double.infinity,
                  height: widget.height,
                  fit: widget.imageFit ?? BoxFit.cover,
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSize.sH10),
        _Indicator(
          count: widget.imageUrls.length,
          current: _currentIndex,
          activeColor: widget.indicatorActiveColor ?? AppColors.forth,
          inactiveColor: widget.indicatorInactiveColor ?? AppColors.border,
          onTap: (i) => _pageController.animateToPage(
            i,
            duration: widget.autoPlayAnimationDuration,
            curve: widget.autoPlayCurve,
          ),
        ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.count,
    required this.current,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final int count;
  final int current;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == current;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? AppSize.sW20 : AppSize.sH8,
            height: AppSize.sH2,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppCircular.r20),
              color: active ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}
