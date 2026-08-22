import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kosh/components/frosted_glass.dart';
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

  static final _blobBlurFilter = ImageFilter.blur(
    sigmaX: AppBlur.md,
    sigmaY: AppBlur.md,
  );

  int? _previewIndex;

  final ValueNotifier<double> _blobPosition = ValueNotifier(0.0);
  final ValueNotifier<bool> _isInteracting = ValueNotifier(false);

  @override
  void dispose() {
    _blobPosition.dispose();
    _isInteracting.dispose();
    super.dispose();
  }

  int get _activeIndex => _previewIndex ?? widget.selectedIndex;

  double _calculateBlobDx(double localDx) {
    return localDx + AppSpacing.xs - (_blobWidth / 2);
  }

  void _updateInteraction(Offset localPosition) {
    final index = _indexForPosition(localPosition.dx);

    _isInteracting.value = true;
    _blobPosition.value = _calculateBlobDx(localPosition.dx);

    if (_previewIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _previewIndex = index;
      });
    }
  }

  void _startInteraction(Offset localPosition) {
    setState(() {
      _isInteracting.value = true;
      _blobPosition.value = _calculateBlobDx(localPosition.dx);
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

  void _endInteraction() {
    setState(() {
      _previewIndex = null;
      _isInteracting.value = false;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _updateInteraction(details.localPosition);
    _commitInteraction();
  }

  void _expandNav() {
    if (widget.isVisibleNotifier is ValueNotifier<bool>) {
      (widget.isVisibleNotifier as ValueNotifier<bool>).value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final navHeight = AppInset.navBarHeight();
    final collapsedWidth = navHeight;
    final expandedWidth =
        (widget.tabs.length * _tabWidth) + (AppSpacing.sm * 2);

    final expandedLeft = (screenWidth - expandedWidth) / 2;
    final collapsedLeft = AppInset.screenEdgePadding;
    final bottomMargin = AppInset.bottomMargin(context);

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isVisibleNotifier,
      builder: (context, isVisible, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isVisible ? 1.0 : 0.0),
          duration: AppTiming.md,
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) {
            final currentWidth = lerpDouble(
              collapsedWidth,
              expandedWidth,
              progress,
            )!;
            final currentLeft = lerpDouble(
              collapsedLeft,
              expandedLeft,
              progress,
            )!;

            return Positioned(
              left: currentLeft,
              bottom: bottomMargin,
              width: currentWidth,
              height: navHeight,
              child: GestureDetector(
                onTap: isVisible ? null : _expandNav,
                child: ClipRRect(
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(navHeight / 2),
                  child: FrostedGlassShell(
                    radius: navHeight / 2,
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0x20000000)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - progress * 2).clamp(0.0, 1.0),
                            child: _TabItem(
                              tab: widget.tabs[_activeIndex],
                              selected: true,
                            ),
                          ),
                          Opacity(
                            opacity: ((progress - 0.5) * 2).clamp(0.0, 1.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: SizedBox(
                                width: expandedWidth,
                                height: navHeight,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _buildInteractionBlob(),
                                    _buildTabs(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabs() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) =>
          _updateInteraction(details.localPosition),
      onHorizontalDragUpdate: (details) =>
          _updateInteraction(details.localPosition),
      onHorizontalDragEnd: (_) => _commitInteraction(),
      onHorizontalDragCancel: _endInteraction,
      onTapDown: (details) => _startInteraction(details.localPosition),
      onTapUp: _handleTapUp,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.tabs.length; i++)
            SizedBox(
              width: _tabWidth,
              child: _TabItem(tab: widget.tabs[i], selected: i == _activeIndex),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionBlob() {
    return ValueListenableBuilder<double>(
      valueListenable: _blobPosition,
      builder: (context, position, child) {
        return Positioned(
          top: 0,
          bottom: 0,
          left: position,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isInteracting,
            builder: (context, interacting, _) {
              return AnimatedOpacity(
                opacity: interacting ? 1 : 0,
                duration: AppTiming.sm,
                curve: Curves.easeInCubic,
                child: ImageFiltered(
                  imageFilter: _blobBlurFilter,
                  child: Container(
                    width: _blobWidth,
                    height: _blobWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
      color: selected
          ? Colors.red.shade500.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.6),
      size: AppGeometry.bottomNavIconSize,
    );
  }
}
