import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kosh/style/style.dart';
import 'package:kosh/widgets/frosted_glass.dart';

class NavTab {
  const NavTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({
    super.key,
    required this.tabs,
    required this.searchIndex,
    required this.onTap,
    this.isLeftHanded = false,
  }) : assert(searchIndex >= 0 && searchIndex < tabs.length);

  final List<NavTab> tabs;
  final int searchIndex;
  final ValueChanged<int> onTap;
  final bool isLeftHanded;

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
  static const double _tabSize = AppAlbumCover.sm;

  int? _previewIndex;

  bool get _isExpanded => _previewIndex != null;

  double get _expandedHeight => widget.tabs.length * _tabSize;

  List<int> get _orderedIndices => [
    for (var i = 0; i < widget.tabs.length; i++)
      if (i != widget.searchIndex) i,
    widget.searchIndex,
  ];

  void _expand() {
    if (_isExpanded) return;

    setState(() {
      _previewIndex = widget.searchIndex;
    });
  }

  void _collapse() {
    if (!_isExpanded) return;

    setState(() {
      _previewIndex = null;
    });
  }

  void _updatePreview(Offset globalPosition) {
    final indices = _orderedIndices;

    final dockBottom = MediaQuery.sizeOf(context).height - AppInset.bottomMargin(context);

    final distanceFromBottom = (dockBottom - globalPosition.dy).clamp(0.0, _expandedHeight - 0.001);

    final slotFromBottom = (distanceFromBottom / _tabSize).floor();
    final index = indices[indices.length - 1 - slotFromBottom];

    if (_previewIndex == index) return;

    HapticFeedback.selectionClick();

    setState(() {
      _previewIndex = index;
    });
  }

  void _select(int index) {
    widget.onTap(index);
    _collapse();
  }

  void _onDragStart(DragStartDetails details) {
    _expand();
    _updatePreview(details.globalPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updatePreview(details.globalPosition);
  }

  void _onDragEnd(DragEndDetails _) {
    _select(_previewIndex ?? widget.searchIndex);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _previewIndex ?? widget.searchIndex;

    return Positioned(
      left: widget.isLeftHanded ? AppInset.screenEdgePadding : null,
      right: widget.isLeftHanded ? null : AppInset.screenEdgePadding,
      bottom: AppInset.bottomMargin(context),
      width: _tabSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(widget.searchIndex),
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        onVerticalDragCancel: _collapse,
        child: AnimatedContainer(
          duration: AppTiming.sm,
          curve: Curves.easeOutCubic,
          width: _tabSize,
          height: _isExpanded ? _expandedHeight : _tabSize,
          child: FrostedGlassShell(
            radius: _tabSize / 2,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minWidth: _tabSize,
              maxWidth: _tabSize,
              minHeight: _expandedHeight,
              maxHeight: _expandedHeight,
              child: SizedBox(
                width: _tabSize,
                height: _expandedHeight,
                child: Column(
                  children: [
                    for (final index in _orderedIndices)
                      _TabItem(tab: widget.tabs[index], selected: index == activeIndex),
                  ],
                ),
              ),
            ),
          ),
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
    return Semantics(
      selected: selected,
      label: tab.label,
      child: SizedBox.square(
        dimension: AppAlbumCover.sm,
        child: Center(
          child: Icon(tab.icon, size: AppIcon.sm, color: selected ? Colors.white : Colors.white54),
        ),
      ),
    );
  }
}
