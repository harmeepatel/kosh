import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kosh/components/nav.dart';
import 'package:kosh/components/screen_content.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: Colors.black,
      builder: (context, _) => const AppShell(child: PlaceholderTab()),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          ScreenContent(
            onScroll: (offset) => _scrollOffset.value = offset,
            child: widget.child,
          ),

          TopBar(
            scrollOffset: _scrollOffset,
            child: Row(
              children: [Text('Home', style: TextStyle(fontSize: 32, fontWeight: .w200))],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          for (var i = 0; i < 10; ++i)
            Container(
              width: 300,
              height: 300,
              color: Colors.blue.withAlpha(Random().nextInt(256)),
              alignment: .center,
              child: Text(
                '$i',
                style: TextStyle(fontSize: 24, fontWeight: .w100),
              ),
            ),
        ],
      ),
    );
  }
}
