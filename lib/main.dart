import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kosh/components/bottom_tab_bar.dart';
import 'package:kosh/components/top_bar.dart';
import 'package:kosh/components/screen_content.dart';
import 'package:kosh/style.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: Colors.black,
      builder: (context, _) => const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.child});

  final Widget? child;

  @override
  State<AppShell> createState() => _AppShellState();
}

enum AppTab {
  home(label: 'Home', icon: CupertinoIcons.music_note_list, color: Colors.blue),
  library(
    label: 'Library',
    icon: CupertinoIcons.square_grid_2x2,
    color: Colors.red,
  ),
  search(label: 'Search', icon: CupertinoIcons.search, color: Colors.green);

  const AppTab({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  NavTab get navTab => NavTab(icon: icon, label: label);
  Widget buildPage() => PHSongList(title: label, color: color);
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final _scrollOffset = ValueNotifier<double>(0);
  double _lastOffset = 0.0;
  double _scrollAccumulator = 0.0;
  final _isBottomBarVisible = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final List<Widget> pages = AppTab.values
        .map((t) => t.buildPage())
        .toList();
    final tabs = AppTab.values.map((t) => t.navTab).toList();
    final scrollOffsets = List<double>.filled(AppTab.values.length, 0.0);

    onScroll(offset) {
      final deltaSinceLastFrame = offset - _lastOffset;
      _lastOffset = offset;

      // always show bottom bar if at top
      if (offset <= 0) {
        _isBottomBarVisible.value = true;
        _scrollAccumulator = 0.0;
      } else {
        if (deltaSinceLastFrame > 0) {
          // Scrolling Down
          if (_scrollAccumulator < 0) {
            _scrollAccumulator = 0.0;
          }
          _scrollAccumulator += deltaSinceLastFrame;

          if (_scrollAccumulator > AppTimings.scrollBuffer) {
            _isBottomBarVisible.value = false;
          }
        } else if (deltaSinceLastFrame < 0) {
          // Scrolling Up
          if (_scrollAccumulator > 0) {
            _scrollAccumulator = 0.0; // Reset if direction changed
          }
          _scrollAccumulator += deltaSinceLastFrame;

          if (_scrollAccumulator < -AppTimings.scrollBuffer) {
            _isBottomBarVisible.value = true;
          }
        }
      }

      scrollOffsets[_selectedIndex] = offset;
      _scrollOffset.value = offset;
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          ScreenContent(
            onScroll: onScroll,
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),

          // renders on top
          TopBar(
            scrollOffset: _scrollOffset,
            title: Text(
              AppTab.values[_selectedIndex].label,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
          ),

          BottomTabBar(
            isVisibleNotifier: _isBottomBarVisible,
            tabs: tabs,
            selectedIndex: _selectedIndex,
            onTap: (i) => setState(() {
              _selectedIndex = i;
              _isBottomBarVisible.value = true;

              // reset
              _lastOffset = scrollOffsets[i];
              _scrollAccumulator = 0.0;
              _scrollOffset.value = scrollOffsets[i];
            }),
          ),
        ],
      ),
    );
  }
}

class PHSongList extends StatelessWidget {
  const PHSongList({super.key, required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(
        top: AppInsets.topBarHeight(context),
        bottom: AppInsets.bottomNavHeight,
      ),
      itemCount: 32,
      separatorBuilder: (context, index) => Container(
        height: 1,
        margin: const EdgeInsets.only(left: 75),
        color: Colors.white12,
      ),
      itemBuilder: (context, i) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Handle song tap
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppGeometry.screenEdgePadding,
              vertical: AppGeometry.screenEdgePadding,
            ),
            child: Row(
              children: [
                // Album Art Placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: color.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: const Icon(Icons.music_note, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 16),

                // Song Title & Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Song Title ${i + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Artist Name",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // More Options Icon
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
