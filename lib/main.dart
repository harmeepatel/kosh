import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kosh/components/top_bar.dart';
import 'package:kosh/components/screen_content.dart';
import 'package:kosh/style.dart';

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
      builder: (context, _) => const AppShell(child: Home()),
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
              children: [
                Text('Home', style: TextStyle(fontSize: 32, fontWeight: .w700)),
                // TODO: currently this button also shrinks on scroll, make it so only text scales and nothing else
                // ElevatedButton.icon(
                //   label: Text('asdf'),
                //   icon: const Icon(CupertinoIcons.cube),
                //   onPressed: () {
                //     print("asdf");
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(top: AppInsets.topBar(context)),
      itemCount: 20,
      itemBuilder: (context, i) {
        return Center(
          child: Container(
            height: 150,
            width: 300,
            color: Colors.blue.withAlpha(250 - ((i + 1) * 10).clamp(0, 200)),
            alignment: Alignment.center,
            child: Text(
              "$i asdfasdfasdfasdfadfasdfasdfdsfasdfasdfasdfadfadsfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfa",
            ),
          ),
        );
      },
    );
  }
}

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // We still need the top padding so content doesn't hide under the TopBar
      padding: EdgeInsets.only(top: AppInsets.topBar(context)),
      itemCount: 20,
      itemBuilder: (context, i) {
        return Container(
          height: 150,
          color: Colors.blue.withAlpha(250 - ((i + 1) * 10).clamp(0, 200)),
          alignment: Alignment.center,
          child: Text(
            '$title - Item $i',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        );
      },
    );
  }
}
