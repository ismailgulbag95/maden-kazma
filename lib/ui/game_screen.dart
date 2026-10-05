import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../app/game_controller.dart';
import '../core/design/palette.dart';
import '../domain/models/mine_event_definition.dart';
import '../domain/models/game_state.dart';
import '../domain/models/resource_definition.dart';
import '../domain/models/ore_deposit.dart';
import '../domain/simulation/game_engine.dart';
import '../services/sound_service.dart';
import 'widgets/atlas_sprite.dart';
import 'widgets/building_dialog.dart';
import 'widgets/character_animation.dart';
import 'widgets/game_primitives.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _offlineDialogShown = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(SoundService.instance.startBgm());
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final notices = widget.controller.takeNotices();
    if (notices.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(notices.last),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    });
  }

  void _openBuilding(String id) {
    widget.controller.markBuildingOpened();
    showDialog<void>(
      context: context,
      builder: (context) =>
          BuildingDialog(controller: widget.controller, buildingId: id),
    );
  }

  void _openUtilities(String panel) {
    if (panel == 'workshop' ||
        panel == 'warehouse' ||
        panel == 'elevator' ||
        panel == 'trade' ||
        panel == 'research' ||
        panel == 'expedition') {
      widget.controller.markBuildingOpened();
    }
    showDialog<void>(
      context: context,
      builder: (context) =>
          BuildingDialog(controller: widget.controller, buildingId: panel),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_offlineDialogShown && widget.controller.offlineSeconds >= 30) {
      _offlineDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: MinePalette.panel,
            title: const Text('Vardiya raporu'),
            content: Text(
              'Dönüşünde ekibin ${_number(widget.controller.offlineOreGained)} kaynak çıkardı '
              've ${widget.controller.offlineDepthGained.toStringAsFixed(0)} m daha ilerledi. '
              'Süre: ${_duration(widget.controller.offlineSeconds)}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DEVAM ET'),
              ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1120;
              return DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D2D3B), MinePalette.ink],
                  ),
                ),
                child: Column(
                  children: [
                    _HudBar(
                      state: widget.controller.state,
                      onSave: widget.controller.saveNow,
                    ),
                    Expanded(
                      child: compact
                          ? _CompactGameLayout(
                              controller: widget.controller,
                              onBuilding: _openBuilding,
                              onUtility: _openUtilities,
                            )
                          : _WideGameLayout(
                              controller: widget.controller,
                              onBuilding: _openBuilding,
                              onUtility: _openUtilities,
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }
}

class _HudBar extends StatelessWidget {
  const _HudBar({required this.state, required this.onSave});

  final GameState state;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final portraitPhone = constraints.maxWidth < 560;
      final compact = constraints.maxWidth < 1120;
      final chips = [
        _HudChip(
          icon: Icons.currency_exchange_rounded,
          label: 'KASA',
          value: _number(state.coins.round()),
          color: MinePalette.amber,
          compact: compact,
        ),
        _HudChip(
          icon: Icons.diamond_rounded,
          label: 'KARGO',
          value:
              '${state.cargoUsed.toStringAsFixed(0)} / ${state.effectiveCargoCapacity.toStringAsFixed(0)}',
          color: MinePalette.teal,
          compact: compact,
        ),
        _HudChip(
          icon: Icons.air_rounded,
          label: 'BASINÇ',
          value: '${state.pressure.toStringAsFixed(0)}%',
          color: state.pressure > 70 ? MinePalette.danger : MinePalette.cream,
          compact: compact,
        ),
        _HudChip(
          icon: Icons.vertical_align_bottom_rounded,
          label: 'DERİNLİK',
          value: _depthLabel(state.deepestMeters.floor()),
          color: MinePalette.cyan,
          compact: compact,
        ),
      ];

      final background = BoxDecoration(
        color: const Color(0xFF091E28),
        border: Border(
          bottom: BorderSide(color: MinePalette.border, width: 1.2),
        ),
      );
      if (portraitPhone) {
        return Container(
          height: 92,
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
          decoration: background,
          child: Column(
            children: [
              SizedBox(
                height: 34,
                child: Row(
                  children: [
                    Expanded(child: _GameTitle(compact: true)),
                    IconButton(
                      tooltip: 'Ses ayarları',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showAudioSettings(context),
                      icon: const Icon(
                        Icons.volume_up_outlined,
                        color: MinePalette.muted,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kaydı kaydet',
                      visualDensity: VisualDensity.compact,
                      onPressed: onSave,
                      icon: const Icon(
                        Icons.save_outlined,
                        color: MinePalette.muted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: chips),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        height: compact ? 58 : 70,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 7,
        ),
        decoration: background,
        child: Row(
          children: [
            SizedBox(
              width: compact ? 140 : 196,
              child: _GameTitle(compact: compact),
            ),
            SizedBox(width: compact ? 7 : 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: chips),
              ),
            ),
            IconButton(
              tooltip: 'Ses ayarları',
              visualDensity: compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              onPressed: () => _showAudioSettings(context),
              icon: Icon(
                Icons.volume_up_outlined,
                color: MinePalette.muted,
                size: compact ? 20 : 24,
              ),
            ),
            IconButton(
              tooltip: 'Kaydı kaydet',
              visualDensity: compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              onPressed: onSave,
              icon: Icon(
                Icons.save_outlined,
                color: MinePalette.muted,
                size: compact ? 20 : 24,
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showAudioSettings(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: MinePalette.panel,
        title: const Text('Ses ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Efekt sesleri'),
              value: SoundService.instance.sfxEnabled,
              activeThumbColor: MinePalette.cyan,
              onChanged: (_) {
                SoundService.instance.toggleSfx();
                setDialogState(() {});
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Arka plan müziği'),
              value: SoundService.instance.bgmEnabled,
              activeThumbColor: MinePalette.cyan,
              onChanged: (_) {
                SoundService.instance.toggleBgm();
                setDialogState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('KAPAT'),
          ),
        ],
      ),
    ),
  );
}

class _GameTitle extends StatelessWidget {
  const _GameTitle({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 30 : 48,
    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF754624), Color(0xFF36271F)],
      ),
      border: Border.all(color: const Color(0xFFD08A46), width: 2),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
      ],
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        'TAŞIN ALTI',
        style: TextStyle(
          color: const Color(0xFFFFCF83),
          fontSize: compact ? 16 : 25,
          fontWeight: FontWeight.w900,
          letterSpacing: compact ? 1 : 1.6,
          shadows: const [
            Shadow(color: Colors.black, offset: Offset(2, 3), blurRadius: 1),
          ],
        ),
      ),
    ),
  );
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 88 : 144,
    height: compact ? 37 : 51,
    margin: EdgeInsets.only(right: compact ? 4 : 7),
    padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8),
    decoration: BoxDecoration(
      color: const Color(0xFF102D3A),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: MinePalette.border),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: compact ? 15 : 22),
        SizedBox(width: compact ? 4 : 7),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 7 : 9,
                  color: MinePalette.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 10 : 15,
                    color: MinePalette.cream,
                    fontWeight: FontWeight.w900,
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

class _WideGameLayout extends StatelessWidget {
  const _WideGameLayout({
    required this.controller,
    required this.onBuilding,
    required this.onUtility,
  });

  final GameController controller;
  final ValueChanged<String> onBuilding;
  final ValueChanged<String> onUtility;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 91, child: _DepthRail(state: controller.state)),
      Expanded(
        child: Column(
          children: [
            SizedBox(
              height: 188,
              child: _SurfaceOutpost(
                state: controller.state,
                onBuilding: onBuilding,
              ),
            ),
            if (controller.state.tutorialStep < 5)
              _TutorialBanner(state: controller.state),
            Expanded(child: _MineShaftView(controller: controller)),
            SizedBox(
              height: 74,
              child: _MineActionBar(
                controller: controller,
                onUtility: onUtility,
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        width: 285,
        child: _RightDock(controller: controller, onUtility: onUtility),
      ),
    ],
  );
}

class _CompactGameLayout extends StatelessWidget {
  const _CompactGameLayout({
    required this.controller,
    required this.onBuilding,
    required this.onUtility,
  });

  final GameController controller;
  final ValueChanged<String> onBuilding;
  final ValueChanged<String> onUtility;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final outpost = _SurfaceOutpost(
        state: controller.state,
        onBuilding: onBuilding,
      );
      final mine = _MineShaftView(controller: controller);
      final mineEventBanner = _MineEventBanner(
        state: controller.state,
        onUtility: onUtility,
      );

      final outpostHeight = constraints.maxHeight < 700 ? 116.0 : 134.0;
      return Column(
        children: [
          SizedBox(height: outpostHeight, child: outpost),
          Expanded(child: mine),
          if (controller.state.tutorialStep < 5)
            _TutorialBanner(state: controller.state),
          mineEventBanner,
          SizedBox(
            height: 74,
            child: _CompactActionBar(
              controller: controller,
              onUtility: onUtility,
            ),
          ),
        ],
      );
    },
  );
}

class _TutorialBanner extends StatelessWidget {
  const _TutorialBanner({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(9, 0, 9, 5),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          constraints: const BoxConstraints(minHeight: 39),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xEC0A242E),
            border: Border.all(color: MinePalette.amber),
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: MinePalette.amber,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _tutorialText(state.tutorialStep),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CompactActionBar extends StatelessWidget {
  const _CompactActionBar({required this.controller, required this.onUtility});

  final GameController controller;
  final ValueChanged<String> onUtility;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 360;
      final shortcuts = narrow
          ? [
              (Icons.construction_rounded, 'ATÖLYE', 'workshop'),
              (Icons.inventory_2_rounded, 'AMBAR', 'warehouse'),
              (Icons.task_alt_rounded, 'GÖREV', 'quests'),
              (Icons.emoji_events_rounded, 'ROZET', 'achievements'),
            ]
          : [
              (Icons.construction_rounded, 'ATÖLYE', 'workshop'),
              (Icons.inventory_2_rounded, 'AMBAR', 'warehouse'),
              (Icons.task_alt_rounded, 'GÖREV', 'quests'),
              controller.state.totalChestsFound > 0
                  ? (
                      Icons.inventory_2_rounded,
                      'SANDIK ${controller.state.totalChestsFound}',
                      'trade',
                    )
                  : (Icons.explore_rounded, 'SEFER', 'expedition'),
              (Icons.emoji_events_rounded, 'ROZET', 'achievements'),
            ];
      final digWidth = math.max(
        82.0,
        math.min(142.0, constraints.maxWidth * .27),
      );
      return Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xF0071B24), Color(0xF80B2732)],
          ),
          border: const Border(
            top: BorderSide(color: MinePalette.border, width: 1.3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < shortcuts.length; index++) ...[
              _QuickNav(
                icon: shortcuts[index].$1,
                label: shortcuts[index].$2,
                onTap: () => onUtility(shortcuts[index].$3),
              ),
              const SizedBox(width: 2),
            ],
            SizedBox(
              width: digWidth,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: controller.state.cargoFull ? null : controller.dig,
                icon: const Icon(Icons.bolt_rounded, size: 20),
                label: const Text(
                  'KAZI',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBE3E),
                  foregroundColor: const Color(0xFF201509),
                  side: const BorderSide(color: Color(0xFFFFE08B), width: 2),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _MineEventBanner extends StatelessWidget {
  const _MineEventBanner({required this.state, required this.onUtility});

  final GameState state;
  final ValueChanged<String> onUtility;

  @override
  Widget build(BuildContext context) {
    final event = MineEventCatalog.byId[state.activeMineEventId];
    final bossAvailable = GameEngine.availableBossIndex(state) != null;
    if (event == null && !bossAvailable) {
      return const SizedBox.shrink(key: ValueKey('no-mine-notice'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Column(
        key: ValueKey(
          '${event?.id ?? 'no-event'}-${bossAvailable ? 'boss' : 'safe'}',
        ),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (event != null)
            _MineNoticeButton(
              icon: Icons.auto_awesome_rounded,
              title: '${event.title} kuyuda!',
              action: 'İNCELE',
              onTap: () => onUtility('mine_event'),
            ),
          if (bossAvailable)
            _MineNoticeButton(
              icon: Icons.shield_moon_rounded,
              title: 'Muhafız uyandı • Maden tehlikeli',
              action: 'SAVAŞ',
              danger: true,
              onTap: () => onUtility('boss'),
            ),
        ],
      ),
    );
  }
}

class _MineNoticeButton extends StatelessWidget {
  const _MineNoticeButton({
    required this.icon,
    required this.title,
    required this.action,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String action;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(9, 0, 9, 5),
    child: SizedBox(
      height: 39,
      child: Material(
        color: danger ? const Color(0xFF3D2023) : const Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: danger ? MinePalette.danger : MinePalette.amber,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$action  ›',
                  style: TextStyle(
                    color: danger ? MinePalette.danger : MinePalette.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuickNav extends StatelessWidget {
  const _QuickNav({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: MinePalette.cyan),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _buildings = <(String, String, int, IconData)>[
  ('workshop', 'ATÖLYE', 1, Icons.construction_rounded),
  ('warehouse', 'AMBAR', 2, Icons.inventory_2_rounded),
  ('trade', 'TİCARET', 3, Icons.storefront_rounded),
  ('elevator', 'ASANSÖR', 0, Icons.elevator_rounded),
  ('research', 'ARAŞTIRMA', 4, Icons.biotech_rounded),
  ('expedition', 'SEFER', 5, Icons.explore_rounded),
];

const _surfaceBuildingAnchors = <double>[.08, .22, .35, .5, .65, .87];
const _surfacePortraitBuildingAnchors = <double>[.07, .215, .36, .5, .67, .92];
// Crop each atlas cell to its visible sprite so its foot meets the shared soil.
const _surfaceBuildingSourceCrops = <Rect>[
  Rect.fromLTRB(0, .0625, 1, .923828),
  Rect.fromLTRB(0, .105469, 1, .917969),
  Rect.fromLTRB(0, .199219, 1, .904297),
  Rect.fromLTRB(0, .066406, 1, .904297),
  Rect.fromLTRB(0, 0, 1, .865234),
  Rect.fromLTRB(0, .029297, .978516, .853516),
];
const _galleryHeightRatios = <double>[.25, .46, .67, .86];
const double _mineVisualFloorMeters = 1000;

String _mineWallAsset({required int worldIndex, required int majorBand}) {
  final assets = switch (worldIndex) {
    1 => const ['mine-moon-basalt-wall.png', 'mine-moon-crystal-wall.png'],
    2 => const ['mine-titan-ice-wall.png', 'mine-titan-amber-wall.png'],
    _ => const [
      'cave-wall-tile.png',
      'mine-earth-iron-wall.png',
      'mine-earth-crystal-wall.png',
    ],
  };
  return assets[majorBand % assets.length];
}

Color? _mineMinorTint({required int worldIndex, required int variant}) {
  if (variant == 0) return null;
  return switch (worldIndex) {
    1 => const Color(0xFF78B8D4),
    2 => const Color(0xFF6FA7A0),
    _ => const Color(0xFFCE8A4D),
  };
}

class _SurfaceOutpost extends StatelessWidget {
  const _SurfaceOutpost({required this.state, required this.onBuilding});

  final GameState state;
  final ValueChanged<String> onBuilding;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final wide = width >= 900;
        final anchors = wide
            ? _surfaceBuildingAnchors
            : _surfacePortraitBuildingAnchors;
        final buttonHeight = math.max(0.0, height - 18);
        final buttonWidth = wide
            ? math.min(150.0, width * .122)
            : width < 560
            ? math.min(58.0, width * .14)
            : math.min(104.0, width * .13);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                switch (state.currentWorldIndex) {
                  1 => 'assets/packs/moon-outpost-panorama.png',
                  2 => 'assets/packs/titan-outpost-panorama.png',
                  _ => 'assets/packs/surface-outpost-panorama.png',
                },
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.24),
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF514132), Color(0xFF2B2725)],
                  ),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFBD7540), width: 3),
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 18,
              child: Stack(
                key: const ValueKey('surface-building-layer'),
                clipBehavior: Clip.hardEdge,
                children: [
                  for (var index = 0; index < _buildings.length; index++)
                    Positioned(
                      left: width * anchors[index] - buttonWidth / 2,
                      top: 0,
                      bottom: 0,
                      width: buttonWidth,
                      child: _surfaceBuildingButton(
                        index,
                        buttonWidth,
                        buttonHeight,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 9,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xDD102B35),
                  border: Border.all(color: MinePalette.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.currentWorldName} • Yüzey Karakolu',
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _surfaceBuildingButton(int index, double width, double height) {
    final item = _buildings[index];
    return _BuildingButton(
      id: item.$1,
      label: item.$2,
      spriteIndex: item.$3,
      state: state,
      width: width,
      height: height,
      onTap: () => onBuilding(item.$1),
    );
  }
}

class _BuildingButton extends StatelessWidget {
  const _BuildingButton({
    required this.id,
    required this.label,
    required this.spriteIndex,
    required this.state,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final String id;
  final String label;
  final int spriteIndex;
  final GameState state;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pending =
        id == 'expedition' && state.caveCompletedPending ||
        id == 'research' && state.excavationCompletedPending ||
        id == 'trade' && state.totalChestsFound > 0;
    final crewRole = switch (id) {
      'workshop' => (2, CrewAction.repairing),
      'warehouse' => (3, CrewAction.scanning),
      'elevator' => (4, CrewAction.operatingLift),
      'trade' => (1, CrewAction.hauling),
      'research' => (1, CrewAction.surveying),
      'expedition' => (5, CrewAction.exploring),
      _ => (0, CrewAction.mining),
    };
    return Semantics(
      button: true,
      label: '$label binasını aç',
      key: ValueKey('surface-building-$id'),
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  top: 42,
                  child: AtlasSprite(
                    key: ValueKey('surface-building-sprite-$id'),
                    asset: 'surface-buildings-sheet.png',
                    index: spriteIndex,
                    columns: 3,
                    rows: 2,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    sourceCrop: _surfaceBuildingSourceCrops[spriteIndex],
                  ),
                ),
                Positioned(
                  right: width < 64 ? 0 : 5,
                  bottom: 0,
                  child: IgnorePointer(
                    child: AnimatedCrewSprite(
                      index: crewRole.$1,
                      action: crewRole.$2,
                      width: width < 64
                          ? 13
                          : width < 100
                          ? 18
                          : 27,
                      height: width < 64
                          ? 19
                          : width < 100
                          ? 24
                          : 32,
                      phaseOffset: spriteIndex * .137,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: height * .2,
                  height: 15,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xE8202525),
                          border: Border.all(color: const Color(0xFFD18D4A)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            key: ValueKey('surface-building-label-$id'),
                            maxLines: 1,
                            style: TextStyle(
                              color: const Color(0xFFFFD08D),
                              fontSize: width < 64 ? 8 : 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (pending)
                  Positioned(
                    right: 4,
                    top: height * .2 + 16,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF092129),
                        shape: BoxShape.circle,
                        border: Border.all(color: MinePalette.teal),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: MinePalette.teal,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepthRail extends StatelessWidget {
  const _DepthRail({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    const milestones = [
      0,
      100,
      250,
      500,
      1000,
      5000,
      10000,
      50000,
      100000,
      500000,
      1032000,
      1782000,
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE909202A),
        border: Border(right: BorderSide(color: MinePalette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(7, 12, 5, 10),
      child: Column(
        children: [
          const Text(
            'DERİNLİK',
            style: TextStyle(
              color: MinePalette.cream,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned(
                    left: 7,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: MinePalette.panelRaised,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 7,
                    top: 0,
                    height:
                        constraints.maxHeight *
                        (state.deepestMeters / 2200000).clamp(0, 1),
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: MinePalette.teal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: milestones.map((meter) {
                      final reached = state.deepestMeters >= meter;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: reached
                                  ? MinePalette.amber
                                  : MinePalette.panel,
                              border: Border.all(
                                color: reached
                                    ? MinePalette.amber
                                    : MinePalette.muted,
                                width: 1.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _depthLabel(meter),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                color: reached
                                    ? MinePalette.cream
                                    : MinePalette.muted,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            Icons.public_rounded,
            color: state.currentWorldIndex > 0
                ? MinePalette.cyan
                : MinePalette.teal,
            size: 19,
          ),
          Text(
            state.currentWorldName,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RightDock extends StatelessWidget {
  const _RightDock({required this.controller, required this.onUtility});

  final GameController controller;
  final ValueChanged<String> onUtility;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xE909202A),
      border: Border(left: BorderSide(color: MinePalette.border)),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UpgradeDock(controller: controller),
          const SizedBox(height: 10),
          _QuestDock(controller: controller),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => onUtility('achievements'),
            icon: const Icon(Icons.emoji_events_rounded),
            label: Text(
              'BAŞARIMLAR • ${controller.state.unlockedAchievements.length}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onUtility('research'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('REZONANS TARAMASI'),
          ),
          if (controller.state.totalChestsFound > 0) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => controller.openChest(
                tier: controller.state.deepChests > 0
                    ? 'deep'
                    : controller.state.goldChests > 0
                    ? 'gold'
                    : 'basic',
              ),
              icon: const Icon(Icons.inventory_2_rounded),
              label: Text('${controller.state.totalChestsFound} SANDIĞI AÇ'),
            ),
          ],
          if (GameEngine.availableBossIndex(controller.state) != null) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => onUtility('boss'),
              icon: const Icon(Icons.shield_moon_rounded),
              label: const Text('MUHAFIZLA SAVAŞ'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _UpgradeDock extends StatelessWidget {
  const _UpgradeDock({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => GamePanel(
    title: 'YÜKSELTMELER',
    icon: Icons.handyman_rounded,
    child: Column(
      children: [
        for (final track in ['drill', 'scanner', 'warehouse', 'lift'])
          UpgradeRow(controller: controller, track: track, compact: true),
      ],
    ),
  );
}

class _QuestDock extends StatelessWidget {
  const _QuestDock({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final quest = controller.currentQuest;
    final progress = controller.currentQuestProgress;
    final ratio = quest.target <= 0
        ? 0.0
        : (progress / quest.target).clamp(0, 1).toDouble();
    return GamePanel(
      title: 'GÖREVLER',
      icon: Icons.assignment_turned_in_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            quest.title,
            style: const TextStyle(
              color: MinePalette.cream,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quest.description,
            style: const TextStyle(color: MinePalette.muted, fontSize: 10),
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: MinePalette.ink,
            color: MinePalette.teal,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progress / ${quest.target}',
                style: const TextStyle(color: MinePalette.muted, fontSize: 10),
              ),
              Text(
                '+${quest.reward} kasa',
                style: const TextStyle(
                  color: MinePalette.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: controller.currentQuestReady
                  ? controller.claimCurrentQuest
                  : null,
              child: Text(
                controller.currentQuestReady ? 'ÖDÜLÜ AL' : 'GÖREVİ TAKİP ET',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MineShaftView extends StatefulWidget {
  const _MineShaftView({required this.controller});

  final GameController controller;

  @override
  State<_MineShaftView> createState() => _MineShaftViewState();
}

class _MineShaftViewState extends State<_MineShaftView> {
  final ScrollController _cameraController = ScrollController();
  bool _manualCamera = false;
  bool _hasAutoFollowed = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _followActiveDepth(double maxOffset) {
    if (_manualCamera) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _manualCamera || !_cameraController.hasClients) return;
      final position = _cameraController.position;
      final target = maxOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((position.pixels - target).abs() < 1) return;
      if (!_hasAutoFollowed) {
        _hasAutoFollowed = true;
        _cameraController.jumpTo(target);
        return;
      }
      _cameraController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle &&
        !_manualCamera) {
      setState(() => _manualCamera = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.state;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final narrow = width < 690;
        final worldIndex = state.activeWorldIndex.clamp(0, 2).toInt();
        final worldStartDepth = GameState.worldEntryDepths[worldIndex];
        final worldDepth = math.max(
          state.depthMeters,
          state.worldDepths[worldIndex.toString()] ?? worldStartDepth,
        );
        final localDeepest = math.max(0.0, worldDepth - worldStartDepth);
        final floorCount = (localDeepest / _mineVisualFloorMeters).floor() + 1;
        final floorHeight = math.max(288.0, height * 1.05);
        final localDepth = (state.depthMeters - worldStartDepth)
            .clamp(0.0, localDeepest)
            .toDouble();
        final activeFloor = (localDepth / _mineVisualFloorMeters).floor().clamp(
          0,
          floorCount - 1,
        );
        final progressInFloor =
            (localDepth % _mineVisualFloorMeters) / _mineVisualFloorMeters;
        const buffBottom = 56.0;
        _followActiveDepth(
          localDepth / _mineVisualFloorMeters * floorHeight - height * .46,
        );
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Semantics(
                label: 'Maden katmanları',
                hint: 'Etkin derinliğin üstündeki ve altındaki katmanları kaydır.',
                explicitChildNodes: true,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScroll,
                  child: ListView.builder(
                    key: const ValueKey('mine-world'),
                    controller: _cameraController,
                    physics: const ClampingScrollPhysics(),
                    itemCount: floorCount,
                    itemExtent: floorHeight,
                    itemBuilder: (context, floorIndex) {
                      return SizedBox(
                        key: ValueKey('mine-floor-$worldIndex-$floorIndex'),
                        width: width,
                        height: floorHeight,
                        child: _MineWorld(
                          controller: controller,
                          width: width,
                          height: floorHeight,
                          narrow: narrow,
                          floorIndex: floorIndex,
                          isActiveFloor: floorIndex == activeFloor,
                          progressInFloor: progressInFloor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(top: 10, left: 12, child: _WorldPill(state: state)),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xD90A2029),
                  border: Border.all(color: MinePalette.border),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 15,
                      color: MinePalette.cyan,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${state.drillRateMetersPerSecond.toStringAsFixed(1)} m/sn',
                      style: const TextStyle(
                        color: MinePalette.cream,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.resonanceBuffUntil?.isAfter(DateTime.now()) == true)
              Positioned(
                left: 12,
                bottom: buffBottom,
                child: _BuffPill(
                  seconds: state.resonanceBuffUntil!
                      .difference(DateTime.now())
                      .inSeconds,
                ),
              ),
            if (state.cargoFull)
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xE62A1C1A),
                    border: Border.all(color: MinePalette.danger),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.inventory_rounded,
                        color: MinePalette.danger,
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Kargo dolu • Ambarı açıp kaynakları sat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_manualCamera)
              Positioned(
                right: 10,
                top: 88,
                child: IconButton.filledTonal(
                  tooltip: 'Aktif derinliğe dön',
                  onPressed: () => setState(() => _manualCamera = false),
                  icon: const Icon(Icons.my_location_rounded),
                ),
              )
            else if (state.tutorialStep >= 5)
              Positioned(
                right: 12,
                top: 91,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD90A2029),
                      border: Border.all(color: MinePalette.border),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe_vertical_rounded,
                          color: MinePalette.cyan,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'KATLARI KAYDIR',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MineWorld extends StatelessWidget {
  const _MineWorld({
    required this.controller,
    required this.width,
    required this.height,
    required this.narrow,
    required this.floorIndex,
    required this.isActiveFloor,
    required this.progressInFloor,
  });

  final GameController controller;
  final double width;
  final double height;
  final bool narrow;
  final int floorIndex;
  final bool isActiveFloor;
  final double progressInFloor;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final worldIndex = state.activeWorldIndex.clamp(0, 2).toInt();
    final minorVariant = (floorIndex % 100) ~/ 50;
    final deposits =
        state.oreDeposits.values
            .where(
              (deposit) =>
                  deposit.worldIndex == worldIndex &&
                  deposit.floorIndex == floorIndex &&
                  !deposit.depleted,
            )
            .toList()
          ..sort((left, right) => left.id.compareTo(right.id));
    final galleryFloors = _galleryHeightRatios
        .map((ratio) => height * ratio)
        .toList(growable: false);
    final shaftWidth = narrow ? 86.0 : 112.0;
    final elevatorWidth = narrow ? 122.0 : 164.0;
    final elevatorHeight = elevatorWidth * 2 / 3;
    final rigWidth = narrow ? 108.0 : 136.0;
    final rigHeight = rigWidth * 1.107;
    final robotWidth = narrow ? 38.0 : 48.0;
    final robotHeight = narrow ? 38.0 : 48.0;
    final workerGap = narrow ? 7.0 : 12.0;
    final shaftLeft = (width - shaftWidth) / 2;
    final workerSlots = _layoutMineWorkers(
      crewCount: state.crewCount,
      width: width,
      height: height,
      narrow: narrow,
      shaftLeft: shaftLeft,
      shaftWidth: shaftWidth,
      workerGap: workerGap,
    );
    final oreNodes = _layoutMineOreNodes(
      deposits: deposits,
      width: width,
      height: height,
      narrow: narrow,
    );
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _MineBasePainter())),
        Positioned.fill(
          child: Opacity(
            opacity: 0.78,
            child: CaveTextureBackground(
              asset: _mineWallAsset(
                worldIndex: worldIndex,
                majorBand: floorIndex ~/ 100,
              ),
              floorVariant: floorIndex,
              minorTint: _mineMinorTint(
                worldIndex: worldIndex,
                variant: minorVariant,
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: CustomPaint(painter: _MineLightingPainter()),
        ),
        Positioned(
          left: (width - shaftWidth) / 2,
          top: 0,
          bottom: 0,
          width: shaftWidth,
          child: IgnorePointer(
            child: VerticalShaftBackground(verticalOffset: floorIndex * height),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _ShaftPainter(variant: minorVariant)),
        ),
        Positioned(
          left: 8,
          top: 48,
          child: Container(
            key: ValueKey('mine-floor-label-$worldIndex-$floorIndex'),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xD90A2029),
              border: Border.all(color: MinePalette.border),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${_depthLabel((GameState.worldEntryDepths[worldIndex] + floorIndex * 1000).round())} – '
              '${_depthLabel((GameState.worldEntryDepths[worldIndex] + (floorIndex + 1) * 1000).round())}',
              style: const TextStyle(
                color: MinePalette.cream,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        if (isActiveFloor)
          Positioned(
            left: (width - elevatorWidth) / 2,
            top:
                galleryFloors.first -
                elevatorHeight +
                (galleryFloors.last - galleryFloors.first) * progressInFloor,
            width: elevatorWidth,
            height: elevatorHeight,
            child: IgnorePointer(
              child: Image.asset(
                'assets/packs/mine-elevator-car.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        for (var worker = 0; worker < workerSlots.length; worker++)
          Positioned(
            left: workerSlots[worker].left,
            top: workerSlots[worker].top,
            child: IgnorePointer(
              child: AnimatedCrewSprite(
                key: ValueKey('mine-worker-$floorIndex-$worker'),
                index: worker.isEven ? 0 : 1,
                action: CrewAction.mining,
                detailedMiningAnimation: true,
                width: workerSlots[worker].width,
                height: workerSlots[worker].height,
                phaseOffset: worker * .31,
              ),
            ),
          ),
        if (isActiveFloor && state.drones > 0)
          Positioned(
            left: math.max(0, shaftLeft - robotWidth - workerGap).toDouble(),
            top: galleryFloors[2] - robotHeight,
            child: IgnorePointer(
              child: AnimatedCrewSprite(
                index: 3,
                action: CrewAction.scanning,
                width: robotWidth,
                height: robotHeight,
                phaseOffset: .42,
              ),
            ),
          ),
        if (isActiveFloor)
          Positioned(
            left: (width - rigWidth) / 2,
            top: galleryFloors.last - rigHeight,
            child: IgnorePointer(
              child: ContinuousDrillRig(width: rigWidth, height: rigHeight),
            ),
          ),
        for (var index = 0; index < deposits.length; index++)
          _OreNode(
            deposit: deposits[index],
            resource: ResourceCatalog.byId[deposits[index].resourceId]!,
            placement: oreNodes[index],
            onTap: () => controller.mineDeposit(deposits[index].id),
          ),
      ],
    );
  }
}

class _MineWorkerPlacement {
  const _MineWorkerPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

List<_MineWorkerPlacement> _layoutMineWorkers({
  required int crewCount,
  required double width,
  required double height,
  required bool narrow,
  required double shaftLeft,
  required double shaftWidth,
  required double workerGap,
}) {
  if (crewCount <= 0) return const [];
  final workerCount = math.min(crewCount, _galleryHeightRatios.length);
  final workerWidth = narrow ? 46.0 : 60.0;
  final workerHeight = narrow ? 62.0 : 80.0;
  final galleryFloors = _galleryHeightRatios
      .map((ratio) => height * ratio)
      .toList(growable: false);
  final firstGallery = galleryFloors.length - workerCount;
  final placements = <_MineWorkerPlacement>[];

  for (var worker = 0; worker < workerCount; worker++) {
    final side = worker.isEven ? 0 : 1;
    final left = side == 0
        ? shaftLeft - workerGap - workerWidth
        : shaftLeft + shaftWidth + workerGap;
    final floorY = galleryFloors[firstGallery + worker];
    placements.add(
      _MineWorkerPlacement(
        left: left,
        top: floorY - 8 - workerHeight,
        width: workerWidth,
        height: workerHeight,
      ),
    );
  }
  return placements;
}

const Map<int, double> _oreSpriteBottoms = {
  0: 270 / 271,
  1: 267 / 271,
  2: 268 / 271,
  3: 1,
  4: 264 / 272,
  5: 262 / 272,
  6: 265 / 272,
  7: 261 / 272,
  8: 1,
  9: 1,
};

Rect _oreSpriteCrop(int iconIndex) =>
    Rect.fromLTRB(0, 0, 1, _oreSpriteBottoms[iconIndex] ?? 1);

class _OreNode extends StatelessWidget {
  const _OreNode({
    required this.deposit,
    required this.resource,
    required this.placement,
    required this.onTap,
  });

  final OreDepositState deposit;
  final ResourceDefinition resource;
  final _OreNodePlacement placement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: placement.left,
      top: placement.top,
      child: SizedBox(
        key: ValueKey('ore-node-${deposit.id}'),
        width: placement.width,
        height: placement.height,
        child: Semantics(
          button: true,
          label: '${resource.name} cevher taşı',
          hint: 'Kırmak için dokun.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: placement.iconWidth,
                height: placement.iconHeight,
                child: AtlasSprite(
                  asset: 'resources-treasure-sheet.png',
                  index: resource.iconIndex,
                  columns: 4,
                  rows: 4,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  sourceCrop: _oreSpriteCrop(resource.iconIndex),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OreNodePlacement {
  const _OreNodePlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.iconWidth,
    required this.iconHeight,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double iconWidth;
  final double iconHeight;
}

List<_OreNodePlacement> _layoutMineOreNodes({
  required List<OreDepositState> deposits,
  required double width,
  required double height,
  required bool narrow,
}) {
  if (deposits.isEmpty) return const [];
  const wallInset = 4.0;
  final shaftWidth = narrow ? 86.0 : 112.0;
  final shaftLeft = (width - shaftWidth) / 2;
  final workerWidth = narrow ? 46.0 : 60.0;
  final workerGap = narrow ? 7.0 : 12.0;
  final nodeWidth = math.min(
    narrow ? 88.0 : 108.0,
    math.max(48.0, shaftLeft - workerGap - workerWidth - wallInset - 4),
  );
  final nodeHeight = narrow ? 76.0 : 90.0;
  final iconWidth = math.min(nodeWidth - 4, narrow ? 84.0 : 104.0);
  final iconHeight = narrow ? 68.0 : 82.0;
  final floors = _galleryHeightRatios
      .map((ratio) => height * ratio)
      .toList(growable: false);
  final galleryCount = floors.length;
  final occupiedSlots = <int>{};
  final placements = <_OreNodePlacement>[];

  for (var index = 0; index < deposits.length; index++) {
    final deposit = deposits[index];
    final preferredGallery = deposit.pocket.clamp(0, galleryCount - 1).toInt();
    final preferredSide = deposit.side.clamp(0, 1).toInt();
    final preferredSlot = preferredSide * galleryCount + preferredGallery;
    var slot = preferredSlot;
    for (var offset = 0; offset < galleryCount * 2; offset++) {
      final candidate = (preferredSlot + offset) % (galleryCount * 2);
      if (occupiedSlots.add(candidate)) {
        slot = candidate;
        break;
      }
    }
    final side = slot ~/ galleryCount;
    final gallery = slot % galleryCount;
    final floorY = floors[gallery];
    final floorSurfaceY = floorY - 8;
    placements.add(
      _OreNodePlacement(
        left: side == 0 ? wallInset : width - wallInset - nodeWidth,
        top: floorSurfaceY - nodeHeight,
        width: nodeWidth,
        height: nodeHeight,
        iconWidth: iconWidth,
        iconHeight: iconHeight,
      ),
    );
  }
  return placements;
}

class _MineActionBar extends StatelessWidget {
  const _MineActionBar({required this.controller, required this.onUtility});

  final GameController controller;
  final ValueChanged<String> onUtility;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 690;
      final veryNarrow = constraints.maxWidth < 450;
      final shortcuts = veryNarrow
          ? [
              (Icons.engineering_rounded, 'EKİP', 'workshop'),
              (Icons.inventory_2_rounded, 'AMBAR', 'warehouse'),
            ]
          : compact
          ? [
              (Icons.engineering_rounded, 'EKİP', 'workshop'),
              (
                Icons.inventory_2_rounded,
                'SANDIK ${controller.state.totalChestsFound}',
                'trade',
              ),
              (Icons.inventory_2_outlined, 'AMBAR', 'warehouse'),
            ]
          : [
              (Icons.engineering_rounded, 'EKİP', 'workshop'),
              (
                Icons.inventory_2_rounded,
                'SANDIK ${controller.state.totalChestsFound}',
                'trade',
              ),
              (Icons.inventory_2_outlined, 'AMBAR', 'warehouse'),
              (Icons.map_rounded, 'SEFER', 'expedition'),
            ];
      final actionWidth = veryNarrow
          ? 52.0
          : compact
          ? 63.0
          : 77.0;
      final digWidth = veryNarrow
          ? math.min(178.0, constraints.maxWidth * .44)
          : compact
          ? 198.0
          : 206.0;
      final gap = compact ? 5.0 : 7.0;
      return Container(
        height: 74,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xF0071B24), Color(0xF80B2732)],
          ),
          border: const Border(
            top: BorderSide(color: MinePalette.border, width: 1.3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < shortcuts.length; index++) ...[
              SizedBox(
                width: actionWidth,
                child: _SquareAction(
                  icon: shortcuts[index].$1,
                  label: shortcuts[index].$2,
                  onTap: () => onUtility(shortcuts[index].$3),
                ),
              ),
              SizedBox(width: gap),
            ],
            SizedBox(
              width: digWidth,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: controller.state.cargoFull ? null : controller.dig,
                icon: Icon(Icons.bolt_rounded, size: compact ? 21 : 25),
                label: Text(
                  'KAZI',
                  style: TextStyle(
                    fontSize: compact ? 17 : 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBE3E),
                  foregroundColor: const Color(0xFF201509),
                  side: const BorderSide(color: Color(0xFFFFE08B), width: 2),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: SizedBox(
      height: 56,
      child: Material(
        color: const Color(0xFF102E3A),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: MinePalette.cyan),
              const SizedBox(height: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _WorldPill extends StatelessWidget {
  const _WorldPill({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xE509202A),
      border: Border.all(color: MinePalette.border),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AtlasSprite(
          asset: 'ui-icon-sheet.png',
          index: 9,
          columns: 4,
          rows: 4,
          width: 21,
          height: 21,
        ),
        const SizedBox(width: 5),
        Text(
          '${state.currentWorldName} • ${_depthLabel(state.deepestMeters.floor())}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _BuffPill extends StatelessWidget {
  const _BuffPill({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xE40D3C3A),
      border: Border.all(color: MinePalette.teal),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt_rounded, size: 15, color: MinePalette.teal),
        const SizedBox(width: 4),
        Text(
          'REZONANS • ${_duration(seconds)}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _MineBasePainter extends CustomPainter {
  const _MineBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF392D27), Color(0xFF211F22), Color(0xFF111B25)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _MineBasePainter oldDelegate) => false;
}

class _MineLightingPainter extends CustomPainter {
  const _MineLightingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (var level = 0; level < 4; level++) {
      final ceiling = size.height * level / 4;
      final positions = level.isEven ? [.17, .79] : [.32, .88];
      for (final ratio in positions) {
        final x = size.width * ratio;
        final y = ceiling + 26;
        final glowRect = Rect.fromCircle(
          center: Offset(x, y + 12),
          radius: size.width < 700 ? 42 : 58,
        );
        canvas.drawCircle(
          glowRect.center,
          glowRect.width / 2,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0x66FFAE32),
                const Color(0x22E58A22),
                const Color(0x00E58A22),
              ],
              stops: const [0, .42, 1],
            ).createShader(glowRect),
        );
        canvas.drawLine(
          Offset(x, ceiling + 2),
          Offset(x, y - 5),
          Paint()
            ..color = const Color(0xFF493426)
            ..strokeWidth = 2,
        );
        final lamp = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 8, height: 12),
          const Radius.circular(2),
        );
        canvas.drawRRect(lamp, Paint()..color = const Color(0xFF55391F));
        canvas.drawRRect(
          lamp.deflate(2),
          Paint()..color = const Color(0xFFFFB642),
        );
      }
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x00091420), Color(0x4D06101A)],
        stops: const [.52, 1],
        radius: 1.2,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MineLightingPainter oldDelegate) => false;
}

class _ShaftPainter extends CustomPainter {
  const _ShaftPainter({this.variant = 0});

  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final shaftWidth = size.width < 690 ? 86.0 : 112.0;
    final x = (size.width - shaftWidth) / 2;
    for (var level = 0; level < _galleryHeightRatios.length; level++) {
      final y = size.height * _galleryHeightRatios[level];
      final nextY = level + 1 < _galleryHeightRatios.length
          ? size.height * _galleryHeightRatios[level + 1]
          : size.height - 7;
      final spans = <(double, double)>[
        (0, x - 3),
        (x + shaftWidth + 3, size.width),
      ];
      for (final (start, end) in spans) {
        final beam = Rect.fromLTRB(start, y - 7, end, y + 10);
        canvas.drawRect(beam, Paint()..color = const Color(0xFF1C1715));
        canvas.drawRect(
          Rect.fromLTRB(start, y - 7, end, y - 3),
          Paint()
            ..color = variant == 0
                ? const Color(0xFFA67543)
                : const Color(0xFF957B56),
        );
        canvas.drawRect(
          Rect.fromLTRB(start, y - 8, end, y - 6),
          Paint()..color = const Color(0xFFE0AC5C),
        );
        canvas.drawRect(
          Rect.fromLTRB(start, y + 2, end, y + 8),
          Paint()
            ..color = variant == 0
                ? const Color(0xFF39291F)
                : const Color(0xFF32312C),
        );
        for (var plank = start + 70; plank < end; plank += 112) {
          canvas.drawLine(
            Offset(plank, y - 6),
            Offset(plank, y + 5),
            Paint()
              ..color = const Color(0xFF4D382A)
              ..strokeWidth = 3,
          );
          canvas.drawCircle(
            Offset(plank + 7, y - 4),
            1.7,
            Paint()..color = const Color(0xFFE5B66B),
          );
        }

        for (final supportRatio in [.08, .92]) {
          final supportX = start + (end - start) * supportRatio;
          final supportHeight = nextY - y - 17;
          if (supportHeight <= 0) continue;
          final support = Rect.fromLTWH(supportX - 5, y + 9, 10, supportHeight);
          canvas.drawRect(support, Paint()..color = const Color(0xFF30241D));
          canvas.drawRect(
            Rect.fromLTWH(supportX - 1, support.top, 3, support.height),
            Paint()..color = const Color(0xFF785238),
          );
          canvas.drawRect(
            Rect.fromLTWH(support.left + 1, support.top, 2, 3),
            Paint()..color = const Color(0xFFE5B66B),
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShaftPainter oldDelegate) =>
      variant != oldDelegate.variant;
}

String _depthLabel(int meters) =>
    meters >= 1000 ? '${_number(meters ~/ 1000)} km' : '$meters m';

String _number(num value) {
  final raw = value.round().toString();
  final result = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) result.write('.');
    result.write(raw[i]);
  }
  return result.toString();
}

String _duration(int seconds) {
  final safe = math.max(0, seconds);
  final minutes = safe ~/ 60;
  final remainingSeconds = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

String _tutorialText(int step) => switch (step) {
  0 => '1 / 5  •  Kömür yığınını birkaç kez tıklayıp kır; cevheri topla.',
  1 => '2 / 5  •  Ambarı açıp topladığın cevheri sat.',
  2 => '3 / 5  •  Satış kasasıyla atölyeden ilk madencini işe al.',
  3 => '4 / 5  •  Atölyeden sondaj ucunu yükselt.',
  4 => '5 / 5  •  KAZI ile kuyuyu ilerlet veya yüzey binalarını keşfet.',
  _ => '',
};
