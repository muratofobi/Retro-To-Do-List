import 'package:flutter/material.dart';

class RetroCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const RetroCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF282A45),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE5A96A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
