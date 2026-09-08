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
    this.spacing = 2,
    this.alignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.format,
    this.showFormat = true,
  });

  final String title;
  final String artist;
  final String? format;
  final bool showFormat;
  final TextStyle titleStyle;
  final TextStyle artistStyle;
  final double spacing;
  final CrossAxisAlignment alignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
        Row(
          children: [
            Flexible(
              child: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: artistStyle),
            ),
            if (format != null && showFormat) ...[
              SizedBox(width: spacing),
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs6, horizontal: AppSpacing.xs5),
                decoration: ShapeDecoration(
                  color: const Color(0xff141312),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: AppRadii.xs,
                      cornerSmoothing: AppRadii.cornerSmoothing,
                    ),
                  ),
                ),
                child: Text(
                  format!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white30, fontSize: 7.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
