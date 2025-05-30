import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  
  const LoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        backgroundColor: Colors.white,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? kBrandColor,
        ),
      ),
    );
  }
}
