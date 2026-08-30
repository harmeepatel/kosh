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
    this.fallbackColor,
    this.fallbackIconColor = Colors.white70,
    this.customFallback,
  });

  final double? size;
  final double radius;
  final ImageProvider? imageProvider;
  final Uint8List? imageBytes;
  final Color? fallbackColor;
  final Color fallbackIconColor;
  final Widget? customFallback;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imageBytes != null) {
      content = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (imageProvider != null) {
      content = Image(image: imageProvider!, fit: BoxFit.cover);
    } else if (customFallback != null) {
      content = customFallback!;
    } else {
      content = Center(child: Icon(Icons.music_note, color: fallbackIconColor));
    }

    return SizedBox(
      width: size,
      height: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: fallbackColor ?? AppColors.albumPlaceholder,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: radius,
                cornerSmoothing: AppRadii.cornerSmoothing,
              ),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                spreadRadius: 4,
                blurRadius: 32,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}
