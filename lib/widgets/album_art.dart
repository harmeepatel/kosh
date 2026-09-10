import 'dart:math' show pow;
import 'dart:typed_data';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_symbols/flutter_cupertino_symbols.dart';
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
    final borderRadius = SmoothBorderRadius(cornerRadius: radius, cornerSmoothing: AppRadii.cornerSmoothing);

    final hasArtwork = imageBytes != null || imageProvider != null;

    return SizedBox(
      width: size,
      height: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logicalSize = size ?? constraints.maxWidth;
            final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

            final decodeSize = (logicalSize * devicePixelRatio).round();

            final Widget content;

            if (imageBytes != null) {
              content = Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
                cacheWidth: decodeSize,
                cacheHeight: decodeSize,
                gaplessPlayback: true,
              );
            } else if (imageProvider != null) {
              content = Image(image: imageProvider!, fit: BoxFit.cover, gaplessPlayback: true);
            } else if (customFallback != null) {
              content = customFallback!;
            } else {
              content = Center(child: Icon(SFSymbols.music_note, color: fallbackIconColor));
            }

            return Container(
              decoration: ShapeDecoration(
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: radius * pow(AppGeometry.ratio, 2),
                    spreadRadius: radius / pow(AppGeometry.ratio, 2),
                  ),
                ],
                shape: SmoothRectangleBorder(borderRadius: borderRadius),
              ),
              child: ClipSmoothRect(
                radius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  color: hasArtwork ? Colors.black : AppColors.albumPlaceholder,
                  foregroundDecoration: showBorder
                      ? ShapeDecoration(
                          shape: SmoothRectangleBorder(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: (AppGeometry.borderWidth * 2) / pow(AppGeometry.ratio, 2),
                            ),
                            borderRadius: borderRadius,
                          ),
                        )
                      : null,
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
