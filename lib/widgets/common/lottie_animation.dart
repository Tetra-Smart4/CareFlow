import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAnimation extends StatelessWidget {
  final String assetName;
  final double? width;
  final double? height;
  final Widget? fallback;

  const LottieAnimation({
    super.key,
    required this.assetName,
    this.width,
    this.height,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetName,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return fallback ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: Icon(Icons.animation, color: Colors.grey),
              ),
            );
      },
    );
  }
}
