import 'dart:ui';

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
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
  static const _tabWidth = 48.0;
  static const _blobWidth = 64.0;

  static const _interactionDuration = Duration(milliseconds: 200);
  static const _blobAnimationDuration = Duration(milliseconds: 80);

  static final _blurFilter = ImageFilter.blur(
    sigmaX: Spacing.xs5,
    sigmaY: Spacing.xs5,
  );

  static final _blobBlurFilter = ImageFilter.blur(sigmaX: 30, sigmaY: 30);

  int? _previewIndex;
  double _blobPosition = 0;
  bool _isInteracting = false;

  int get _activeIndex => _previewIndex ?? widget.selectedIndex;

  void _updateInteraction(Offset localPosition) {
    final position = localPosition.dx - Spacing.xs;
    final index = _indexForPosition(position);

    setState(() {
      _isInteracting = true;
      _blobPosition = position;
    });

    if (_previewIndex != index) {
      HapticFeedback.lightImpact();

      setState(() {
        _previewIndex = index;
      });
    }
  }

  int _indexForPosition(double position) {
    final index = (position / _tabWidth).floor();

    return index.clamp(0, widget.tabs.length - 1);
  }

  void _startInteraction(Offset localPosition) {
    setState(() {
      _isInteracting = true;
      _blobPosition = localPosition.dx;
    });
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
      child: SafeArea(
        top: false,
        bottom: false,
        minimum: EdgeInsets.only(bottom: AppGeometry.bottomPadding),
        child: Center(child: _buildBar()),
      ),
    );
  }

  Widget _buildBar() {
    return Container(
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      decoration: const ShapeDecoration(
        color: Color(0x20000000),
        shape: StadiumBorder(),
      ),
      child: BackdropFilter(
        filter: _blurFilter,
        child: Stack(
          alignment: Alignment.center,
          children: [_buildInteractionBlob(), _buildTabs()],
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
        duration: _interactionDuration,
        curve: Curves.easeOut,
        child: ImageFiltered(
          imageFilter: _blobBlurFilter,
          child: AnimatedContainer(
            duration: _blobAnimationDuration,
            curve: Curves.easeInOut,
            width: _blobWidth,
            height: _blobWidth,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: Spacing.sm,
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
      color: selected ? Colors.red.shade400 : const Color(0xffcccccc),
      size: 24,
    );
  }
}
