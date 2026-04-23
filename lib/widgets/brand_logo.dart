import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  static const String logoUrl =
      'https://res.cloudinary.com/dqsacd9ez/image/upload/v1776962386/PawMatch_upljxz.png';

  final double? width;
  final double? height;
  final BoxFit fit;

  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      logoUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.pets_rounded)),
        );
      },
    );
  }
}
