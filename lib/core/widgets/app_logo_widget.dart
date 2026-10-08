import 'package:flutter/material.dart';

/// Pixel-perfect vector render of the App Logo Icon (Mobile Phone with Cyan Rupee symbol).
class AppLogoWidget extends StatelessWidget {
  final double size;

  const AppLogoWidget({
    super.key,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4C44D6),
            Color(0xFF27217B),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27217B).withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(
            color: Colors.white,
            width: size * 0.075,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: size * 0.04),
            // Top Notch/Speaker capsule
            Container(
              width: size * 0.26,
              height: size * 0.04,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(size * 0.02),
              ),
            ),
            // Cyan Rupee Symbol
            Expanded(
              child: Center(
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: size * 0.44,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00E5FF),
                    height: 1.0,
                  ),
                ),
              ),
            ),
            // Bottom Home Button Dot
            Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: size * 0.04),
          ],
        ),
      ),
    );
  }
}
