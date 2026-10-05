import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AtlasSprite extends StatelessWidget {
  const AtlasSprite({
    super.key,
    required this.asset,
    required this.index,
    required this.columns,
    required this.rows,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.sourceCrop,
  });

  final String asset;
  final int index;
  final int columns;
  final int rows;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  /// Normalized crop within this atlas cell, useful for trimming sprite-cell
  /// whitespace while keeping the authored artwork at its original ratio.
  final Rect? sourceCrop;

  static final Map<String, Future<ui.Image>> _images = {};

  static Future<ui.Image> _load(String path) =>
      _images.putIfAbsent(path, () async {
        final data = await rootBundle.load(path);
        final Uint8List bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: FutureBuilder<ui.Image>(
      future: _load('assets/packs/$asset'),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return snapshot.hasError
              ? const Icon(Icons.broken_image_outlined, color: Colors.white38)
              : const SizedBox.shrink();
        }
        return SizedBox.expand(
          child: CustomPaint(
            painter: _AtlasPainter(
              image: image,
              index: index,
              columns: columns,
              rows: rows,
              fit: fit,
              alignment: alignment,
              sourceCrop: sourceCrop,
            ),
            size: Size(width ?? 96, height ?? 80),
          ),
        );
      },
    ),
  );
}

/// Repeats the authored elevator-rail artwork vertically to make an endless
/// fixed shaft instead of stretching a short ladder down the whole mine.
class VerticalShaftBackground extends StatelessWidget {
  const VerticalShaftBackground({super.key, this.verticalOffset = 0});

  final double verticalOffset;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return FutureBuilder<ui.Image>(
        future: AtlasSprite._load('assets/packs/elevator-shaft-repeat.png'),
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) return const SizedBox.expand();
          return CustomPaint(
            size: size,
            painter: _VerticalShaftPainter(
              image: image,
              verticalOffset: verticalOffset,
            ),
          );
        },
      );
    },
  );
}

class CaveTextureBackground extends StatelessWidget {
  const CaveTextureBackground({
    super.key,
    required this.asset,
    required this.floorVariant,
    required this.minorTint,
  });

  final String asset;
  final int floorVariant;
  final Color? minorTint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return FutureBuilder<ui.Image>(
        future: AtlasSprite._load('assets/packs/$asset'),
        builder: (context, snapshot) {
          final image = snapshot.data;
          if (image == null) return const SizedBox.expand();
          return CustomPaint(
            size: size,
            painter: _CaveTexturePainter(
              image: image,
              floorVariant: floorVariant,
              minorTint: minorTint,
            ),
          );
        },
      );
    },
  );
}

class _CaveTexturePainter extends CustomPainter {
  const _CaveTexturePainter({
    required this.image,
    required this.floorVariant,
    required this.minorTint,
  });

  final ui.Image image;
  final int floorVariant;
  final Color? minorTint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final identity = Float64List(16)
      ..[0] = 1
      ..[5] = 1
      ..[10] = 1
      ..[15] = 1
      ..[12] = image.width * ((floorVariant % 4) * .21)
      ..[13] = image.height * ((floorVariant % 5) * .13);
    final texture = ui.ImageShader(
      image,
      ui.TileMode.mirror,
      ui.TileMode.mirror,
      identity,
      filterQuality: ui.FilterQuality.none,
    );

    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, Paint()..shader = texture);
    if (minorTint case final tint?) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = tint.withValues(alpha: 0.07)
          ..blendMode = ui.BlendMode.srcOver,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CaveTexturePainter oldDelegate) =>
      image != oldDelegate.image ||
      floorVariant != oldDelegate.floorVariant ||
      minorTint != oldDelegate.minorTint;
}

class _VerticalShaftPainter extends CustomPainter {
  const _VerticalShaftPainter({
    required this.image,
    required this.verticalOffset,
  });

  final ui.Image image;
  final double verticalOffset;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final source = Rect.fromLTWH(
      image.width * .30,
      0,
      image.width * .40,
      image.height.toDouble(),
    );
    final tileHeight = size.width * source.height / source.width;
    if (tileHeight <= 0) return;
    final paint = Paint()..filterQuality = FilterQuality.none;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    final firstTile = (verticalOffset / tileHeight).floor();
    var tile = firstTile;
    var top = tile * tileHeight - verticalOffset;
    while (top < size.height) {
      final destination = Rect.fromLTWH(0, top, size.width, tileHeight);
      canvas.save();
      if (tile.isOdd) {
        canvas
          ..translate(0, top * 2 + tileHeight)
          ..scale(1, -1);
      }
      canvas.drawImageRect(image, source, destination, paint);
      canvas.restore();
      tile++;
      top += tileHeight;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VerticalShaftPainter oldDelegate) =>
      image != oldDelegate.image ||
      verticalOffset != oldDelegate.verticalOffset;
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter({
    required this.image,
    required this.index,
    required this.columns,
    required this.rows,
    required this.fit,
    required this.alignment,
    required this.sourceCrop,
  });

  final ui.Image image;
  final int index;
  final int columns;
  final int rows;
  final BoxFit fit;
  final Alignment alignment;
  final Rect? sourceCrop;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || rows <= 0 || index < 0 || index >= columns * rows) {
      return;
    }
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;
    final cell = Rect.fromLTWH(
      (index % columns) * cellWidth,
      (index ~/ columns) * cellHeight,
      cellWidth,
      cellHeight,
    );
    final crop = sourceCrop;
    final source = crop == null
        ? cell
        : Rect.fromLTRB(
            cell.left + cell.width * crop.left,
            cell.top + cell.height * crop.top,
            cell.left + cell.width * crop.right,
            cell.top + cell.height * crop.bottom,
          );
    final fitted = applyBoxFit(fit, source.size, size);
    final sourceRect = alignment.inscribe(fitted.source, source);
    final destinationRect = alignment.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasPainter oldDelegate) =>
      image != oldDelegate.image ||
      index != oldDelegate.index ||
      sourceCrop != oldDelegate.sourceCrop ||
      columns != oldDelegate.columns ||
      rows != oldDelegate.rows ||
      fit != oldDelegate.fit;
}
