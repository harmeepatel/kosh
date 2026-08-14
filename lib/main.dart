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
  final scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          ScreenContent(
            child: widget.child,
          ),
          TopAppBar(
            scrollOffset: scrollOffset,
            children: const [Text('Hello')],
          ),
        ],
      ),
    );
  }
}

// class MainApp extends StatefulWidget {
//   const MainApp({super.key});

//   @override
//   State<MainApp> createState() => _MainAppState();
// }

// class _MainAppState extends State<MainApp> {
//   final scrollOffset = ValueNotifier<double>(0);

//   @override
//   void dispose() {
//     scrollOffset.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WidgetsApp(
//       debugShowCheckedModeBanner: false,
//       showPerformanceOverlay: false,
//       color: Colors.black,
//       builder: (context, child) {
//         return ColoredBox(
//           color: Colors.black,
//           child: Stack(
//             children: [
//               NotificationListener<ScrollNotification>(
//                 onNotification: (n) {
//                   scrollOffset.value = n.metrics.pixels;
//                   return false;
//                 },
//                 child: const ScreenContent(child: PlaceholderTab()),
//               ),
//               TopAppBar(scrollOffset: scrollOffset, children: [Text("hello")]),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

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
              child: Text('$i'),
            ),
        ],
      ),
    );
  }
}
