import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/palette.dart';

class OpeningComicOverlay extends StatefulWidget {
  const OpeningComicOverlay({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OpeningComicOverlay> createState() => _OpeningComicOverlayState();
}

class _OpeningComicOverlayState extends State<OpeningComicOverlay> {
  static const _panelMotionDuration = Duration(seconds: 18);
  static const _beats = <_ComicBeat>[
    _ComicBeat(
      'ÜÇ VURUŞ',
      'Saat 03.17. Beş bin metrenin altındaki ölçer üç kez vurdu. Nöbetçi fişi çekti; ses devam etti. Sonra bütün kuyu sustu.',
    ),
    _ComicBeat(
      'KARAKOL',
      'Sabah, karakolun paslı panjuru yıllar sonra açıldı. Masada kuyu anahtarı, yarım kalmış vardiya çizelgesi ve sana ayrılmış boş bir satır vardı. Kimse neden seni seçtiklerini açıklamadı.',
    ),
    _ComicBeat(
      'SON VARDİYA',
      'Asansör defterinin son sayfası on bir yıl önce koparılmış. Karbon kâğıdında tek notun izi kalmış: “Dönüşte yükü almayın.” Kafesin tartısı o günden beri sıfır gösteriyor.',
    ),
    _ComicBeat(
      '5.000 METRE',
      'Kafes 5.000 metrede durunca yukarıdaki telsiz sustu. Aşağıdaki matkap kendi kendine bir tur döndü. Senin vardiyan henüz başlamamıştı; kuyu senden önce davranmıştı.',
    ),
    _ComicBeat(
      'İLK KÖMÜR',
      'İlk kömür damarı yeni kırılmış; tozu hâlâ sıcak. Çıkardığın birkaç parça bu vardiyanın yakıtını ve ilk satışını karşılayacak. Taşın içindeki çizik, matkap izinden daha derine uzanıyor.',
    ),
    _ComicBeat(
      'RİTMİN ALTINDA',
      'Rehber drone kaydı önüne bıraktı: üç kısa darbe, bir uzun. Aynı ritim aşağıdan geliyor. Ekip senden emir bekliyor; defterdeki “yükü almayın” notuysa hâlâ aklında.',
    ),
  ];

  ui.Image? _comicSheet;
  int _frameIndex = 0;
  bool _showStartPage = false;
  bool _finished = false;
  bool _comicSheetFailed = false;

  @override
  void initState() {
    super.initState();
    _loadComicSheet();
  }

  Future<void> _loadComicSheet() async {
    try {
      final data = await rootBundle.load(
        'assets/packs/opening_comic_sheet.png',
      );
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _comicSheet = frame.image);
    } catch (_) {
      if (mounted) setState(() => _comicSheetFailed = true);
    }
  }

  void _advance() {
    if (!mounted || _finished || _showStartPage) return;
    if (_frameIndex >= _beats.length - 1) {
      setState(() => _showStartPage = true);
    } else {
      setState(() => _frameIndex++);
    }
  }

  void _openStartPage() {
    if (!mounted || _finished) return;
    setState(() => _showStartPage = true);
  }

  void _goBack() {
    if (!mounted || _finished) return;
    if (_showStartPage) {
      setState(() => _showStartPage = false);
    } else if (_frameIndex > 0) {
      setState(() => _frameIndex--);
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MinePalette.ink,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF102D38), MinePalette.ink],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxPanelWidth = math
                  .max(0.0, constraints.maxWidth - 36)
                  .toDouble();
              final maxPanelHeight = math
                  .max(0.0, constraints.maxHeight - 300)
                  .toDouble();
              final panelWidth = math
                  .min(maxPanelWidth, maxPanelHeight * 1.5)
                  .toDouble();
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(.035, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: _showStartPage
                                  ? _buildStartPage(panelWidth)
                                  : _buildStoryPage(panelWidth),
                            ),
                          ),
                        ),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPage(double panelWidth) {
    final beat = _beats[_frameIndex];
    return Column(
      key: ValueKey('story-$_frameIndex'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPanel(
          panelWidth,
          frameIndex: _frameIndex,
          semanticLabel: '${beat.title}. ${beat.caption}',
          motionKey: 'story-$_frameIndex',
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: math.min(panelWidth, 620).toDouble(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey('caption-$_frameIndex'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xE90A232D),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: MinePalette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beat.title,
                    style: const TextStyle(
                      color: MinePalette.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    beat.caption,
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartPage(double panelWidth) => Column(
    key: const ValueKey('start-page'),
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildPanel(
        panelWidth,
        frameIndex: _beats.length - 1,
        semanticLabel:
            'Vardiya başlangıcı. Kuyunun verdiği cevabın peşine düş.',
        motionKey: 'start-page',
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: math.min(panelWidth, 620).toDouble(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xE90A232D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MinePalette.amber, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VARDİYA 01  •  5.000 M',
                style: TextStyle(
                  color: MinePalette.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Önce yükü çıkar. Sonra defterdeki notu çöz.',
                style: TextStyle(
                  color: MinePalette.cream,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'İlk kömürü çıkar, kargoyu yüzeye ulaştır ve kazancını matkabı geliştirmek için kullan. Rehber drone darbelerin izini kat kat takip edecek.',
                style: TextStyle(
                  color: MinePalette.muted,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: MinePalette.cyan,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Asansör defterindeki not: “Dönüşte yükü almayın.”',
                      style: TextStyle(
                        color: MinePalette.cream.withValues(alpha: .88),
                        fontSize: 12,
                        height: 1.25,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildPanel(
    double panelWidth, {
    required int frameIndex,
    required String semanticLabel,
    required String motionKey,
  }) => SizedBox(
    width: panelWidth,
    child: TweenAnimationBuilder<double>(
      key: ValueKey(motionKey),
      tween: Tween(begin: 1, end: 1.045),
      duration: _panelMotionDuration,
      curve: Curves.easeInOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MinePalette.panel,
            border: Border.all(color: MinePalette.amber, width: 2),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5537D9D0),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _ComicSpritePanel(
              sheet: _comicSheet,
              loadFailed: _comicSheetFailed,
              frameIndex: frameIndex,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF153A45),
            border: Border.all(color: MinePalette.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.graphic_eq_rounded, color: MinePalette.cyan),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KUYU DEFTERİ',
                style: TextStyle(
                  color: MinePalette.cream,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                _showStartPage
                    ? 'VARDİYA BAŞLANGICI'
                    : 'KUYU GÜNLÜĞÜ • SAHNE ${_frameIndex + 1} / ${_beats.length}',
                style: const TextStyle(
                  color: MinePalette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
        if (!_showStartPage)
          TextButton.icon(
            onPressed: _openStartPage,
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: const Text('ÖYKÜYÜ GEÇ'),
            style: TextButton.styleFrom(
              foregroundColor: MinePalette.cream,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    ),
  );

  Widget _buildFooter() {
    final progress = _showStartPage ? _beats.length + 1 : _frameIndex + 1;
    final canGoBack = _showStartPage || _frameIndex > 0;
    final isLastStoryScene =
        !_showStartPage && _frameIndex == _beats.length - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < _beats.length + 1; index++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 4,
                          decoration: BoxDecoration(
                            color: _showStartPage || index <= _frameIndex
                                ? MinePalette.amber
                                : const Color(0xFF29424A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (index < _beats.length) const SizedBox(width: 5),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${progress.toString().padLeft(2, '0')} / ${_beats.length + 1}',
                style: const TextStyle(
                  color: MinePalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Row(
              children: [
                SizedBox(
                  width: 104,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: canGoBack ? _goBack : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MinePalette.cream,
                      side: const BorderSide(color: MinePalette.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text('GERİ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _showStartPage
                          ? _finish
                          : isLastStoryScene
                          ? _openStartPage
                          : _advance,
                      style: FilledButton.styleFrom(
                        backgroundColor: MinePalette.amber,
                        foregroundColor: MinePalette.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: Icon(
                        _showStartPage
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _showStartPage
                            ? 'MACERAYA BAŞLA'
                            : isLastStoryScene
                            ? 'VARDİYAYI DEVRAL'
                            : 'SONRAKİ SAHNE',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _comicSheet?.dispose();
    super.dispose();
  }
}

class _ComicBeat {
  const _ComicBeat(this.title, this.caption);

  final String title;
  final String caption;
}

class _ComicSpritePanel extends StatelessWidget {
  const _ComicSpritePanel({
    required this.sheet,
    required this.loadFailed,
    required this.frameIndex,
    required this.semanticLabel,
  });

  final ui.Image? sheet;
  final bool loadFailed;
  final int frameIndex;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticLabel,
    child: ColoredBox(
      color: const Color(0xFF14232A),
      child: sheet != null
          ? CustomPaint(
              painter: _ComicFramePainter(sheet!, frameIndex),
              size: Size.infinite,
            )
          : Center(
              child: loadFailed
                  ? const Icon(
                      Icons.broken_image_outlined,
                      color: MinePalette.muted,
                      size: 38,
                    )
                  : const CircularProgressIndicator(
                      color: MinePalette.amber,
                      strokeWidth: 2,
                    ),
            ),
    ),
  );
}

class _ComicFramePainter extends CustomPainter {
  const _ComicFramePainter(this.sheet, this.frameIndex);

  final ui.Image sheet;
  final int frameIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = sheet.width / 2;
    final cellHeight = sheet.height / 3;
    final column = frameIndex % 2;
    final row = frameIndex ~/ 2;
    const inset = .022;
    final source = Rect.fromLTWH(
      column * cellWidth + cellWidth * inset,
      row * cellHeight + cellHeight * inset,
      cellWidth * (1 - inset * 2),
      cellHeight * (1 - inset * 2),
    );
    canvas.drawImageRect(
      sheet,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _ComicFramePainter oldDelegate) =>
      oldDelegate.sheet != sheet || oldDelegate.frameIndex != frameIndex;
}
