import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/ui/game_screen.dart';

void main() {
  testWidgets(
    'iki istasyon zemine hafifçe oturur ve tüm ekranlarda kata sığar',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      const viewports = [
        Size(320, 844),
        Size(390, 844),
        Size(600, 900),
        Size(768, 1024),
        Size(1024, 1200),
      ];
      for (final viewport in viewports) {
        tester.view.physicalSize = viewport;

        for (final repaired in [false, true]) {
          final state = GameState.newGame(seed: 873)
            ..openingComicSeen = true
            ..musicEnabled = false
            ..soundEffectsEnabled = false
            ..depthMeters = 8000
            ..deepestMeters = 8000
            ..crusherRepaired = repaired;
          final controller = GameController()
            ..state = state
            ..isReady = true;
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('tr'),
              supportedLocales: testSupportedLocales,
              localizationsDelegates: testLocalizationDelegates,
              home: GameScreen(controller: controller),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          final floor = find.byKey(const ValueKey('mine-floor-0-6'));
          final background = find.byKey(
            const ValueKey('mine-crusher-station-background'),
          );
          final floorRect = tester.getRect(floor);
          final backgroundRect = tester.getRect(background);
          final platformY =
              backgroundRect.top +
              _platformTopInRow(
                width: backgroundRect.width,
                height: backgroundRect.height,
              );
          final platformTopInRow = platformY - floorRect.top;
          final narrow = floorRect.width < 690;
          final shaftWidth = narrow ? 86.0 : 112.0;
          final edgeInset = narrow ? 32.0 : 48.0;
          const shaftGap = 16.0;
          final sideSpace =
              (floorRect.width - shaftWidth) / 2 -
              math.min(edgeInset, 12) -
              shaftGap;
          final footFraction = _visibleFootFraction(repaired: repaired);
          final expectedStationSize = math.max(
            0,
            math.min(
              220.0,
              math.min(
                sideSpace,
                math.min(
                  (platformTopInRow - 4) / footFraction,
                  (floorRect.height - platformTopInRow - 4) /
                      (1 - footFraction),
                ),
              ),
            ),
          );
          final stationArtworkRects = <Rect>[];
          for (final side in ['Sol', 'Sağ']) {
            final station = find.byKey(ValueKey('crusher-station-7km-$side'));
            final artwork = find.byKey(ValueKey('crusher-station-art-$side'));
            expect(station, findsOneWidget);
            expect(artwork, findsOneWidget);

            final artworkRect = tester.getRect(artwork);
            final stationRect = tester.getRect(station);
            stationArtworkRects.add(artworkRect);
            final visibleFootY =
                artworkRect.top + artworkRect.width * footFraction;
            final visibleTopY =
                artworkRect.top +
                artworkRect.width * _visibleTopFraction(repaired: repaired);

            expect(artworkRect.left, greaterThanOrEqualTo(floorRect.left));
            expect(artworkRect.right, lessThanOrEqualTo(floorRect.right));
            expect(stationRect.top, greaterThanOrEqualTo(floorRect.top));
            expect(stationRect.bottom, lessThanOrEqualTo(floorRect.bottom));
            expect(artworkRect.width, closeTo(expectedStationSize, .1));
            expect(visibleTopY, greaterThanOrEqualTo(floorRect.top - 1));
            expect(visibleFootY, lessThanOrEqualTo(floorRect.bottom + 1));
            expect(visibleFootY, closeTo(platformY + 4, 1));
          }

          expect(
            stationArtworkRects[0].width,
            closeTo(stationArtworkRects[1].width, .01),
          );
          expect(
            stationArtworkRects[0].top,
            closeTo(stationArtworkRects[1].top, .01),
          );
          final shaftLeft = (floorRect.width - shaftWidth) / 2;
          final sideCenteringOffset = math.max(
            0,
            (sideSpace - stationArtworkRects.first.width) / 2,
          );
          expect(
            stationArtworkRects[0].right,
            closeTo(shaftLeft - shaftGap - sideCenteringOffset, .1),
          );
          expect(
            stationArtworkRects[1].left,
            closeTo(
              shaftLeft + shaftWidth + shaftGap + sideCenteringOffset,
              .1,
            ),
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );
}

const _floorArtworkWidth = 2172.0;
const _floorArtworkHeight = 724.0;
const _floorPlatformTop = 588.0;

double _platformTopInRow({required double width, required double height}) {
  final scale = math.max(
    width / _floorArtworkWidth,
    height / _floorArtworkHeight,
  );
  final topCrop = _floorArtworkHeight * scale - height;
  return _floorPlatformTop * scale - topCrop;
}

double _visibleFootFraction({required bool repaired}) {
  final spriteWidth = repaired ? 1378.0 : 1377.0;
  const spriteHeight = 1142.0;
  final visibleBottom = repaired ? 1080.0 : 1122.0;
  return ((spriteWidth - spriteHeight) / 2 + visibleBottom) / spriteWidth;
}

double _visibleTopFraction({required bool repaired}) {
  final spriteWidth = repaired ? 1378.0 : 1377.0;
  const spriteHeight = 1142.0;
  const visibleTop = 83.0;
  return ((spriteWidth - spriteHeight) / 2 + visibleTop) / spriteWidth;
}
