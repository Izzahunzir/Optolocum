import 'package:flutter/material.dart';

class AdvertisementStrip extends StatelessWidget {
  const AdvertisementStrip({super.key, this.horizontalPadding = 0});

  final double horizontalPadding;

  static const _images = [
    'assets/images/ads 1.jpg',
    'assets/images/ads 2.jpg',
    'assets/images/ads 3.jpg',
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 14.0;
      // Show two complete cards and a quarter of the third as a scroll cue.
      final cardSize =
          (constraints.maxWidth - horizontalPadding * 2 - spacing * 2) / 2.25;
      return SizedBox(
        height: cardSize,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          itemCount: _images.length,
          separatorBuilder: (_, _) => const SizedBox(width: spacing),
          itemBuilder: (context, index) => SizedBox(
            width: cardSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    _images[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
