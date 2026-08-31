import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:kosh/style/style.dart';

class SongInfo extends StatelessWidget {
  const SongInfo({
    super.key,
    required this.title,
    required this.artist,
    required this.titleStyle,
    required this.artistStyle,
    this.spacing = 2.0,
    this.alignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.format,
  });

  final String title;
  final String artist;
  final String? format;
  final TextStyle titleStyle;
  final TextStyle artistStyle;
  final double spacing;
  final CrossAxisAlignment alignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final localFormat = format;
    return Column(
      crossAxisAlignment: alignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),

        Row(
          children: [
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: artistStyle,
            ),

            if (localFormat != null) ...[
              SizedBox(width: spacing),
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppSpacing.xs6,
                  horizontal: AppSpacing.xs5,
                ),
                decoration: ShapeDecoration(
                  color: Color(0xff141312),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(cornerRadius: AppRadii.xs),
                  ),
                ),

                child: Text(
                  localFormat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 7.5,
                    fontWeight: .w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Source - https://stackoverflow.com/a/51776987
// Posted by leodriesch, modified by community. See post 'Timeline' for change history
// Retrieved 2026-08-30, License - CC BY-SA 4.0

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final Duration animationDuration, backDuration, pauseDuration;

  const MarqueeWidget({
    Key? key,
    required this.child,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController(initialScrollOffset: 50.0);
    WidgetsBinding.instance.addPostFrameCallback(scroll);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: widget.child,
      scrollDirection: widget.direction,
      controller: scrollController,
    );
  }

  void scroll(_) async {
    while (scrollController.hasClients) {
      await Future.delayed(widget.pauseDuration);
      if (scrollController.hasClients) {
        await scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: widget.animationDuration,
          curve: Curves.ease,
        );
      }
      await Future.delayed(widget.pauseDuration);
      if (scrollController.hasClients) {
        await scrollController.animateTo(
          0.0,
          duration: widget.backDuration,
          curve: Curves.easeOut,
        );
      }
    }
  }
}
