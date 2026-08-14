import 'package:flutter/cupertino.dart';
import '../style.dart';

class ScreenContent extends StatelessWidget {
  const ScreenContent({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: Scale.topBarInset(context)),
      child: child,
    );
  }
}
