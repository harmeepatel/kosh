import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cupertino_symbols/flutter_cupertino_symbols.dart';
import 'package:audio_service/audio_service.dart';
import 'package:kosh/pages/song_library.dart';
import 'package:kosh/player/audio_handler.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/style/style.dart';
import 'package:kosh/widgets/bottom_tab_bar.dart';
import 'package:kosh/widgets/player_dock.dart';
import 'package:kosh/widgets/screen_content.dart';
import 'package:kosh/widgets/song_list_tile.dart';
import 'package:kosh/widgets/top_bar.dart';
import 'package:kosh/player/state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init<KoshAudioHandler>(
    builder: KoshAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'app.kosh.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationOngoing: true,
      preloadArtwork: true,
    ),
  );

  PlayerState.initialize(audioHandler);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: AppColors.background,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => Theme(
            data: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: AppColors.background),
            child: const AppShell(),
          ),
        );
      },
    );
  }
}

enum AppTab {
  home(label: 'Home', icon: SFSymbols.music_note_list, color: Colors.blue),
  library(label: 'Library', icon: SFSymbols.square_grid_2x2, color: Colors.red),
  search(label: 'Search', icon: SFSymbols.magnifyingglass, color: Colors.green);

  const AppTab({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  NavTab get navTab => NavTab(icon: icon, label: label);

  Widget buildPage() {
    switch (this) {
      case AppTab.home:
        return const SongListView();
      case AppTab.library:
      case AppTab.search:
        return PlaceholderSongList(title: label, color: color);
    }
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);
  final ValueNotifier<bool> _isPlayerSheetOpen = ValueNotifier<bool>(false);
  final List<double> _scrollOffsets = List<double>.filled(AppTab.values.length, 0);

  late final List<Widget> _pages = [for (final tab in AppTab.values) tab.buildPage()];

  @override
  void dispose() {
    _scrollOffset.dispose();
    _isPlayerSheetOpen.dispose();
    super.dispose();
  }

  void _handleScroll(double offset) {
    _scrollOffsets[_selectedIndex] = offset;
    if (_scrollOffset.value != offset) {
      _scrollOffset.value = offset;
    }
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);
    _scrollOffset.value = _scrollOffsets[index];
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = AppTab.values[_selectedIndex];

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          ScreenContent(
            onScroll: _handleScroll,
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
          TopBar(
            scrollOffset: _scrollOffset,
            title: Text(currentTab.label, style: AppTextStyles.header),
          ),
          BottomTabBar(
            tabs: [for (final tab in AppTab.values) tab.navTab],
            searchIndex: AppTab.search.index,
            onTap: _onTabTapped,
          ),
          PlayerDock(isOpenNotifier: _isPlayerSheetOpen),
        ],
      ),
    );
  }
}

class PlaceholderSongList extends StatelessWidget {
  const PlaceholderSongList({super.key, required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(top: AppInset.topBarHeight(context), bottom: AppInset.totalBottomHeight(context)),
      itemCount: 32,
      separatorBuilder: (context, index) => Container(
        height: 1,
        margin: const EdgeInsets.only(left: AppInset.listSeparatorLeft, right: AppInset.screenEdgePadding),
        color: AppColors.divider,
      ),
      itemBuilder: (context, index) => SongListTile(
        song: Song(
          id: 'placeholder_$index',
          title: '$title Song ${index + 1}',
          artist: 'Artist Name',
          filePath: '',
          length: 128,
          format: 'test',
        ),
      ),
    );
  }
}
