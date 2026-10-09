import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart' show Ticker;

import '../app/game_controller.dart';
import '../core/design/palette.dart';
import '../domain/models/advisor_guide.dart';
import '../domain/models/drill_assembly_definition.dart';
import '../domain/models/mine_event_definition.dart';
import '../domain/models/game_state.dart';
import '../domain/models/mr_mine_big_number.dart';
import '../domain/models/quest_definition.dart';
import '../domain/models/resource_definition.dart';
import '../domain/models/ore_deposit.dart';
import '../domain/simulation/game_engine.dart';
import '../services/sound_service.dart';
import 'widgets/atlas_sprite.dart';
import 'widgets/building_dialog.dart';
import 'widgets/character_animation.dart';
import 'widgets/game_primitives.dart';
import 'widgets/loading_screen.dart';
import 'widgets/opening_comic.dart';
import 'widgets/settings_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _offlineDialogShown = false;
  bool _hasRenderedReadyState = false;
  bool _showOpeningComic = false;
  String? _activeNotice;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.state.musicEnabled) {
        unawaited(SoundService.instance.startBgm());
      }
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (!widget.controller.isReady) return;
    if (!_hasRenderedReadyState) {
      _hasRenderedReadyState = true;
      setState(() {});
    }
    final notices = widget.controller.takeNotices();
    if (notices.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _noticeTimer?.cancel();
      setState(() => _activeNotice = notices.last);
      _noticeTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _activeNotice = null);
      });
    });
  }

  void _openBuilding(String id) {
    if (!widget.controller.state.canOpenBuilding(id)) {
      widget.controller.showNotice(_lockedBuildingMessage());
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) =>
          BuildingDialog(controller: widget.controller, buildingId: id),
    );
  }

  void _openUtilities(String panel) {
    if (!widget.controller.state.canOpenBuilding(panel)) {
      widget.controller.showNotice(_lockedBuildingMessage());
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) =>
          BuildingDialog(controller: widget.controller, buildingId: panel),
    );
  }

  void _openAdvisorGuide(AdvisorGuideDefinition guide) {
    if (guide.isTutorial) {
      final targetPanel = guide.targetPanel;
      if (targetPanel != null) _openUtilities(targetPanel);
      return;
    }
    widget.controller.acknowledgeAdvisorGuide(guide.id);
    final targetPanel = guide.targetPanel;
    if (targetPanel != null) _openUtilities(targetPanel);
  }

  String _lockedBuildingMessage() {
    if (!widget.controller.state.initialTutorialComplete) {
      return 'Danışman robotun görevini tamamlayınca bu sistem açılacak.';
    }
    final guide = AdvisorGuideCatalog.currentFor(widget.controller.state);
    if (guide != null) {
      return 'Önce danışman robotun ${guide.targetLabel} tanıtımını tamamla.';
    }
    return 'Bu sistem henüz açılmadı.';
  }

  void _openSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => SettingsDialog(
        controller: widget.controller,
        onReplayOpeningComic: _replayOpeningComic,
      ),
    );
  }

  void _replayOpeningComic() {
    if (!mounted) return;
    widget.controller.pauseSimulation();
    setState(() => _showOpeningComic = true);
  }

  void _finishOpeningComic() {
    widget.controller.markOpeningComicSeen();
    widget.controller.resumeSimulation();
    if (mounted) setState(() => _showOpeningComic = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isReady) {
      return const MineLoadingScreen();
    }
    if (widget.controller.initializationError != null) {
      return Scaffold(
        backgroundColor: MinePalette.ink,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: MinePalette.amber,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Oyun başlatılamadı',
                    style: TextStyle(
                      color: MinePalette.cream,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.controller.initializationError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: MinePalette.muted),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sayfayı yenileyip tekrar deneyin.',
                    style: TextStyle(color: MinePalette.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
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
        bottom: false,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1120;
              final hudHeight = constraints.maxWidth < 560
                  ? 92.0
                  : compact
                  ? 58.0
                  : 70.0;
              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
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
                          onSettings: _openSettings,
                          onToggleSound: () =>
                              widget.controller.setSoundEffectsEnabled(
                                !widget.controller.state.soundEffectsEnabled,
                              ),
                        ),
                        Expanded(
                          child: TickerMode(
                            enabled:
                                widget.controller.state.visualEffectsEnabled,
                            child: compact
                                ? _CompactGameLayout(
                                    controller: widget.controller,
                                    onBuilding: _openBuilding,
                                    onUtility: _openUtilities,
                                    onAdvisorGuide: _openAdvisorGuide,
                                  )
                                : _WideGameLayout(
                                    controller: widget.controller,
                                    onBuilding: _openBuilding,
                                    onUtility: _openUtilities,
                                    onAdvisorGuide: _openAdvisorGuide,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_activeNotice != null)
                    Positioned(
                      top: hudHeight + 8,
                      left: 12,
                      right: 12,
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Container(
                                key: ValueKey(_activeNotice),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xEA092129),
                                  border: Border.all(
                                    color: MinePalette.cyan,
                                    width: 1.2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 9,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _activeNotice!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: MinePalette.cream,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_showOpeningComic ||
                      !widget.controller.state.openingComicSeen)
                    Positioned.fill(
                      key: const ValueKey('opening-comic-overlay'),
                      child: OpeningComicOverlay(onFinish: _finishOpeningComic),
                    ),
                ],
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
    _noticeTimer?.cancel();
    super.dispose();
  }
}

class _HudBar extends StatelessWidget {
  const _HudBar({
    required this.state,
    required this.onSettings,
    required this.onToggleSound,
  });

  final GameState state;
  final VoidCallback onSettings;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final portraitPhone = constraints.maxWidth < 560;
      final compact = constraints.maxWidth < 1120;
      final chips = [
        _HudChip(
          icon: Icons.currency_exchange_rounded,
          label: 'KASA',
          value: state.debugMoneyEnabled ? '∞' : _formatCoins(state.coins),
          color: MinePalette.amber,
          compact: compact,
        ),
        _CargoHudChip(
          value:
              '${state.cargoUsed.toStringAsFixed(0)} / ${state.effectiveCargoCapacity.toStringAsFixed(0)}',
          compact: compact,
          full: state.cargoFull,
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
                      tooltip: state.soundEffectsEnabled
                          ? 'Ses efektlerini kapat'
                          : 'Ses efektlerini aç',
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggleSound,
                      icon: Icon(
                        state.soundEffectsEnabled
                            ? Icons.volume_up_outlined
                            : Icons.volume_off_outlined,
                        color: MinePalette.muted,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ayarlar',
                      visualDensity: VisualDensity.compact,
                      onPressed: onSettings,
                      icon: const Icon(
                        Icons.settings_outlined,
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
              tooltip: state.soundEffectsEnabled
                  ? 'Ses efektlerini kapat'
                  : 'Ses efektlerini aç',
              visualDensity: compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              onPressed: onToggleSound,
              icon: Icon(
                state.soundEffectsEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                color: MinePalette.muted,
                size: compact ? 20 : 24,
              ),
            ),
            IconButton(
              tooltip: 'Ayarlar',
              visualDensity: compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              onPressed: onSettings,
              icon: Icon(
                Icons.settings_outlined,
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
    this.alarmProgress = 0,
    this.alarmColor = MinePalette.amber,
    this.alarmBackground = const Color(0xFF352D1D),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;
  final double alarmProgress;
  final Color alarmColor;
  final Color alarmBackground;

  @override
  Widget build(BuildContext context) {
    final pulse = alarmProgress.clamp(0, 1).toDouble();
    return Container(
      width: compact ? 88 : 144,
      height: compact ? 37 : 51,
      margin: EdgeInsets.only(right: compact ? 4 : 7),
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF102D3A), alarmBackground, pulse),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Color.lerp(MinePalette.border, alarmColor, pulse)!,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          if (pulse > 0)
            BoxShadow(
              color: alarmColor.withValues(alpha: pulse * .3),
              blurRadius: 3 + pulse * 5,
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Color.lerp(color, alarmColor, pulse),
            size: compact ? 15 : 22,
          ),
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
                    color: Color.lerp(MinePalette.muted, alarmColor, pulse),
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
                      color: Color.lerp(
                        MinePalette.cream,
                        alarmColor,
                        pulse * .7,
                      ),
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
}

class _CargoHudChip extends StatefulWidget {
  const _CargoHudChip({
    required this.value,
    required this.compact,
    required this.full,
  });

  final String value;
  final bool compact;
  final bool full;

  @override
  State<_CargoHudChip> createState() => _CargoHudChipState();
}

class _CargoHudChipState extends State<_CargoHudChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _alarm;

  @override
  void initState() {
    super.initState();
    _alarm = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    if (widget.full) _alarm.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _CargoHudChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.full == widget.full) return;
    if (widget.full) {
      _alarm.repeat(reverse: true);
    } else {
      _alarm.stop();
      _alarm.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _alarm,
    builder: (context, _) => _HudChip(
      icon: Icons.diamond_rounded,
      label: 'KARGO',
      value: widget.value,
      color: MinePalette.teal,
      compact: widget.compact,
      alarmProgress: widget.full ? _alarm.value : 0,
      alarmColor: MinePalette.danger,
      alarmBackground: const Color(0xFF43171D),
    ),
  );

  @override
  void dispose() {
    _alarm.dispose();
    super.dispose();
  }
}

class _WideGameLayout extends StatelessWidget {
  const _WideGameLayout({
    required this.controller,
    required this.onBuilding,
    required this.onUtility,
    required this.onAdvisorGuide,
  });

  final GameController controller;
  final ValueChanged<String> onBuilding;
  final ValueChanged<String> onUtility;
  final ValueChanged<AdvisorGuideDefinition> onAdvisorGuide;

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
            _GoalBanner(
              controller: controller,
              guide: AdvisorGuideCatalog.currentFor(controller.state),
              onOpenTarget: onAdvisorGuide,
              onOpenUtility: onUtility,
            ),
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
    required this.onAdvisorGuide,
  });

  final GameController controller;
  final ValueChanged<String> onBuilding;
  final ValueChanged<String> onUtility;
  final ValueChanged<AdvisorGuideDefinition> onAdvisorGuide;

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
          _GoalBanner(
            controller: controller,
            guide: AdvisorGuideCatalog.currentFor(controller.state),
            onOpenTarget: onAdvisorGuide,
            onOpenUtility: onUtility,
          ),
          mineEventBanner,
          _CompactActionBar(controller: controller, onUtility: onUtility),
        ],
      );
    },
  );
}

class _GoalBanner extends StatelessWidget {
  const _GoalBanner({
    required this.controller,
    required this.guide,
    required this.onOpenTarget,
    required this.onOpenUtility,
  });

  final GameController controller;
  final AdvisorGuideDefinition? guide;
  final ValueChanged<AdvisorGuideDefinition> onOpenTarget;
  final ValueChanged<String> onOpenUtility;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final quest = controller.currentQuest;
    final progress = controller.currentQuestProgress;
    final isTutorial = guide?.isTutorial ?? false;
    final tutorialNumber =
        state.claimedQuestIds
            .where((id) => id >= 0 && id < 5)
            .length
            .clamp(0, 4)
            .toInt() +
        1;
    final title = guide == null
        ? quest.title
        : isTutorial
        ? '$tutorialNumber / 5 • ${guide!.title}'
        : guide!.title;
    final message = guide?.message ?? quest.description;
    final detail = _goalRequirementLine(controller, guide: guide, quest: quest);
    final targetPanel = _questTargetPanel(quest);
    final ready = controller.currentQuestReady;
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 0, 9, 5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            key: const ValueKey('goal-banner'),
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xF10A242E),
              border: Border.all(color: MinePalette.amber, width: 1.3),
              borderRadius: BorderRadius.circular(9),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3440),
                    shape: BoxShape.circle,
                    border: Border.all(color: MinePalette.teal, width: 1.4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x6634D3CB), blurRadius: 9),
                    ],
                  ),
                  child: const AnimatedCrewSprite(
                    index: 3,
                    action: CrewAction.scanning,
                    width: 52,
                    height: 52,
                    phaseOffset: .29,
                    advisorDroneAnimation: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MinePalette.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MinePalette.cream,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guide == null && quest.kind == QuestKind.depth
                            ? '$detail • $progress / ${quest.target} m'
                            : detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MinePalette.teal,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (guide == null ||
                    !isTutorial ||
                    ready ||
                    guide!.targetPanel != null) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: guide == null
                          ? ready
                                ? controller.claimCurrentQuest
                                : () => onOpenUtility(targetPanel ?? 'quests')
                          : isTutorial
                          ? ready
                                ? controller.claimCurrentQuest
                                : () => onOpenTarget(guide!)
                          : () => onOpenTarget(guide!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MinePalette.amber,
                        foregroundColor: MinePalette.ink,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        textStyle: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: Text(
                        guide == null
                            ? ready
                                  ? 'AL'
                                  : targetPanel == null
                                  ? 'GÖREV'
                                  : 'AÇ'
                            : isTutorial
                            ? ready
                                  ? 'AL'
                                  : 'AÇ'
                            : guide!.targetPanel == null
                            ? 'TAMAM'
                            : 'AÇ',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvisorTargetMarker extends StatelessWidget {
  const _AdvisorTargetMarker({this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xEE0B3440),
        shape: BoxShape.circle,
        border: Border.all(color: MinePalette.teal, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0xAA34D3CB), blurRadius: 10)],
      ),
      child: AnimatedCrewSprite(
        index: 3,
        action: CrewAction.scanning,
        width: size - 2,
        height: size - 2,
        phaseOffset: .29,
        advisorDroneAnimation: true,
      ),
    ),
  );
}

class _QuestCountBadge extends StatelessWidget {
  const _QuestCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: MinePalette.danger,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: MinePalette.ink, width: 1.2),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3)],
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        height: 1,
        fontWeight: FontWeight.w900,
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
    builder: (context, _) {
      final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
      final viewPadding = MediaQuery.viewPaddingOf(context);
      final unclaimedQuestRewards = controller.unclaimedQuestRewardCount;
      final currentGuideTarget = AdvisorGuideCatalog.currentFor(
        controller.state,
      )?.target;
      final shortcuts = [
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
      return Container(
        width: double.infinity,
        height: 74 + bottomInset,
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
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: LayoutBuilder(
            builder: (context, navConstraints) {
              final width = navConstraints.maxWidth;
              final centerX =
                  (width + viewPadding.right - viewPadding.left) / 2;
              final halfAvailable = math.min(centerX, width - centerX);
              final navWidth = math
                  .min(math.min(width, 560.0), halfAvailable * 2)
                  .toDouble();
              final navLeft = centerX - navWidth / 2;
              final itemWidth = navWidth / shortcuts.length;

              return SizedBox(
                height: 74,
                child: Stack(
                  children: [
                    for (var index = 0; index < shortcuts.length; index++)
                      Positioned(
                        left: navLeft + itemWidth * index,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: _QuickNav(
                            icon: shortcuts[index].$1,
                            label: shortcuts[index].$2,
                            enabled: controller.state.canOpenBuilding(
                              shortcuts[index].$3,
                            ),
                            badgeCount: shortcuts[index].$3 == 'quests'
                                ? unclaimedQuestRewards
                                : 0,
                            highlighted:
                                currentGuideTarget == shortcuts[index].$3 ||
                                (shortcuts[index].$3 == 'quests' &&
                                    unclaimedQuestRewards > 0),
                            onTap: () => onUtility(shortcuts[index].$3),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
    required this.enabled,
    this.badgeCount = 0,
    this.highlighted = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final int badgeCount;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: enabled,
    enabled: enabled,
    label: badgeCount > 0 ? '$label, $badgeCount alınmamış ödül' : label,
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: highlighted
                          ? BoxDecoration(
                              border: Border.all(
                                color: MinePalette.amber,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x99FFBE3E),
                                  blurRadius: 8,
                                ),
                              ],
                            )
                          : null,
                      child: Icon(
                        enabled ? icon : Icons.lock_outline_rounded,
                        size: 18,
                        color: highlighted
                            ? MinePalette.amber
                            : enabled
                            ? MinePalette.cyan
                            : MinePalette.muted,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -6,
                        right: -8,
                        child: _QuestCountBadge(count: badgeCount),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: enabled ? MinePalette.cream : MinePalette.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

const _buildings = <(String, String, int, IconData)>[
  ('warehouse', 'AMBAR', 2, Icons.inventory_2_rounded),
  ('trade', 'TİCARET', 3, Icons.storefront_rounded),
  ('workshop', 'ATÖLYE', 0, Icons.elevator_rounded),
  ('research', 'ARAŞTIRMA', 4, Icons.biotech_rounded),
  ('expedition', 'SEFER', 5, Icons.explore_rounded),
];

const _surfaceBuildingAnchors = <double>[.1, .3, .5, .7, .9];
// Crop each atlas cell to its visible sprite so its foot meets the shared soil.
const _surfaceBuildingSourceCrops = <Rect>[
  Rect.fromLTRB(0, .0625, 1, .925781),
  Rect.fromLTRB(0, .105469, 1, .917969),
  Rect.fromLTRB(0, .199219, 1, .904297),
  Rect.fromLTRB(0, .066406, 1, .841797),
  Rect.fromLTRB(0, 0, 1, .867188),
  Rect.fromLTRB(0, .029297, .978516, .855469),
];

double _surfaceBuildingSpriteHeight(
  int spriteIndex,
  double width,
  double height,
) {
  final crop = _surfaceBuildingSourceCrops[spriteIndex];
  final croppedAspectRatio = crop.width / crop.height;
  final availableHeight = math.max(0.0, height - 18);
  return math.min(availableHeight, width / croppedAspectRatio).toDouble();
}

double _surfaceBuildingHitHeight(
  int spriteIndex,
  double width,
  double height,
) => math.min(
  height,
  _surfaceBuildingSpriteHeight(spriteIndex, width, height) + 18,
);

// Each 1 km tile is one gallery. About five equal galleries fit in a viewport.
const _galleryHeightRatios = <double>[.92];
const int _mineFloorsPerViewport = 5;
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
        final anchors = _surfaceBuildingAnchors;
        const groundBandHeight = 12.0;
        final buttonHeight = math.max(0.0, height - groundBandHeight);
        final buttonWidth = wide
            ? math.min(220.0, width * .18)
            : width < 560
            ? math.min(100.0, width * .18)
            : math.min(170.0, width * .18);
        final buildingHitHeights = [
          for (var index = 0; index < _buildings.length; index++)
            _surfaceBuildingHitHeight(
              _buildings[index].$3,
              buttonWidth,
              buttonHeight,
            ),
        ];
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
              height: groundBandHeight,
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
              bottom: groundBandHeight,
              child: Stack(
                key: const ValueKey('surface-building-layer'),
                clipBehavior: Clip.hardEdge,
                children: [
                  for (var index = 0; index < _buildings.length; index++)
                    Positioned(
                      left: width * anchors[index] - buttonWidth / 2,
                      top: buttonHeight - buildingHitHeights[index],
                      width: buttonWidth,
                      height: buildingHitHeights[index],
                      child: _surfaceBuildingButton(
                        index,
                        buttonWidth,
                        buildingHitHeights[index],
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
      highlighted: AdvisorGuideCatalog.currentFor(state)?.target == item.$1,
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
    required this.highlighted,
    required this.onTap,
  });

  final String id;
  final String label;
  final int spriteIndex;
  final GameState state;
  final double width;
  final double height;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.canOpenBuilding(id);
    final pending =
        id == 'expedition' && state.caveCompletedPending ||
        id == 'research' && state.excavationCompletedPending ||
        id == 'trade' && state.totalChestsFound > 0;
    final crewRole = switch (id) {
      'workshop' => (4, CrewAction.operatingLift),
      'warehouse' => (3, CrewAction.scanning),
      'trade' => (1, CrewAction.hauling),
      'research' => (1, CrewAction.surveying),
      'expedition' => (5, CrewAction.exploring),
      _ => (0, CrewAction.mining),
    };
    final spriteHeight = _surfaceBuildingSpriteHeight(
      spriteIndex,
      width,
      height,
    );
    final labelTop = (height - spriteHeight - 18)
        .clamp(0.0, math.max(0.0, height - 15))
        .toDouble();
    return Semantics(
      button: unlocked,
      enabled: unlocked,
      label: unlocked ? '$label binasını aç' : '$label kilitli',
      key: ValueKey('surface-building-$id'),
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: unlocked ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: spriteHeight,
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
                if (highlighted)
                  Positioned(
                    right: 0,
                    top: labelTop + 16,
                    child: const _AdvisorTargetMarker(size: 30),
                  ),
                if (!unlocked)
                  Positioned.fill(
                    top: labelTop + 16,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: width < 64 ? 22 : 28,
                          height: width < 64 ? 22 : 28,
                          decoration: BoxDecoration(
                            color: const Color(0xEAF0A23A),
                            border: Border.all(
                              color: const Color(0xFF34251A),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            size: width < 64 ? 14 : 18,
                            color: const Color(0xFF182127),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (highlighted)
                  Positioned.fill(
                    top: labelTop,
                    bottom: 2,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: MinePalette.amber,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: const [
                            BoxShadow(color: Color(0x99FFBE3E), blurRadius: 9),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: labelTop,
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
                    top: labelTop + 16,
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
      1814000,
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
  Widget build(BuildContext context) {
    final state = controller.state;
    final canOpenWorkshop = state.canOpenBuilding('workshop');
    final canOpenResearch = state.canOpenBuilding('research');
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE909202A),
        border: Border(left: BorderSide(color: MinePalette.border)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canOpenWorkshop)
              _UpgradeDock(controller: controller)
            else
              GamePanel(
                title: 'YÜKSELTMELER',
                icon: Icons.lock_outline_rounded,
                child: const Text(
                  'Atölye, ilk görevleri tamamladığında açılacak.',
                  style: TextStyle(color: MinePalette.muted, fontSize: 11),
                ),
              ),
            const SizedBox(height: 10),
            _QuestDock(controller: controller),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: state.canOpenBuilding('achievements')
                  ? () => onUtility('achievements')
                  : null,
              icon: const Icon(Icons.emoji_events_rounded),
              label: Text(
                'BAŞARIMLAR • ${controller.state.unlockedAchievements.length}',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: canOpenResearch ? () => onUtility('research') : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ARAŞTIRMA • DİZİYİ TARA'),
              style: controller.currentQuest.kind == QuestKind.resonance
                  ? OutlinedButton.styleFrom(
                      foregroundColor: MinePalette.amber,
                      side: const BorderSide(
                        color: MinePalette.amber,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            if (state.totalChestsFound > 0) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: state.canOpenBuilding('trade')
                    ? () => controller.openChest(
                        tier: state.deepChests > 0
                            ? 'deep'
                            : state.goldChests > 0
                            ? 'gold'
                            : 'basic',
                      )
                    : null,
                icon: const Icon(Icons.inventory_2_rounded),
                label: Text('${state.totalChestsFound} SANDIĞI AÇ'),
              ),
            ],
            if (GameEngine.availableBossIndex(state) != null) ...[
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
        for (final track in ['drill', 'scanner', 'lift'])
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
    final progressUnit = quest.kind == QuestKind.depth ? ' m' : '';
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
          const SizedBox(height: 4),
          Text(
            _goalRequirementLine(controller, quest: quest),
            style: const TextStyle(
              color: MinePalette.teal,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
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
                '$progress$progressUnit / ${quest.target}$progressUnit',
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
        // The game state advances once per second. Keep the camera glide a
        // little longer than that interval so each update blends into the
        // next instead of stopping between depth ticks.
        duration: const Duration(milliseconds: 1200),
        curve: Curves.linear,
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
        final discoveredFloorCount =
            (localDeepest / _mineVisualFloorMeters).floor() + 1;
        final floorHeight = math.max(96.0, height / _mineFloorsPerViewport);
        final visibleFloorCount = (height / floorHeight).ceil() + 1;
        final floorCount = math.max(discoveredFloorCount, visibleFloorCount);
        final localDepth = (state.depthMeters - worldStartDepth)
            .clamp(0.0, localDeepest)
            .toDouble();
        final drillingFloor = (discoveredFloorCount - 1).clamp(
          0,
          floorCount - 1,
        );
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
                          isActiveFloor: floorIndex == drillingFloor,
                          isDiscoveredFloor: floorIndex < discoveredFloorCount,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _AmbientAdvisorDrone(
                  controller: controller,
                  width: width,
                  height: height,
                  narrow: narrow,
                  cameraController: _cameraController,
                  floorHeight: floorHeight,
                  floorCount: floorCount,
                  manualCamera: _manualCamera,
                ),
              ),
            ),
            Positioned(
              left: (width - (narrow ? 122.0 : 164.0)) / 2,
              top: 0,
              width: narrow ? 122.0 : 164.0,
              height: height,
              child: IgnorePointer(
                child: _MineElevatorMotion(
                  width: narrow ? 122.0 : 164.0,
                  height: height,
                  worldExtent: floorCount * floorHeight,
                  floorHeight: floorHeight,
                  turnaroundFloorIndex: math.max(0, drillingFloor - 1).toInt(),
                  cameraController: _cameraController,
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
            if (controller.currentQuest.kind == QuestKind.resonance ||
                state.resonanceProgress > 0)
              Positioned(
                top: 50,
                left: 12,
                right: 12,
                child: _ResonanceSequenceHint(state: state),
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
    required this.isDiscoveredFloor,
  });

  final GameController controller;
  final double width;
  final double height;
  final bool narrow;
  final int floorIndex;
  final bool isActiveFloor;
  final bool isDiscoveredFloor;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final worldIndex = state.activeWorldIndex.clamp(0, 2).toInt();
    final guideTarget = AdvisorGuideCatalog.currentFor(state)?.target;
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
    final shaftWidth = narrow ? 86.0 : 112.0;
    final rigWidth = math.min((narrow ? 108.0 : 136.0) * 1.3, width * .48);
    final rigHeight = rigWidth * 1.107;
    final edgeRockWidth = narrow ? 32.0 : 48.0;
    final rigLeft = (width - rigWidth) / 2;
    final nextFloorDepth =
        GameState.worldEntryDepths[worldIndex] +
        (floorIndex + 1) * _mineVisualFloorMeters;
    final hasNextFloor =
        nextFloorDepth <= GameEngine.maxDrillDepthForWorld(worldIndex);
    final secondsUntilNextFloor = hasNextFloor
        ? math
              .max(
                0,
                ((nextFloorDepth - state.depthMeters) /
                        math.max(.001, state.drillRateMetersPerSecond))
                    .ceil(),
              )
              .toInt()
        : null;
    final countdownLeft = rigLeft + rigWidth + 6;
    final countdownWidth = math
        .min(128.0, math.max(44.0, width - countdownLeft - edgeRockWidth - 8))
        .toDouble();
    final countdownTop = math.max(4.0, height - rigHeight * .985 - 4);
    final dugGroundCapHeight = math.min(height * .92, width / 3.0).toDouble();
    final edgeTint = switch (worldIndex) {
      1 => const Color(0xFFA9CFDE),
      2 => const Color(0xFFA9C9B0),
      _ => null,
    };
    final groundTint = switch (worldIndex) {
      1 => const Color(0xFF9CC4D2),
      2 => const Color(0xFFB3C79D),
      _ => null,
    };
    final workerGap = narrow ? 7.0 : 12.0;
    final shaftLeft = (width - shaftWidth) / 2;
    final workerSlots = _layoutMineWorkers(
      crewCount: state.activeMinerCount,
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
      clipBehavior: Clip.none,
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
              verticalOffset: floorIndex * height,
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
          left: 0,
          top: 0,
          bottom: 0,
          width: edgeRockWidth,
          child: IgnorePointer(
            child: Opacity(
              opacity: .94,
              child: MineEdgeRockStrip(
                asset: 'mine-edge-rock-tile.png',
                verticalOffset: floorIndex * height,
                tint: edgeTint,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: edgeRockWidth,
          child: IgnorePointer(
            child: Opacity(
              opacity: .94,
              child: MineEdgeRockStrip(
                asset: 'mine-edge-rock-tile.png',
                verticalOffset: floorIndex * height,
                mirroredX: true,
                tint: edgeTint,
              ),
            ),
          ),
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
        if (isActiveFloor)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: dugGroundCapHeight,
            child: IgnorePointer(
              child: groundTint == null
                  ? Image.asset(
                      'assets/packs/mine-dug-ground-cap.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.none,
                    )
                  : ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        groundTint,
                        BlendMode.modulate,
                      ),
                      child: Image.asset(
                        'assets/packs/mine-dug-ground-cap.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
            ),
          ),
        if (_shouldLabelMineFloor(worldIndex, floorIndex))
          Positioned(
            left: 8,
            top: 6,
            child: Container(
              key: ValueKey('mine-floor-label-$worldIndex-$floorIndex'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xD90A2029),
                border: Border.all(color: MinePalette.border),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _mineFloorDepthLabel(worldIndex, floorIndex),
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        if (isDiscoveredFloor && !isActiveFloor)
          for (var worker = 0; worker < workerSlots.length; worker++)
            Positioned(
              left: workerSlots[worker].left,
              top: workerSlots[worker].top,
              child: IgnorePointer(
                child: Transform.flip(
                  flipX: workerSlots[worker].mirrored,
                  child: AnimatedCrewSprite(
                    key: ValueKey(
                      'mine-worker-$floorIndex-${workerSlots[worker].gallery}-${workerSlots[worker].crewIndex}',
                    ),
                    index: 0,
                    action: CrewAction.mining,
                    detailedMiningAnimation: true,
                    width: workerSlots[worker].width,
                    height: workerSlots[worker].height,
                    phaseOffset:
                        workerSlots[worker].crewIndex * .31 +
                        workerSlots[worker].gallery * .17,
                  ),
                ),
              ),
            ),
        if (isActiveFloor)
          Positioned(
            left: (width - rigWidth) / 2,
            // The visible drill tip meets the floor edge at the current depth.
            top: height - rigHeight * .985,
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ContinuousDrillRig(
                    key: ValueKey('deep-drill-rig-$floorIndex'),
                    width: rigWidth,
                    height: rigHeight,
                  ),
                  if (guideTarget == 'drill')
                    Positioned(
                      right: 0,
                      top: rigHeight * .44,
                      child: const _AdvisorTargetMarker(size: 28),
                    ),
                ],
              ),
            ),
          ),
        if (isDiscoveredFloor)
          for (var index = 0; index < deposits.length; index++)
            _OreNode(
              key: ValueKey('ore-node-${deposits[index].id}'),
              deposit: deposits[index],
              resource: ResourceCatalog.byId[deposits[index].resourceId]!,
              placement: oreNodes[index],
              showAdvisorMarker: guideTarget == 'ore',
              onTap: () {
                final deposit = deposits[index];
                final amountBefore =
                    controller.state.inventory[deposit.resourceId] ?? 0;
                if (!controller.mineDeposit(deposit.id)) return null;
                return (controller.state.inventory[deposit.resourceId] ?? 0) -
                    amountBefore;
              },
            ),
        if (isActiveFloor)
          Positioned(
            left: countdownLeft,
            top: countdownTop,
            child: IgnorePointer(
              child: _MineFloorCountdown(
                width: countdownWidth,
                secondsRemaining: secondsUntilNextFloor,
              ),
            ),
          ),
      ],
    );
  }
}

class _MineFloorCountdown extends StatelessWidget {
  const _MineFloorCountdown({
    required this.width,
    required this.secondsRemaining,
  });

  final double width;
  final int? secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final seconds = secondsRemaining;
    final minutes = seconds == null ? null : seconds ~/ 60;
    final remainingSeconds = seconds == null ? null : seconds % 60;
    final compact = width < 76;
    final timeLabel = seconds == null
        ? 'SON KAT'
        : '$minutes dk ${remainingSeconds!.toString().padLeft(2, '0')} sn';
    return Semantics(
      label: seconds == null
          ? 'Son kat'
          : 'Sıradaki kata kalan süre: $minutes dakika $remainingSeconds saniye',
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xF20A242E),
          border: Border.all(color: MinePalette.amber, width: 1),
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              seconds == null
                  ? 'SON DERİNLİK'
                  : compact
                  ? 'SONRAKİ KAT'
                  : 'SONRAKİ KATA',
              maxLines: 1,
              style: TextStyle(
                color: MinePalette.muted,
                fontSize: compact ? 5 : 7,
                fontWeight: FontWeight.w900,
                letterSpacing: .35,
              ),
            ),
            const SizedBox(height: 2),
            if (compact && seconds != null)
              Column(
                children: [
                  Text(
                    '$minutes dk',
                    maxLines: 1,
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${remainingSeconds.toString().padLeft(2, '0')} sn',
                    maxLines: 1,
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    seconds == null
                        ? Icons.flag_rounded
                        : Icons.hourglass_bottom_rounded,
                    size: 11,
                    color: MinePalette.amber,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        timeLabel,
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
          ],
        ),
      ),
    );
  }
}

class _AmbientAdvisorDrone extends StatefulWidget {
  const _AmbientAdvisorDrone({
    required this.controller,
    required this.width,
    required this.height,
    required this.narrow,
    required this.cameraController,
    required this.floorHeight,
    required this.floorCount,
    required this.manualCamera,
  });

  final GameController controller;
  final double width;
  final double height;
  final bool narrow;
  final ScrollController cameraController;
  final double floorHeight;
  final int floorCount;
  final bool manualCamera;

  @override
  State<_AmbientAdvisorDrone> createState() => _AmbientAdvisorDroneState();
}

class _AmbientAdvisorDroneState extends State<_AmbientAdvisorDrone>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  final Duration _offscreenDelay = const Duration(seconds: 3);
  Timer? _offscreenTimer;
  Timer? _speechTimer;
  Timer? _speechHideTimer;
  _DroneSpeech? _speech;
  int _speechCount = 0;
  AnimationController? _flightController;
  ScrollPosition? _scrollPosition;
  bool _initialized = false;
  bool _flying = false;
  int _floorIndex = 0;
  double _floorOffset = .42;
  double _leftFraction = .12;
  int _destinationFloor = 0;
  double _destinationFloorOffset = .42;
  double _destinationLeftFraction = .12;
  double _flightStartWorldY = 0;
  double _flightEndWorldY = 0;
  double _flightStartLeft = .12;
  double _flightEndLeft = .12;

  double get _size => widget.narrow ? 74 : 90;

  double get _cameraOffset => widget.cameraController.hasClients
      ? widget.cameraController.position.pixels
      : 0;

  double get _worldY => (_floorIndex + _floorOffset) * widget.floorHeight;

  bool get _isScrolling => _scrollPosition?.isScrollingNotifier.value ?? false;

  double _randomGalleryLeftFraction() {
    final size = _size;
    final shaftWidth = widget.narrow ? 86.0 : 112.0;
    final shaftLeft = (widget.width - shaftWidth) / 2;
    final leftLimit = math.max(0.0, shaftLeft - size - 10);
    final rightStart = shaftLeft + shaftWidth + 10;
    final rightLimit = math.max(0.0, widget.width - size);
    final rightSpace = math.max(0.0, rightLimit - rightStart);
    if (rightLimit <= 0 || (leftLimit <= 0 && rightSpace <= 0)) return .5;
    final useLeft = leftLimit > 0 && (rightSpace <= 0 || _random.nextBool());
    final left = useLeft
        ? _random.nextDouble() * leftLimit
        : rightStart + _random.nextDouble() * rightSpace;
    return (left / rightLimit).clamp(0.0, 1.0).toDouble();
  }

  @override
  void initState() {
    super.initState();
    widget.cameraController.addListener(_onCameraChanged);
    _flightController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1250),
          )
          ..addListener(_onFlightTick)
          ..addStatusListener(_onFlightStatusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _attachScrollPosition();
      _placeInitially();
    });
    _scheduleSpeech(const Duration(seconds: 18));
  }

  @override
  void didUpdateWidget(covariant _AmbientAdvisorDrone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraController != widget.cameraController) {
      oldWidget.cameraController.removeListener(_onCameraChanged);
      _scrollPosition?.isScrollingNotifier.removeListener(
        _onScrollActivityChanged,
      );
      _scrollPosition = null;
      widget.cameraController.addListener(_onCameraChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _attachScrollPosition();
        _checkVisibility();
      });
    } else if (oldWidget.floorHeight != widget.floorHeight ||
        oldWidget.height != widget.height ||
        oldWidget.floorCount != widget.floorCount ||
        oldWidget.manualCamera != widget.manualCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkVisibility();
      });
    }
  }

  void _attachScrollPosition() {
    _scrollPosition?.isScrollingNotifier.removeListener(
      _onScrollActivityChanged,
    );
    _scrollPosition = widget.cameraController.hasClients
        ? widget.cameraController.position
        : null;
    _scrollPosition?.isScrollingNotifier.addListener(_onScrollActivityChanged);
  }

  void _placeInitially() {
    final spot = _randomVisibleSpot();
    setState(() {
      _floorIndex = spot.$1;
      _floorOffset = spot.$2;
      _leftFraction = spot.$3;
      _initialized = true;
    });
    _checkVisibility();
  }

  (int, double, double) _randomVisibleSpot() {
    final offset = _cameraOffset;
    final size = _size;
    final first = (offset / widget.floorHeight)
        .floor()
        .clamp(0, math.max(0, widget.floorCount - 1))
        .toInt();
    final last = ((offset + widget.height - 1) / widget.floorHeight)
        .floor()
        .clamp(first, math.max(first, widget.floorCount - 1))
        .toInt();
    final visibleFloors = <(int, double, double)>[];
    for (var floor = first; floor <= last; floor++) {
      final floorTop = floor * widget.floorHeight - offset;
      final minimumTop = math.max(0.0, floorTop);
      final maximumTop = math.min(
        widget.height - size,
        floorTop + widget.floorHeight - size,
      );
      if (maximumTop < minimumTop) continue;
      final screenTop =
          minimumTop + _random.nextDouble() * (maximumTop - minimumTop);
      final withinFloor = ((offset + screenTop) / widget.floorHeight - floor)
          .clamp(0.04, .96)
          .toDouble();
      visibleFloors.add((floor, withinFloor, _randomGalleryLeftFraction()));
    }
    if (visibleFloors.isEmpty) {
      final screenTop = (widget.height - size) * .45;
      final worldY = offset + screenTop;
      final floor = (worldY / widget.floorHeight)
          .floor()
          .clamp(0, math.max(0, widget.floorCount - 1))
          .toInt();
      return (
        floor,
        (worldY / widget.floorHeight - floor).clamp(0.04, .96).toDouble(),
        _randomGalleryLeftFraction(),
      );
    }
    return visibleFloors[_random.nextInt(visibleFloors.length)];
  }

  void _onCameraChanged() {
    if (!mounted) return;
    setState(() {});
    _checkVisibility();
  }

  void _onFlightTick() {
    if (mounted) setState(() {});
  }

  void _onScrollActivityChanged() {
    if (!mounted) return;
    if (_isScrolling && widget.manualCamera) {
      _cancelOffscreenTimer();
    } else {
      _checkVisibility();
    }
  }

  bool get _worldPositionVisible {
    final top = _worldY - _cameraOffset;
    return top + _size > 0 && top < widget.height;
  }

  void _checkVisibility() {
    if (!_initialized || _flying) return;
    if (_worldPositionVisible || (_isScrolling && widget.manualCamera)) {
      _cancelOffscreenTimer();
      return;
    }
    if (_offscreenTimer != null) return;
    _offscreenTimer = Timer(_offscreenDelay, _flyBackIntoView);
  }

  void _cancelOffscreenTimer() {
    _offscreenTimer?.cancel();
    _offscreenTimer = null;
  }

  void _flyBackIntoView() {
    _offscreenTimer = null;
    if (!mounted ||
        !_initialized ||
        _flying ||
        (_isScrolling && widget.manualCamera)) {
      return;
    }
    if (_worldPositionVisible) return;

    final offset = _cameraOffset;
    final oldTop = _worldY - offset;
    final enteringFromTop = oldTop + _size <= 0;
    final destination = _randomVisibleSpot();
    final destinationWorldY =
        (destination.$1 + destination.$2) * widget.floorHeight;
    setState(() {
      _destinationFloor = destination.$1;
      _destinationFloorOffset = destination.$2;
      _destinationLeftFraction = destination.$3;
      _flightStartWorldY = enteringFromTop
          ? offset - _size - 6
          : offset + widget.height + 6;
      _flightEndWorldY = destinationWorldY;
      _flightStartLeft = _leftFraction;
      _flightEndLeft = destination.$3;
      _flying = true;
    });
    _flightController?.forward(from: 0);
  }

  void _onFlightStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_flying || !mounted) return;
    setState(() {
      _floorIndex = _destinationFloor;
      _floorOffset = _destinationFloorOffset;
      _leftFraction = _destinationLeftFraction;
      _flying = false;
    });
    _checkVisibility();
  }

  void _scheduleSpeech(Duration delay) {
    _speechTimer?.cancel();
    _speechTimer = Timer(delay, _showSpeech);
  }

  void _showSpeech() {
    _speechTimer = null;
    if (!mounted) return;
    if (!_initialized ||
        !_worldPositionVisible ||
        (_isScrolling && widget.manualCamera)) {
      _scheduleSpeech(const Duration(seconds: 10));
      return;
    }

    final isPlayerTip = _speechCount.isEven;
    final message = isPlayerTip
        ? _dronePlayerHint(widget.controller, _speechCount ~/ 2)
        : _droneMotivation(_speechCount ~/ 2);
    setState(() {
      _speech = _DroneSpeech(message: message, isPlayerTip: isPlayerTip);
      _speechCount++;
    });
    _speechHideTimer?.cancel();
    _speechHideTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _speech = null);
    });
    _scheduleSpeech(Duration(seconds: 42 + _random.nextInt(14)));
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    final progress = _flightController?.value ?? 0;
    final worldY = _flying
        ? _flightStartWorldY +
              (_flightEndWorldY - _flightStartWorldY) * progress
        : _worldY;
    final leftFraction = _flying
        ? _flightStartLeft + (_flightEndLeft - _flightStartLeft) * progress
        : _leftFraction;
    final left = ((widget.width - size) * leftFraction)
        .clamp(0.0, math.max(0.0, widget.width - size))
        .toDouble();
    final screenTop = worldY - _cameraOffset;
    final speechWidth = math.min(
      widget.width - 16,
      widget.narrow ? 218.0 : 268.0,
    );
    final speechHeight = 84.0;
    final speechLeft = (left + size / 2 - speechWidth / 2)
        .clamp(8.0, math.max(8.0, widget.width - speechWidth - 8))
        .toDouble();
    final tailLeft = (left + size / 2 - speechLeft - 8)
        .clamp(16.0, math.max(16.0, speechWidth - 16))
        .toDouble();
    final speechAboveDrone = screenTop >= speechHeight + 9;
    final speechTop = speechAboveDrone
        ? math.max(0.0, screenTop - speechHeight - 9)
        : screenTop + size;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: left,
          top: worldY - _cameraOffset,
          width: size,
          height: size,
          child: AnimatedCrewSprite(
            index: 3,
            action: CrewAction.scanning,
            width: size,
            height: size,
            phaseOffset: .29,
            advisorDroneAnimation: true,
          ),
        ),
        if (_speech != null)
          Positioned(
            left: speechLeft,
            top: speechTop,
            width: speechWidth,
            height: speechHeight + 9,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _DroneSpeechBubble(
                  key: ValueKey('${_speech!.isPlayerTip}:${_speech!.message}'),
                  speech: _speech!,
                  width: speechWidth,
                  height: speechHeight,
                  tailLeft: tailLeft,
                  tailOnTop: !speechAboveDrone,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _cancelOffscreenTimer();
    _speechTimer?.cancel();
    _speechHideTimer?.cancel();
    widget.cameraController.removeListener(_onCameraChanged);
    _scrollPosition?.isScrollingNotifier.removeListener(
      _onScrollActivityChanged,
    );
    _flightController?.dispose();
    super.dispose();
  }
}

class _DroneSpeech {
  const _DroneSpeech({required this.message, required this.isPlayerTip});

  final String message;
  final bool isPlayerTip;
}

class _DroneSpeechBubble extends StatelessWidget {
  const _DroneSpeechBubble({
    super.key,
    required this.speech,
    required this.width,
    required this.height,
    required this.tailLeft,
    required this.tailOnTop,
  });

  final _DroneSpeech speech;
  final double width;
  final double height;
  final double tailLeft;
  final bool tailOnTop;

  @override
  Widget build(BuildContext context) {
    final accent = speech.isPlayerTip ? MinePalette.cyan : MinePalette.amber;
    return SizedBox(
      width: width,
      height: height + 9,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(top: tailOnTop ? 9 : 0),
            width: width,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xF20A2028),
              border: Border.all(color: accent, width: 1.3),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      speech.isPlayerTip
                          ? Icons.lightbulb_rounded
                          : Icons.groups_rounded,
                      size: 12,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      speech.isPlayerTip ? 'DRON • İPUCU' : 'DRON • EKİBE',
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .35,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Text(
                    speech.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 10,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: tailLeft,
            top: tailOnTop ? 0 : height - 1,
            child: CustomPaint(
              size: const Size(16, 9),
              painter: _DroneSpeechTailPainter(
                fill: const Color(0xF20A2028),
                border: accent,
                pointsUp: tailOnTop,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DroneSpeechTailPainter extends CustomPainter {
  const _DroneSpeechTailPainter({
    required this.fill,
    required this.border,
    required this.pointsUp,
  });

  final Color fill;
  final Color border;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _DroneSpeechTailPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.border != border ||
      oldDelegate.pointsUp != pointsUp;
}

String _droneMotivation(int index) {
  const lines = [
    'Güzel tempo ekip! Her vuruş bizi yeni bir katmana yaklaştırıyor.',
    'Kasklar sağlam, ekip hazır. Bu vardiyada rekoru kıracağız!',
    'Madenciler, ritmi koruyun; en iyi damar biraz daha derinde olabilir.',
    'Harika çalışıyorsunuz! Birlikte her engeli aşarız.',
    'Dayan ekip! Biraz daha kazarsak yeni keşifler bizi bekliyor.',
  ];
  return lines[index % lines.length];
}

String _dronePlayerHint(GameController controller, int index) {
  final state = controller.state;
  if (state.cargoFull || state.cargoRatio >= .88) {
    return state.autoSellEnabled
        ? 'Ambar doluyor. Otomatik satış eşiğini düşür ya da depodan cevheri sat.'
        : 'Ambar doluyor. Depodan cevheri sat; boşalan yer kazıyı sürdürür.';
  }
  if (controller.unclaimedQuestRewardCount > 0) {
    return 'Görev düğmesindeki hazır ödülleri al; kasayı geliştirmelere yatır.';
  }
  if (state.canOpenBuilding('workshop') && state.crewCount > 0) {
    final drillCost = GameEngine.upgradeCost(state, 'drill');
    if (drillCost > 0 &&
        state.canAfford(drillCost) &&
        GameEngine.upgradeMaterialDeficits(state, 'drill').isEmpty) {
      return 'Atölye’de Sondaj Ucu yükseltmesi hazır; derinlik ilerleme hızını artırır.';
    }
    final assembly = _availableDrillAssemblyUpgrade(state);
    if (assembly != null) {
      return 'Montajda ${assembly.name} geliştirilebilir; artan sondaj gücü kazıyı hızlandırır.';
    }
    if (controller.currentQuest.kind == QuestKind.assemblyUpgrade) {
      return 'Montaj görevini ilerlet: Atölye’de ucu, fanı veya motoru geliştir.';
    }
    if (state.activeMinerCount < 10 &&
        state.canAfford(GameEngine.minerCost(state))) {
      return 'Kasan yeterli; Atölye’den madenci işe alıp cevher ekibini büyütebilirsin.';
    }
  }
  if (state.pressure >= 70 && state.unlockedBuildings.contains('elevator')) {
    return 'Basınç %70’i aşınca sondaj yavaşlar. Kuyu Asansörü’nde basıncı boşalt.';
  }
  if (state.energy >= 25 &&
      state.unlockedBuildings.contains('reactor') &&
      !state.activeBuffIds.contains('buff_overdrive')) {
    return '25 reaktör enerjin var: Güç Darbesi sondajı 2 dakika hızlandırır.';
  }
  if (!state.canOpenBuilding('workshop')) {
    return 'Görev şeridindeki adımları izle; Atölye açılınca sondaj geliştirmeleri hız kazandırır.';
  }
  const generalHints = [
    'İlerleme yavaşladı mı? Sondaj Ucu derinlik hızını, montaj parçaları toplam gücü artırır.',
    'Montajda uç, fan ve motoru yükseltmek toplam sondaj gücünü artırır.',
    'Görevleri tamamlayıp kasayı sondaj geliştirmelerine yatırmak daha hızlı derinleşmeni sağlar.',
  ];
  return generalHints[index % generalHints.length];
}

DrillAssemblyDefinition? _availableDrillAssemblyUpgrade(GameState state) {
  if (state.crewCount <= 0) return null;
  for (final component in DrillAssemblyCatalog.all) {
    final nextLevel = GameEngine.drillAssemblyLevel(state, component.id) + 1;
    if (nextLevel > DrillAssemblyCatalog.maxLevel ||
        state.deepestMeters <
            DrillAssemblyCatalog.requiredDepthFor(nextLevel)) {
      continue;
    }
    final blueprintId = DrillAssemblyCatalog.blueprintIdFor(
      component.id,
      nextLevel,
    );
    if (blueprintId != null && !state.knownBlueprintIds.contains(blueprintId)) {
      continue;
    }
    final requiredBuilding = DrillAssemblyCatalog.requiredBuildingFor(
      nextLevel,
    );
    if (requiredBuilding != null &&
        !state.unlockedBuildings.contains(requiredBuilding)) {
      continue;
    }
    final cost = GameEngine.drillAssemblyUpgradeCost(state, component.id);
    if (!state.canAfford(cost) ||
        GameEngine.drillAssemblyMaterialDeficits(
          state,
          component.id,
        ).isNotEmpty) {
      continue;
    }
    return component;
  }
  return null;
}

class _MineElevatorMotion extends StatefulWidget {
  const _MineElevatorMotion({
    required this.width,
    required this.height,
    required this.worldExtent,
    required this.floorHeight,
    required this.turnaroundFloorIndex,
    required this.cameraController,
  });

  final double width;
  final double height;
  final double worldExtent;
  final double floorHeight;
  final int turnaroundFloorIndex;
  final ScrollController cameraController;

  @override
  State<_MineElevatorMotion> createState() => _MineElevatorMotionState();
}

class _MineElevatorMotionState extends State<_MineElevatorMotion>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastElapsed;
  late double _worldTop;
  bool _descending = true;

  @override
  void initState() {
    super.initState();
    _worldTop = -_carHeight;
    _ticker = createTicker(_advanceElevator)..start();
  }

  double get _carHeight => math.min(widget.width * 2 / 3, widget.height);

  double get _topEndpoint => -_carHeight;

  double get _bottomEndpoint {
    final floorIndex = widget.turnaroundFloorIndex.clamp(
      0,
      math.max(0, (widget.worldExtent / widget.floorHeight).ceil() - 1),
    );
    final turnaroundTop =
        (floorIndex + .5) * widget.floorHeight - _carHeight / 2;
    return turnaroundTop
        .clamp(0.0, math.max(0.0, widget.worldExtent - _carHeight))
        .toDouble();
  }

  double get _pixelsPerSecond => math.max(1.0, widget.height) / 3.2;

  void _advanceElevator(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;

    final distance =
        (elapsed - previous).inMicroseconds / 1000000.0 * _pixelsPerSecond;
    if (distance <= 0) return;

    final top = _topEndpoint;
    final bottom = _bottomEndpoint;
    if (_worldTop < top) {
      _worldTop = top;
      _descending = true;
    } else if (_worldTop > bottom) {
      _worldTop = bottom;
      _descending = false;
    }

    final legLength = math.max(1.0, bottom - top);
    final roundTrip = legLength * 2;
    final offset = _worldTop - top;
    final phase = _descending ? offset : roundTrip - offset;
    final nextPhase = (phase + distance) % roundTrip;
    if (nextPhase <= legLength) {
      _worldTop = top + nextPhase;
      _descending = nextPhase < legLength;
    } else {
      _worldTop = bottom - (nextPhase - legLength);
      _descending = false;
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _MineElevatorMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worldExtent != widget.worldExtent ||
        oldWidget.height != widget.height ||
        oldWidget.floorHeight != widget.floorHeight ||
        oldWidget.turnaroundFloorIndex != widget.turnaroundFloorIndex ||
        oldWidget.width != widget.width) {
      if (_worldTop < _topEndpoint) {
        _worldTop = _topEndpoint;
        _descending = true;
      } else if (_worldTop > _bottomEndpoint) {
        _worldTop = _bottomEndpoint;
        _descending = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.cameraController,
    builder: (context, _) {
      final carHeight = _carHeight;
      final cameraTop = widget.cameraController.hasClients
          ? widget.cameraController.position.pixels
          : 0.0;
      final top = _worldTop - cameraTop;
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: 0,
            top: top,
            width: widget.width,
            height: carHeight,
            child: Image.asset(
              'assets/packs/mine-elevator-car.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        ],
      );
    },
  );

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _MineWorkerPlacement {
  const _MineWorkerPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.crewIndex,
    required this.gallery,
    required this.mirrored,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final int crewIndex;
  final int gallery;
  final bool mirrored;
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
  final workerCount = math.min(crewCount, 10);
  final baseWorkerWidth = (narrow ? 46.0 : 60.0) * .7;
  final rightCount = workerCount <= 3
      ? workerCount
      : workerCount <= 6
      ? 3
      : (workerCount + 1) ~/ 2;
  final leftCount = workerCount - rightCount;
  final maxSideCount = math.max(rightCount, leftCount);
  final edgeInset = narrow ? 0.0 : 8.0;
  final availableSideWidth = (width - shaftWidth) / 2 - edgeInset - workerGap;
  final fittedWorkerWidth = maxSideCount <= 0
      ? baseWorkerWidth
      : (availableSideWidth - workerGap * (maxSideCount - 1)) / maxSideCount;
  final workerWidth = math
      .min(baseWorkerWidth, fittedWorkerWidth)
      .clamp(12.0, baseWorkerWidth);
  final workerHeight =
      (narrow ? 62.0 : 80.0) * .7 * workerWidth / baseWorkerWidth;
  final galleryFloors = _galleryHeightRatios
      .map((ratio) => height * ratio)
      .toList(growable: false);
  final placements = <_MineWorkerPlacement>[];

  for (var gallery = 0; gallery < galleryFloors.length; gallery++) {
    for (var crewIndex = 0; crewIndex < workerCount; crewIndex++) {
      final mirrored = crewIndex >= rightCount;
      final sideIndex = mirrored ? crewIndex - rightCount : crewIndex;
      final sideCount = mirrored ? leftCount : rightCount;
      final firstLeft = mirrored ? edgeInset : width - edgeInset - workerWidth;
      final firstInwardDistance = mirrored
          ? shaftLeft - workerGap - firstLeft - workerWidth
          : firstLeft - shaftLeft - shaftWidth - workerGap;
      final stride = sideCount <= 1
          ? workerWidth + workerGap
          : math.min(
              workerWidth + workerGap,
              math.max(0.0, firstInwardDistance) / (sideCount - 1),
            );
      final left = mirrored
          ? firstLeft + sideIndex * stride
          : firstLeft - sideIndex * stride;
      final floorY = galleryFloors[gallery];
      placements.add(
        _MineWorkerPlacement(
          left: left,
          top: floorY - 8 - workerHeight,
          width: workerWidth,
          height: workerHeight,
          crewIndex: crewIndex,
          gallery: gallery,
          mirrored: mirrored,
        ),
      );
    }
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

class _OreNode extends StatefulWidget {
  const _OreNode({
    super.key,
    required this.deposit,
    required this.resource,
    required this.placement,
    required this.showAdvisorMarker,
    required this.onTap,
  });

  final OreDepositState deposit;
  final ResourceDefinition resource;
  final _OreNodePlacement placement;
  final bool showAdvisorMarker;
  final int? Function() onTap;

  @override
  State<_OreNode> createState() => _OreNodeState();
}

class _OreNodeState extends State<_OreNode> {
  static const _popupDuration = Duration(milliseconds: 1500);

  final List<_OreGainPopupHandle> _activePopups = [];
  int _popupSequence = 0;

  @override
  void dispose() {
    for (final popup in _activePopups.toList()) {
      popup.remove();
    }
    _activePopups.clear();
    super.dispose();
  }

  void _handleTap() {
    final amount = widget.onTap();
    if (amount != null && amount > 0) _showGainPopup(amount);
  }

  void _showGainPopup(int amount) {
    final nodeObject = context.findRenderObject();
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayObject = overlay.context.findRenderObject();
    if (nodeObject is! RenderBox || overlayObject is! RenderBox) return;
    final anchor = nodeObject.localToGlobal(
      Offset(nodeObject.size.width / 2, nodeObject.size.height * .44),
      ancestor: overlayObject,
    );
    while (_activePopups.length >= 2) {
      _activePopups.removeAt(0).remove();
    }

    final sequence = _popupSequence++;
    final label = '$amount ${widget.resource.name.toLowerCase()}';
    final color = Color(widget.resource.colorHex);
    final maxLeft = math.max(4.0, overlayObject.size.width - 132);
    final left = (anchor.dx - 50 + (sequence.isEven ? -14 : 14))
        .clamp(4.0, maxLeft)
        .toDouble();
    final maxTop = math.max(4.0, overlayObject.size.height - 36);
    final top = (anchor.dy - 40 - (sequence.isEven ? 0 : 13))
        .clamp(4.0, maxTop)
        .toDouble();
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            duration: _popupDuration,
            tween: Tween(begin: 0, end: 1),
            builder: (context, progress, child) => Opacity(
              opacity: (1 - progress).clamp(0.0, 1.0).toDouble(),
              child: Transform.translate(
                offset: Offset(0, -18 * progress),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xE60A2029),
                border: Border.all(color: color, width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final popup = _OreGainPopupHandle(entry);
    _activePopups.add(popup);
    overlay.insert(entry);
    popup.timer = Timer(_popupDuration, () {
      _activePopups.remove(popup);
      popup.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.placement.left,
      top: widget.placement.top,
      child: SizedBox(
        width: widget.placement.width,
        height: widget.placement.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Semantics(
              button: true,
              label: '${widget.resource.name} cevher taşı',
              hint: 'Kırmak için dokun.',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: widget.placement.iconWidth,
                    height: widget.placement.iconHeight,
                    child: AtlasSprite(
                      asset: 'resources-treasure-sheet.png',
                      index: widget.resource.iconIndex,
                      columns: 4,
                      rows: 4,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      sourceCrop: _oreSpriteCrop(widget.resource.iconIndex),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showAdvisorMarker)
              Positioned(
                right: -7,
                top: -10,
                child: const _AdvisorTargetMarker(size: 27),
              ),
          ],
        ),
      ),
    );
  }
}

class _OreGainPopupHandle {
  _OreGainPopupHandle(this.entry);

  final OverlayEntry entry;
  Timer? timer;
  bool _removed = false;

  void remove() {
    if (_removed) return;
    _removed = true;
    timer?.cancel();
    entry.remove();
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
  final nodeWidth = math.min(
    narrow ? 70.0 : 108.0,
    math.max(44.0, (shaftLeft - wallInset - 4) / 2),
  );
  final nodeHeight = math.min(
    narrow ? 76.0 : 90.0,
    math.max(48.0, height * .75),
  );
  final iconWidth = math.min(nodeWidth - 4, narrow ? 84.0 : 104.0) * .8;
  final iconHeight = (narrow ? 68.0 : 82.0) * .8;
  final floors = _galleryHeightRatios
      .map((ratio) => height * ratio)
      .toList(growable: false);
  final placements = <_OreNodePlacement>[];

  for (var index = 0; index < deposits.length; index++) {
    final side = deposits.length == 1 ? deposits[index].side : index % 2;
    final lane = deposits.length == 1 ? 0 : index ~/ 2;
    final laneOffset = lane * (nodeWidth + 4);
    final floorY = floors.single;
    final floorSurfaceY = floorY - 8;
    placements.add(
      _OreNodePlacement(
        left: side == 0
            ? wallInset + laneOffset
            : width - wallInset - nodeWidth - laneOffset,
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
      final state = controller.state;
      final guideTarget = AdvisorGuideCatalog.currentFor(state)?.target;
      final compact = constraints.maxWidth < 690;
      final veryNarrow = constraints.maxWidth < 450;
      final shortcuts = veryNarrow
          ? [
              (Icons.engineering_rounded, 'EKİP', 'workshop'),
              (Icons.inventory_2_rounded, 'AMBAR', 'warehouse'),
              (Icons.task_alt_rounded, 'GÖREV', 'quests'),
              (Icons.map_rounded, 'SEFER', 'expedition'),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var index = 0; index < shortcuts.length; index++) ...[
              SizedBox(
                width: actionWidth,
                child: _SquareAction(
                  icon: shortcuts[index].$1,
                  label: shortcuts[index].$2,
                  enabled: state.canOpenBuilding(shortcuts[index].$3),
                  highlighted: guideTarget == shortcuts[index].$3,
                  onTap: () => onUtility(shortcuts[index].$3),
                ),
              ),
              SizedBox(width: gap),
            ],
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
    required this.enabled,
    this.highlighted = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: enabled,
    enabled: enabled,
    label: label,
    child: SizedBox(
      height: 56,
      child: Material(
        color: const Color(0xFF102E3A),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: highlighted
                        ? BoxDecoration(
                            border: Border.all(
                              color: MinePalette.amber,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x99FFBE3E),
                                blurRadius: 8,
                              ),
                            ],
                          )
                        : null,
                    child: Icon(
                      enabled ? icon : Icons.lock_outline_rounded,
                      size: 20,
                      color: highlighted
                          ? MinePalette.amber
                          : enabled
                          ? MinePalette.cyan
                          : MinePalette.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: enabled
                              ? MinePalette.cream
                              : MinePalette.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (highlighted)
                const Positioned(
                  right: -2,
                  top: -7,
                  child: _AdvisorTargetMarker(size: 25),
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

class _ResonanceSequenceHint extends StatelessWidget {
  const _ResonanceSequenceHint({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final pattern = state.resonancePattern;
    final targetName =
        ResourceCatalog.byId[GameEngine.currentResonanceTarget(state)]?.name ??
        'Kömür';
    final sequence = pattern
        .map((id) => ResourceCatalog.byId[id]?.name ?? id)
        .join('  ›  ');
    final length = math.max(1, pattern.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE90A242E),
        border: Border.all(color: MinePalette.amber, width: 1.2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
      ),
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, color: MinePalette.amber, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'DAMAR AKORDU  ${state.resonanceProgress + 1}/$length  •  $sequence',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MinePalette.cream,
                fontSize: 9,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Sıradaki: $targetName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MinePalette.teal,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
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
      final spans = <(double, double)>[
        (0, x - 3),
        (x + shaftWidth + 3, size.width),
      ];
      for (final (start, end) in spans) {
        for (final supportRatio in [.08, .92]) {
          final supportX = start + (end - start) * supportRatio;
          final supportTop = Rect.fromLTRB(
            supportX - 5,
            0,
            supportX + 5,
            math.max(0.0, y - 7),
          );
          final supportBottom = Rect.fromLTRB(
            supportX - 5,
            math.min(size.height, y + 10),
            supportX + 5,
            size.height,
          );
          for (final support in [supportTop, supportBottom]) {
            if (support.height <= 0) continue;
            canvas.drawRect(support, Paint()..color = const Color(0xFF30241D));
            canvas.drawRect(
              Rect.fromLTWH(support.left + 4, support.top, 3, support.height),
              Paint()..color = const Color(0xFF785238),
            );
          }
        }

        final beamBottom = level == _galleryHeightRatios.length - 1
            ? size.height
            : y + 10;
        final beam = Rect.fromLTRB(start, y - 7, end, beamBottom);
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

bool _shouldLabelMineFloor(int worldIndex, int floorIndex) {
  final depthAtFloorEnd =
      GameState.worldEntryDepths[worldIndex] + (floorIndex + 1) * 1000;
  return depthAtFloorEnd == 1000 || depthAtFloorEnd % 5000 == 0;
}

String _mineFloorDepthLabel(int worldIndex, int floorIndex) => _depthLabel(
  (GameState.worldEntryDepths[worldIndex] + (floorIndex + 1) * 1000).round(),
);

String _number(num value) {
  final raw = value.round().toString();
  final result = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) result.write('.');
    result.write(raw[i]);
  }
  return result.toString();
}

String _formatCoins(MrMineBigNumber coins) {
  if (coins.exponent >= 15) {
    return coins.toScientificString();
  }
  final raw = coins.toString();
  final result = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) result.write('.');
    result.write(raw[i]);
  }
  return result.toString();
}

String _goalRequirementLine(
  GameController controller, {
  AdvisorGuideDefinition? guide,
  required QuestDefinition quest,
}) {
  final state = controller.state;
  if (guide != null) {
    if (guide.isTutorial) {
      switch (quest.id) {
        case 0:
          final veins = state.oreDeposits.values
              .where((deposit) => !deposit.depleted)
              .length;
          return '$veins kömür damarı hazır • her damar 5 vuruşta tükenir.';
        case 1:
          return 'Satış hedefi: 40 kasa • toplam satış: ${_formatCoins(state.totalSold)}.';
        case 2:
          final cost = GameEngine.minerCost(state);
          return 'Madenci: ${_formatCoins(MrMineBigNumber.fromNum(cost))} kasa • kasan: ${_formatCoins(state.coins)}.';
        case 3:
          final cost = GameEngine.upgradeCost(state, 'drill');
          final requirements = GameEngine.upgradeMaterialRequirements(
            state,
            'drill',
          );
          final recipe = requirements.entries
              .map(
                (entry) =>
                    '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
              )
              .join(' + ');
          final materials = recipe.isEmpty ? '' : ' + $recipe';
          return 'Sondaj ucu: ${_formatCoins(MrMineBigNumber.fromNum(cost))} kasa$materials.';
        case 4:
          final remaining = (10000 - state.deepestMeters.floor()).clamp(
            0,
            10000,
          );
          return remaining == 0
              ? '10 km katı açıldı • görevi tamamlayıp ödülünü al.'
              : 'Matkap otomatik ilerliyor • $remaining m kaldı • hedef 10 km.';
      }
    }
    if (guide.requiredDepthMeters > 0) {
      return 'Kilometre taşı: ${_depthLabel(guide.requiredDepthMeters)} • açmak için AÇ düğmesine dokun.';
    }
    return 'Açılan sistemi görmek için AÇ düğmesine dokun.';
  }

  final progress = controller.currentQuestProgress;
  final remaining = math.max(0, quest.target - progress);
  final resonanceTargetName =
      ResourceCatalog.byId[GameEngine.currentResonanceTarget(state)]?.name ??
      'Kömür';
  if (controller.currentQuestReady) return 'Hedef tamamlandı • ödülünü al.';
  return switch (quest.kind) {
    QuestKind.mine =>
      '$remaining cevher daha çıkar • kuyudaki damarları tıkla.',
    QuestKind.depth =>
      quest.absoluteDepth
          ? 'Son hedef: ${_depthLabel(quest.target)} • matkap otomatik ilerliyor.'
          : '$remaining m kaldı • matkap otomatik ilerliyor.',
    QuestKind.hire =>
      'Sıradaki madenci: ${_formatCoins(MrMineBigNumber.fromNum(GameEngine.minerCost(state)))} kasa • kasan: ${_formatCoins(state.coins)}.',
    QuestKind.sell =>
      'Satış hedefi ${_number(quest.target)} kasa • toplam satış: ${_formatCoins(state.totalSold)}.',
    QuestKind.upgrade =>
      'Atölyede sondaj ucu, dökümhane veya muhafız silahını geliştir • toplam seviye ${controller.currentQuestProgress}/${quest.target}.',
    QuestKind.assemblyUpgrade =>
      'Atölyeyi aç → Sondaj Montajı bölümünde sondaj ucu, fan veya motor kartındaki şartları tamamlayıp geliştir düğmesine bas • ${controller.currentQuestProgress}/${quest.target}.',
    QuestKind.chest =>
      'Bulunan sandık: ${state.totalChestsFound} • Ticaret panelinde bir sandık aç.',
    QuestKind.cave => 'Sefer Garajında bir rota başlat ve dronu geri getir.',
    QuestKind.relic =>
      'Araştırmada kalıntı kazısı başlat ve buluntuyu teslim al.',
    QuestKind.boss => 'Cephanelikte zayıf noktayı açıp muhafıza saldır.',
    QuestKind.resonance =>
      'Araştırma’da DİZİYİ TARA’ya bas; kuyuya dönüp sıradaki $resonanceTargetName damarına dokun (${state.resonanceProgress + 1}/${math.max(1, state.resonancePattern.length)}).',
  };
}

String? _questTargetPanel(QuestDefinition quest) => switch (quest.kind) {
  QuestKind.hire ||
  QuestKind.upgrade ||
  QuestKind.assemblyUpgrade => 'workshop',
  QuestKind.sell => 'warehouse',
  QuestKind.chest => 'trade',
  QuestKind.cave => 'expedition',
  QuestKind.relic => 'research',
  QuestKind.boss => 'boss',
  QuestKind.mine || QuestKind.depth => null,
  QuestKind.resonance => 'research',
};

String _duration(int seconds) {
  final safe = math.max(0, seconds);
  final minutes = safe ~/ 60;
  final remainingSeconds = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}
