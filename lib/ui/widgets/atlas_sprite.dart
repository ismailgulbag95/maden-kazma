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
    this.sourceCutouts = const [],
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

  /// Normalized regions within this atlas cell that should be transparent.
  /// This is useful for removing small stray details without changing the
  /// shared source artwork used by other sprites.
  final List<Rect> sourceCutouts;

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
              sourceCutouts: sourceCutouts,
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
    required this.verticalOffset,
    required this.minorTint,
  });

  final String asset;
  final double verticalOffset;
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
              verticalOffset: verticalOffset,
              minorTint: minorTint,
            ),
          );
        },
      );
    },
  );
}

/// Draws the mine-edge rock tile at its authored aspect ratio and repeats it
/// vertically so adjacent mine floors join without restarting the texture.
class MineEdgeRockStrip extends StatelessWidget {
  const MineEdgeRockStrip({
    super.key,
    required this.asset,
    required this.verticalOffset,
    this.mirroredX = false,
    this.tint,
  });

  final String asset;
  final double verticalOffset;
  final bool mirroredX;
  final Color? tint;

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
            painter: _MineEdgeRockPainter(
              image: image,
              verticalOffset: verticalOffset,
              mirroredX: mirroredX,
              tint: tint,
            ),
          );
        },
      );
    },
  );
}

class _MineEdgeRockPainter extends CustomPainter {
  const _MineEdgeRockPainter({
    required this.image,
    required this.verticalOffset,
    required this.mirroredX,
    required this.tint,
  });

  final ui.Image image;
  final double verticalOffset;
  final bool mirroredX;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final tileHeight = size.width * image.height / image.width;
    if (tileHeight <= 0) return;
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..colorFilter = tint == null
          ? null
          : ui.ColorFilter.mode(tint!, ui.BlendMode.modulate);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (mirroredX) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
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
  bool shouldRepaint(covariant _MineEdgeRockPainter oldDelegate) =>
      image != oldDelegate.image ||
      verticalOffset != oldDelegate.verticalOffset ||
      mirroredX != oldDelegate.mirroredX ||
      tint != oldDelegate.tint;
}

class _CaveTexturePainter extends CustomPainter {
  const _CaveTexturePainter({
    required this.image,
    required this.verticalOffset,
    required this.minorTint,
  });

  final ui.Image image;
  final double verticalOffset;
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
      ..[13] = verticalOffset;
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
      verticalOffset != oldDelegate.verticalOffset ||
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
    required this.sourceCutouts,
  });

  final ui.Image image;
  final int index;
  final int columns;
  final int rows;
  final BoxFit fit;
  final Alignment alignment;
  final Rect? sourceCrop;
  final List<Rect> sourceCutouts;

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
    if (sourceCutouts.isEmpty) {
      canvas.drawImageRect(
        image,
        sourceRect,
        destinationRect,
        Paint()..filterQuality = FilterQuality.none,
      );
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.none,
    );
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = false;
    for (final cutout in sourceCutouts) {
      final cutoutSource = Rect.fromLTRB(
        cell.left + cell.width * cutout.left,
        cell.top + cell.height * cutout.top,
        cell.left + cell.width * cutout.right,
        cell.top + cell.height * cutout.bottom,
      ).intersect(sourceRect);
      if (cutoutSource.isEmpty) continue;
      final cutoutDestination = Rect.fromLTRB(
        destinationRect.left +
            (cutoutSource.left - sourceRect.left) /
                sourceRect.width *
                destinationRect.width,
        destinationRect.top +
            (cutoutSource.top - sourceRect.top) /
                sourceRect.height *
                destinationRect.height,
        destinationRect.left +
            (cutoutSource.right - sourceRect.left) /
                sourceRect.width *
                destinationRect.width,
        destinationRect.top +
            (cutoutSource.bottom - sourceRect.top) /
                sourceRect.height *
                destinationRect.height,
      );
      canvas.drawRect(cutoutDestination, clearPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AtlasPainter oldDelegate) =>
      image != oldDelegate.image ||
      index != oldDelegate.index ||
      sourceCrop != oldDelegate.sourceCrop ||
      sourceCutouts != oldDelegate.sourceCutouts ||
      columns != oldDelegate.columns ||
      rows != oldDelegate.rows ||
      fit != oldDelegate.fit;
}
