import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';
import '../../domain/models/upgrade_definition.dart';
import '../../domain/models/resource_definition.dart';
import '../../domain/models/mr_mine_big_number.dart';
import '../../domain/simulation/game_engine.dart';

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF0C2834),
      border: Border.all(color: MinePalette.border, width: 1.2),
      borderRadius: BorderRadius.circular(9),
      boxShadow: const [
        BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 39,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF163B49), Color(0xFF0B222D)],
            ),
            border: Border(bottom: BorderSide(color: MinePalette.border)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: MinePalette.amber),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(9), child: child),
      ],
    ),
  );
}

class UpgradeRow extends StatelessWidget {
  const UpgradeRow({
    super.key,
    required this.controller,
    required this.track,
    this.compact = false,
    this.highlighted = false,
  });

  final GameController controller;
  final String track;
  final bool compact;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final level = state.upgradeLevel(track);
    final maxLevel = track == 'reactor'
        ? 5
        : UpgradeCatalog.byId[track]?.maxLevel ?? 100;
    final cost = GameEngine.upgradeCost(state, track);
    final costBig = MrMineBigNumber.fromNum(cost);
    final missing = state.debugMoneyEnabled || state.canAfford(cost)
        ? MrMineBigNumber.zero
        : costBig.subtract(state.coins);
    final materialRequirements = GameEngine.upgradeMaterialRequirements(
      state,
      track,
    );
    final materialDeficits = GameEngine.upgradeMaterialDeficits(state, track);
    final materialText = materialRequirements.entries
        .map((entry) {
          final name = ResourceCatalog.byId[entry.key]?.name ?? entry.key;
          final available = (state.amount(entry.key) - state.reserve(entry.key))
              .clamp(0, 1000000000);
          return '$name $available/${entry.value}';
        })
        .join(' • ');
    final tutorialLocked =
        state.guidedProgression &&
        !state.debugModeEnabled &&
        !state.initialTutorialComplete &&
        state.tutorialStep < 3;
    final canBuy =
        !tutorialLocked &&
        level < maxLevel &&
        cost > 0 &&
        state.canAfford(cost) &&
        materialDeficits.isEmpty &&
        (track != 'drill' || state.crewCount > 0) &&
        (track != 'reactor' || state.unlockedBuildings.contains('reactor'));
    final (name, icon) = switch (track) {
      'drill' => ('Sondaj ucu', Icons.hardware_rounded),
      'workers' => ('İşçi eğitimi', Icons.engineering_rounded),
      'lift' => ('Kuyu asansörü', Icons.elevator_rounded),
      'warehouse' => ('Kargo ambarı', Icons.inventory_2_rounded),
      'scanner' => ('Mineral tarayıcı', Icons.radar_rounded),
      'foundry' => ('Dökümhane', Icons.local_fire_department_rounded),
      'weapon' => ('Muhafız silahı', Icons.flash_on_rounded),
      'reactor' => ('Çekirdek reaktörü', Icons.bolt_rounded),
      _ => (track, Icons.upgrade_rounded),
    };
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 5 : 8),
      padding: EdgeInsets.all(compact ? 5 : 9),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF2B3029) : const Color(0xFF102F3B),
        border: Border.all(
          color: highlighted ? MinePalette.amber : const Color(0xFF294B55),
          width: highlighted ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(7),
        boxShadow: highlighted
            ? const [BoxShadow(color: Color(0x66FFBE3E), blurRadius: 9)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 33 : 43,
            height: compact ? 33 : 43,
            decoration: BoxDecoration(
              color: const Color(0xFF071922),
              border: Border.all(color: MinePalette.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: compact ? 18 : 22, color: MinePalette.cyan),
          ),
          SizedBox(width: compact ? 6 : 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MinePalette.cream,
                    fontSize: compact ? 9 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (level / maxLevel).clamp(0, 1).toDouble(),
                          minHeight: compact ? 6 : 8,
                          backgroundColor: const Color(0xFF06141C),
                          color: MinePalette.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Lv $level/$maxLevel',
                      style: TextStyle(
                        color: MinePalette.muted,
                        fontSize: compact ? 8 : 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    level >= maxLevel
                        ? 'Bu yükseltme ailesinin tüm şemaları açıldı.'
                        : [
                            UpgradeCatalog.byId[track]?.effect ??
                                'Etkisi gelişir.',
                            'Sonraki şema: $cost kasa',
                            if (track == 'drill' && state.crewCount == 0)
                              'Önce ilk madenciyi işe al',
                            if (materialText.isNotEmpty)
                              'Cevher: $materialText',
                            if (missing.greaterThan(MrMineBigNumber.zero))
                              'Eksik kasa: $missing',
                            if (materialDeficits.isNotEmpty)
                              'Cevher eksiği: ${materialDeficits.entries.map((entry) => '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}').join(', ')}',
                          ].join(' • '),
                    style: const TextStyle(
                      color: MinePalette.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: compact ? 44 : 48,
            height: compact ? 44 : 48,
            child: DecoratedBox(
              decoration: highlighted
                  ? BoxDecoration(
                      border: Border.all(color: MinePalette.amber, width: 2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0x99FFBE3E), blurRadius: 7),
                      ],
                    )
                  : const BoxDecoration(),
              child: IconButton.filled(
                tooltip: highlighted
                    ? 'Görev için bu yükseltme düğmesine dokun'
                    : level >= maxLevel
                    ? 'Şema ailesi tamamlandı'
                    : track == 'drill' && state.crewCount == 0
                    ? 'Önce bir madenci işe al'
                    : canBuy
                    ? 'Yükselt • $cost kasa'
                    : 'Eksik $missing kasa'
                          '${materialText.isEmpty ? '' : ' • $materialText'}',
                padding: EdgeInsets.zero,
                onPressed: canBuy ? () => controller.upgrade(track) : null,
                style: IconButton.styleFrom(
                  backgroundColor: MinePalette.amber,
                  foregroundColor: MinePalette.ink,
                  disabledBackgroundColor: const Color(0xFF203740),
                  disabledForegroundColor: MinePalette.muted,
                ),
                icon: Icon(
                  highlighted
                      ? Icons.touch_app_rounded
                      : Icons.arrow_upward_rounded,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.enabled = true,
    this.accent = MinePalette.amber,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xFF173741) : const Color(0xFF102E3A),
      border: Border.all(
        color: highlighted ? MinePalette.amber : const Color(0xFF294B55),
        width: highlighted ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: highlighted
          ? const [BoxShadow(color: Color(0x66FFBE3E), blurRadius: 10)]
          : null,
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF081D26),
            border: Border.all(color: accent.withValues(alpha: .65)),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: MinePalette.muted,
                  fontSize: 10,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: MinePalette.ink,
              disabledBackgroundColor: const Color(0xFF203740),
              disabledForegroundColor: MinePalette.muted,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              buttonLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}
