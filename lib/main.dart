import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kosh/components/bottom_tab_bar.dart';
import 'package:kosh/components/player_dock.dart';
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
      // showPerformanceOverlay: true,
      color: Colors.black,
      builder: (context, _) => Overlay(
        initialEntries: [OverlayEntry(builder: (context) => const AppShell())],
      ),
    );
  }
}

enum AppTab {
  home(label: 'Home', icon: CupertinoIcons.music_note_list, color: Colors.blue),
  library(
    label: 'Library',
    icon: CupertinoIcons.square_grid_2x2,
    color: Colors.red,
  ),
  search(label: 'Search', icon: CupertinoIcons.search, color: Colors.green);

  final dynamic label;
  final dynamic icon;
  final dynamic color;

  const AppTab({required this.label, required this.icon, required this.color});

  NavTab get navTab => NavTab(icon: icon, label: label);
  Widget buildPage() => PHSongList(title: label, color: color);
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.child});

  final Widget? child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final _scrollOffset = ValueNotifier<double>(0);
  double _lastOffset = 0.0;
  double _scrollAccumulator = 0.0;
  final _isBottomBarVisible = ValueNotifier<bool>(true);
  final _isPlayerSheetOpen = ValueNotifier<bool>(false);

  final scrollOffsets = List<double>.filled(AppTab.values.length, 0.0);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = AppTab.values.map((t) => t.buildPage()).toList();
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _isBottomBarVisible.dispose();
    _isPlayerSheetOpen.dispose();
    super.dispose();
  }

  void _handleScroll(double offset) {
    final deltaSinceLastFrame = offset - _lastOffset;
    _lastOffset = offset;

    if (offset <= 0) {
      _isBottomBarVisible.value = true;
      _scrollAccumulator = 0.0;
    } else {
      if (deltaSinceLastFrame > 0) {
        if (_scrollAccumulator < 0) _scrollAccumulator = 0.0;
        _scrollAccumulator += deltaSinceLastFrame;

        if (_scrollAccumulator > 10.0) {
          _isBottomBarVisible.value = false;
        }
      } else if (deltaSinceLastFrame < 0) {
        if (_scrollAccumulator > 0) _scrollAccumulator = 0.0;
        _scrollAccumulator += deltaSinceLastFrame;

        if (_scrollAccumulator < -10.0) {
          _isBottomBarVisible.value = true;
        }
      }
    }

    scrollOffsets[_selectedIndex] = offset;
    _scrollOffset.value = offset;
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isBottomBarVisible.value = true;
      _lastOffset = scrollOffsets[index];
      _scrollAccumulator = 0.0;
      _scrollOffset.value = scrollOffsets[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = AppTab.values.map((t) => t.navTab).toList();

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          ScreenContent(
            onScroll: _handleScroll,
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
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
            onTap: _onTabTapped,
          ),
          PlayerDock(
            isOpenNotifier: _isPlayerSheetOpen,
            isBottomBarVisibleNotifier: _isBottomBarVisible,
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
        top: AppInset.topBarHeight(context),
        bottom: AppInset.totalBottomheight(context),
      ),
      itemCount: 32,
      separatorBuilder: (context, index) => Container(
        height: 1,
        margin: const EdgeInsets.only(
          left: 75,
          right: AppInset.screenEdgePadding,
        ),
        color: Colors.white12,
      ),
      itemBuilder: (context, i) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppInset.screenEdgePadding,
              vertical: AppInset.screenEdgePadding,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: color.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: const Icon(Icons.music_note, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
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
                      const SizedBox(height: AppSpacing.xs3),
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
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
