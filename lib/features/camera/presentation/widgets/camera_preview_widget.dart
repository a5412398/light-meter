import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final Widget? child;
  
  const CameraPreviewWidget({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child ?? const SizedBox(),
      ),
    );
  }
}