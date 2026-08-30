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
        SizedBox(height: spacing),
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
                  horizontal: AppSpacing.xs4,
                ),
                decoration: ShapeDecoration(
                  color: Color(0xff202020),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(cornerRadius: AppRadii.xs),
                  ),
                ),

                child: Text(
                  localFormat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: artistStyle.fontSize != null
                        ? artistStyle.fontSize! /
                              (AppGeometry.goldenRatio *
                                  AppGeometry.goldenRatio)
                        : 8,
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
