import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kosh/style.dart';

class NavTab {
  const NavTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({
    super.key,
    required this.isVisibleNotifier,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<NavTab> tabs;
  final int selectedIndex;
  final ValueListenable<bool> isVisibleNotifier;
  final ValueChanged<int> onTap;

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
  static const _tabWidth = AppGeometry.bottomNavIconSize * 2;
  static const _blobWidth = 200.0;

  static final _blurFilter = ImageFilter.blur(
    sigmaX: AppBlur.bottomNavBlur,
    sigmaY: AppBlur.bottomNavBlur,
  );

  static final _blobBlurFilter = ImageFilter.blur(sigmaX: 32, sigmaY: 32);

  int? _previewIndex;
  double _blobPosition = 0;
  bool _isInteracting = false;

  int get _activeIndex => _previewIndex ?? widget.selectedIndex;

  void _updateInteraction(Offset localPosition) {
    final index = _indexForPosition(localPosition.dx);
    final blobLeftEdge = localPosition.dx + Spacing.xs - (_blobWidth / 2);

    setState(() {
      _isInteracting = true;
      _blobPosition = blobLeftEdge;
    });

    if (_previewIndex != index) {
      HapticFeedback.lightImpact();

      setState(() {
        _previewIndex = index;
      });
    }
  }

  void _startInteraction(Offset localPosition) {
    setState(() {
      _isInteracting = true;
      _blobPosition = localPosition.dx + Spacing.xs - (_blobWidth / 2);
    });
  }

  int _indexForPosition(double localDx) {
    final index = (localDx / _tabWidth).floor();
    return index.clamp(0, widget.tabs.length - 1);
  }

  void _commitInteraction() {
    final index = _previewIndex;

    if (index != null) {
      widget.onTap(index);
    }

    _endInteraction();
  }

  void _cancelInteraction() {
    _endInteraction();
  }

  void _endInteraction() {
    setState(() {
      _previewIndex = null;
      _isInteracting = false;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _updateInteraction(details.localPosition);
    _commitInteraction();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.isVisibleNotifier,
        builder: (context, isVisible, _) {
          return AnimatedScale(
            scale: isVisible ? 1.0 : 0.618,
            duration: AppTiming.md,
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              bottom: false,
              minimum: EdgeInsets.only(bottom: AppGeometry.bottomPadding),
              child: Center(child: _buildBar()),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBar() {
    return ClipRRect(
      clipBehavior: .antiAlias,
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: _blurFilter,
        child: Container(
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          decoration: const BoxDecoration(color: Color(0x20000000)),
          child: Stack(
            alignment: Alignment.center,
            children: [_buildInteractionBlob(), _buildTabs()],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionBlob() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: _blobPosition,
      child: AnimatedOpacity(
        opacity: _isInteracting ? 1 : 0,
        duration: AppTiming.sm,
        curve: Curves.easeInCubic,
        child: ImageFiltered(
          imageFilter: _blobBlurFilter,
          child: AnimatedContainer(
            duration: AppTiming.sm,
            curve: Curves.easeInCubic,
            width: _blobWidth,
            height: _blobWidth,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppGeometry.bottomNavPadding,
        vertical: AppGeometry.bottomNavPadding,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) =>
            _updateInteraction(details.localPosition),
        onHorizontalDragUpdate: (details) =>
            _updateInteraction(details.localPosition),
        onHorizontalDragEnd: (_) => _commitInteraction(),
        onHorizontalDragCancel: _cancelInteraction,
        onTapDown: (details) => _startInteraction(details.localPosition),
        onTapUp: _handleTapUp,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              SizedBox(
                width: _tabWidth,
                child: _TabItem(
                  tab: widget.tabs[i],
                  selected: i == _activeIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected});

  final NavTab tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      tab.icon,
      color: selected ? Colors.red.shade600 : const Color(0xffbcbcbc),
      size: AppGeometry.bottomNavIconSize,
    );
  }
}
