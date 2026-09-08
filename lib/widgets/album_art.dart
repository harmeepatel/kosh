import 'dart:math' show pow;
import 'dart:typed_data';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:kosh/style/style.dart';

class AlbumArt extends StatelessWidget {
  const AlbumArt({
    super.key,
    this.size,
    required this.radius,
    this.imageProvider,
    this.imageBytes,
    this.fallbackIconColor = Colors.white70,
    this.customFallback,
    this.showBorder = true,
  });

  final double? size;
  final double radius;
  final ImageProvider? imageProvider;
  final Uint8List? imageBytes;
  final Color fallbackIconColor;
  final Widget? customFallback;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (imageBytes != null) {
      content = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (imageProvider != null) {
      content = Image(image: imageProvider!, fit: BoxFit.cover);
    } else if (customFallback != null) {
      content = customFallback!;
    } else {
      content = Center(child: Icon(Icons.music_note, color: fallbackIconColor));
    }

    final borderRadius = SmoothBorderRadius(cornerRadius: radius, cornerSmoothing: AppRadii.cornerSmoothing);

    return SizedBox(
      width: size,
      height: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipSmoothRect(
          radius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: ShapeDecoration(
              color: AppColors.albumPlaceholder,
              shape: SmoothRectangleBorder(borderRadius: borderRadius),
            ),
            foregroundDecoration: showBorder
                ? ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      side: BorderSide(
                        color: Colors.white24,
                        width: AppGeometry.borderWidth / pow(AppGeometry.ratio, 2),
                      ),
                      borderRadius: borderRadius,
                    ),
                  )
                : null,
            child: content,
          ),
        ),
      ),
    );
  }
}
