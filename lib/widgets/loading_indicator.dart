import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  
  const LoadingIndicator({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
