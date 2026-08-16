import 'package:flutter/material.dart';
import 'package:kosh/components/bottom_tab_bar.dart';
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
      builder: (context, _) => const AppShell(
        child: Home(title: "Home", color: Colors.blue),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class AppTabData {
  final NavTab tab;
  final Widget page;
  double scrollOffset;

  AppTabData({required this.tab, required this.page, this.scrollOffset = 0.0});
}

class _AppShellState extends State<AppShell> {
  final _scrollOffset = ValueNotifier<double>(0);
  int _selectedIndex = 0;

  final List<AppTabData> _appTabs = [
    AppTabData(
      tab: const NavTab(icon: Icons.home, label: 'Home'),
      page: const Home(title: "Home", color: Colors.blue),
    ),
    AppTabData(
      tab: const NavTab(icon: Icons.library_music, label: 'Library'),
      page: const Home(title: "Library", color: Colors.red),
    ),
    AppTabData(
      tab: const NavTab(icon: Icons.search, label: 'Search'),
      page: const Home(title: "Search", color: Colors.green),
    ),
  ];

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _appTabs.map((data) => data.page).toList();
    final tabs = _appTabs.map((data) => data.tab).toList();

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          ScreenContent(
            onScroll: (offset) {
              _appTabs[_selectedIndex].scrollOffset = offset;
              _scrollOffset.value = offset;
            },
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),

          // renders on top
          TopBar(
            scrollOffset: _scrollOffset,
            child: Row(
              children: [
                Text(
                  _appTabs[_selectedIndex].tab.label,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          BottomTabBar(
            tabs: tabs,
            selectedIndex: _selectedIndex,
            onTap: (i) => setState(() {
              _selectedIndex = i;
              _scrollOffset.value = _appTabs[i].scrollOffset;
            }),
          ),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key, required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(top: AppInsets.topBar(context)),
      itemCount: 20,
      separatorBuilder: (context, index) => Container(
        height: 1,
        margin: const EdgeInsets.only(
          left: 84,
        ), // Align the divider with the text
        color: Colors.white24, // Subtle divider matching the screenshot
      ),
      itemBuilder: (context, i) {
        return GestureDetector(
          behavior:
              HitTestBehavior.opaque, // Ensures the whole row is clickable
          onTap: () {
            // Handle song tap
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
