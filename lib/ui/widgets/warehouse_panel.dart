import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';
import '../../domain/models/cargo_equipment.dart';
import '../../domain/models/drill_assembly_definition.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/mr_mine_level_table.dart';
import '../../domain/models/mr_mine_progression.dart';
import '../../domain/models/resource_definition.dart';
import '../../domain/simulation/game_engine.dart';
import 'atlas_sprite.dart';
import 'game_primitives.dart';

typedef _VisibleWarehouseResource = ({
  ResourceDefinition resource,
  bool revealed,
});

class WarehousePanel extends StatefulWidget {
  const WarehousePanel({super.key, required this.controller});

  final GameController controller;

  @override
  State<WarehousePanel> createState() => _WarehousePanelState();
}

class _WarehousePanelState extends State<WarehousePanel> {
  bool _isotopeTab = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final world = state.activeWorldIndex;
    final resources = _visibleResources(state, world, isotopes: _isotopeTab);
    final nextCargo = GameEngine.nextCargoEquipment(state);
    final cargoBlueprintId = nextCargo == null
        ? null
        : DrillAssemblyCatalog.blueprintIdFor('cargo', nextCargo.level);
    final cargoBlueprintKnown = cargoBlueprintId == null ||
        state.knownBlueprintIds.contains(cargoBlueprintId);
    final deficits = GameEngine.cargoUpgradeDeficits(state);
    final deficitLabel = deficits.entries
        .map(
          (entry) =>
              '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
        )
        .join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ORTAK AMBAR',
          style: TextStyle(
            color: MinePalette.cyan,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dünya, Ay ve Titan kaynakları aynı kapasiteyi kullanır. Üretim doluluk sınırında durur; sondaj ilerlemeyi sürdürür.',
          style: const TextStyle(color: MinePalette.muted, fontSize: 10),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B222C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MinePalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: MinePalette.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Kargo kapasitesi',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${_quantity(state.cargoUsed.round())} / ${_quantity(state.effectiveCargoCapacity.round())}',
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.cargoRatio,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF06141C),
                  color: state.cargoFull
                      ? MinePalette.danger
                      : MinePalette.teal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_cargoName(state.cargoLevel)} • seviye ${state.cargoLevel}/16',
                style: const TextStyle(color: MinePalette.muted, fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (nextCargo != null)
          ActionTile(
            icon: Icons.upgrade_rounded,
            title: 'Kargo donanımını yükselt • ${nextCargo.name}',
            description:
                'Kapasite ${_quantity(state.cargoCapacity.round())} → ${_quantity(nextCargo.capacity.round())}.'
                '${cargoBlueprintKnown ? '' : ' Önce montaj şemasını keşfet.'}'
                '${deficitLabel.isEmpty ? '' : ' Eksik cevher: $deficitLabel.'}',
            buttonLabel: cargoBlueprintKnown
                ? '${_quantity(nextCargo.cashCost)} KASA'
                : 'ŞEMA GEREKİYOR',
            enabled: GameEngine.canUpgradeCargo(state),
            onPressed: () {
              if (!widget.controller.upgradeCargo()) return;
            },
            accent: MinePalette.amber,
          )
        else
          const _InventoryHint('Kargo kapasitesinin son seviyesine ulaştın.'),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment<bool>(
              value: false,
              label: Text('MADEN SAT'),
              icon: Icon(Icons.landscape_rounded),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('İZOTOP SAT'),
              icon: Icon(Icons.science_rounded),
            ),
          ],
          selected: {_isotopeTab},
          onSelectionChanged: (selection) =>
              setState(() => _isotopeTab = selection.first),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_worldName(world)} • ${resources.length} kaynak',
                style: const TextStyle(
                  color: MinePalette.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed:
                  resources.any(
                    (item) =>
                        state.amount(item.resource.id) >
                        state.reserve(item.resource.id),
                  )
                  ? () => widget.controller.sellAll(
                      worldIndex: world,
                      isotopesOnly: _isotopeTab,
                    )
                  : null,
              icon: const Icon(Icons.point_of_sale_rounded, size: 17),
              label: const Text('HEPSİNİ SAT'),
            ),
          ],
        ),
        const Text(
          'Kilit, seçilen en az miktarı tekli ve toplu satışta korur.',
          style: TextStyle(color: MinePalette.muted, fontSize: 9),
        ),
        const SizedBox(height: 5),
        if (resources.isEmpty)
          _InventoryHint(
            _isotopeTab
                ? 'Bu dünyada henüz izotop açılmadı.'
                : 'Henüz satılabilir maden açılmadı.',
          )
        else
          for (final item in resources)
            _WarehouseResourceRow(
              controller: widget.controller,
              resource: item.resource,
              revealed: item.revealed,
            ),
      ],
    );
  }

  List<_VisibleWarehouseResource> _visibleResources(
    GameState state,
    int world, {
    required bool isotopes,
  }) {
    final startFloor =
        (GameState.worldEntryDepths[world] / GameEngine.mineFloorMeters)
            .floor();
    final worldEndFloor = switch (world) {
      0 => MrMineProgression.earthEndMeters ~/ GameEngine.mineFloorMeters,
      1 => MrMineProgression.moonEndMeters ~/ GameEngine.mineFloorMeters,
      _ => MrMineLevelTable.rows.length,
    };
    final depth = world == state.activeWorldIndex
        ? state.depthMeters
        : (state.worldDepths[world.toString()] ??
              GameState.worldEntryDepths[world]);
    final endFloor = ((depth / GameEngine.mineFloorMeters).floor() + 1)
        .clamp(startFloor, worldEndFloor)
        .toInt();
    final discoveredIds = MrMineLevelTable.rarityWeightsBetween(
      startFloor,
      endFloor,
    ).keys.toSet();
    final resources = <String, _VisibleWarehouseResource>{};
    for (final id in MrMineLevelTable.rarityWeightsBetween(
      startFloor,
      worldEndFloor,
    ).keys) {
      final resource = ResourceCatalog.byId[id];
      if (resource == null ||
          resource.kind !=
              (isotopes ? ResourceKind.isotope : ResourceKind.mineral)) {
        continue;
      }
      resources[id] = (
        resource: resource,
        revealed: discoveredIds.contains(id) || state.amount(id) > 0,
      );
    }
    for (final resource in ResourceCatalog.all) {
      if (resource.kind !=
              (isotopes ? ResourceKind.isotope : ResourceKind.mineral) ||
          _resourceWorld(
                resource.id,
                ResourceCatalog.firstMineDepthMeters(resource.id),
              ) !=
              world ||
          state.amount(resource.id) <= 0) {
        continue;
      }
      resources[resource.id] = (resource: resource, revealed: true);
    }
    final result = resources.values.toList()
      ..sort((a, b) {
        final valueOrder = a.resource.baseValue.compareTo(b.resource.baseValue);
        return valueOrder != 0
            ? valueOrder
            : a.resource.name.compareTo(b.resource.name);
      });
    return result;
  }

  int? _resourceWorld(String resourceId, double minDepth) {
    final mineralBand = MrMineProgression.bandByResourceId[resourceId];
    if (mineralBand != null) return mineralBand.worldIndex;
    if (RegExp(r'^(?:u|pu|po)[1-3]$').hasMatch(resourceId)) return 0;
    if (RegExp(r'^(?:n|he|e|f)[1-3]$').hasMatch(resourceId)) return 1;
    if (RegExp(r'^(?:h|o)[1-3]$').hasMatch(resourceId)) return 2;
    return MrMineProgression.worldAtDepth(minDepth);
  }

  String _worldName(int world) => const ['Dünya', 'Ay', 'Titan'][world];

  String _cargoName(int level) => CargoEquipmentCatalog.all[level - 1].name;

  String _quantity(num value) {
    if (value >= 1e18) return '${(value / 1e18).toStringAsFixed(1)}Qi';
    if (value >= 1e15) return '${(value / 1e15).toStringAsFixed(1)}Qa';
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(1)}T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.round().toString();
  }
}

class _WarehouseResourceRow extends StatelessWidget {
  const _WarehouseResourceRow({
    required this.controller,
    required this.resource,
    required this.revealed,
  });

  final GameController controller;
  final ResourceDefinition resource;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final amount = state.amount(resource.id);
    final reserve = state.reserve(resource.id);
    final available = (amount - reserve).clamp(0, amount).toInt();
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B222C),
        border: Border.all(color: const Color(0xFF294650)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          if (revealed)
            AtlasSprite(
              asset: 'resources-treasure-sheet.png',
              index: resource.iconIndex,
              columns: 4,
              rows: 4,
              width: 37,
              height: 37,
            )
          else
            const SizedBox(
              width: 37,
              height: 37,
              child: Icon(Icons.help_outline_rounded, color: MinePalette.muted),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  revealed ? resource.name : '???',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  revealed
                      ? '\$${_unitPrice(resource.baseValue)} / birim'
                      : '—',
                  style: const TextStyle(color: MinePalette.muted, fontSize: 8),
                ),
              ],
            ),
          ),
          Text(
            '×$amount',
            style: const TextStyle(
              color: MinePalette.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            tooltip: reserve > 0
                ? 'Satış kilidini düzenle'
                : 'Stok kilidi ekle',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 38, height: 40),
            onPressed: revealed && amount > 0
                ? () => _editReserve(context, amount, reserve)
                : null,
            icon: Icon(
              reserve > 0 ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: reserve > 0 ? MinePalette.amber : MinePalette.muted,
              size: 17,
            ),
          ),
          SizedBox(
            width: 58,
            height: 34,
            child: FilledButton(
              onPressed: revealed && available > 0
                  ? () => controller.sell(resource.id, quantity: available)
                  : null,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'SAT',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReserve(
    BuildContext context,
    int owned,
    int currentReserve,
  ) async {
    final input = TextEditingController(text: currentReserve.toString());
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MinePalette.panel,
        title: Text('${resource.name} • satış kilidi'),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Satıştan korunacak miktar',
            helperText: 'Sahip olunan miktar: $owned',
            suffixText: '/ $owned',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(input.text.trim())?.clamp(0, owned).toInt() ?? 0,
            ),
            child: const Text('UYGULA'),
          ),
        ],
      ),
    );
    input.dispose();
    if (selected != null) {
      controller.setResourceReserve(resource.id, selected);
    }
  }

  String _unitPrice(num value) {
    if (value >= 1e18) return '${(value / 1e18).toStringAsFixed(1)}Qi';
    if (value >= 1e15) return '${(value / 1e15).toStringAsFixed(1)}Qa';
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(1)}T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.round().toString();
  }
}

class _InventoryHint extends StatelessWidget {
  const _InventoryHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0B222C),
      border: Border.all(color: MinePalette.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: const TextStyle(color: MinePalette.muted, fontSize: 10),
    ),
  );
}
