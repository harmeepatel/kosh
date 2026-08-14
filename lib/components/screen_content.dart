import 'package:flutter/cupertino.dart';
import '../style.dart';

class ScreenContent extends StatelessWidget {
  const ScreenContent({super.key, required this.child, this.onScroll});

  final Widget child;
  final ValueChanged<double>? onScroll;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        onScroll?.call(notification.metrics.pixels);
        return false;
      },
      child: ListView(
        padding: EdgeInsets.only(top: AppInsets.topBar(context)),
        children: [child],
      ),
    );
  }
}
