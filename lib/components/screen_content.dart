import 'package:flutter/cupertino.dart';

class ScreenContent extends StatelessWidget {
  const ScreenContent({super.key, required this.child, this.onScroll});

  final Widget child;
  final ValueChanged<double>? onScroll;

  @override
  Widget build(BuildContext context) {
    if (onScroll == null) return child;

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        onScroll!(notification.metrics.pixels);
        return false;
      },
      child: child,
    );
  }
}
