import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../domain/models/game_state.dart';
import '../services/sound_service.dart';
import 'crusher_engine.dart';
import 'localization.dart';
import 'crusher_scene.dart';

class CrusherView extends StatefulWidget {
  const CrusherView({super.key, required this.controller});

  final GameController controller;

  @override
  State<CrusherView> createState() => _CrusherViewState();
}

class _CrusherViewState extends State<CrusherView> {
  late final CrusherGame _game;

  @override
  void initState() {
    super.initState();
    _game = CrusherGame(widget.controller);
    _game.start();
  }

  @override
  void dispose() {
    _game.pause();
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _game]),
      builder: (context, _) {
        final state = widget.controller.state;
        return Scaffold(
          backgroundColor: const Color(0xff0d131a),
          appBar: _buildHeader(state),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            Expanded(child: _buildMachineViewport()),
                            _buildWarehouseStatusBar(state),
                            _buildRawOreQueueStrip(state),
                          ],
                        ),
                      ),
                      Container(width: 1, color: const Color(0xff222e3d)),
                      Expanded(
                        flex: 4,
                        child: _buildUpgradesAndInfoPanel(state),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Expanded(flex: 5, child: _buildMachineViewport()),
                    _buildWarehouseStatusBar(state),
                    _buildRawOreQueueStrip(state),
                    Expanded(flex: 5, child: _buildUpgradesAndInfoPanel(state)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildHeader(GameState state) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return AppBar(
      backgroundColor: const Color(0xff121a24),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xffccd7e6),
          size: 18,
        ),
        onPressed: withButtonTapSound(() => Navigator.of(context).pop()),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.precision_manufacturing_rounded,
            color: Color(0xffc8ef70),
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.gameText('KIRICI'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
                color: Color(0xfff0f4f8),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xff223247),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LV.${_game.level}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xffc8ef70),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10, right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: state.cargoFull
                ? const Color(0xff3b1616)
                : const Color(0xff182230),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: state.cargoFull
                  ? const Color(0xffff5555)
                  : const Color(0xff2c3b4e),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_rounded,
                color: state.cargoFull
                    ? const Color(0xffff5555)
                    : const Color(0xff77c2ff),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${state.cargoUsed.toInt()} / ${state.effectiveCargoCapacity.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: state.cargoFull
                      ? const Color(0xffff8888)
                      : const Color(0xfff5f8fc),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xff182230),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff2c3b4e)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xffffd46a),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                state.coins.toDisplayString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xfff5f8fc),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMachineViewport() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xff111923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff26364a)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CrusherScene(game: _game),
    );
  }

  Widget _buildWarehouseStatusBar(GameState state) {
    return CrusherCargoStatusBar(
      state: state,
      onSell: widget.controller.sellAll,
    );
  }

  Widget _buildRawOreQueueStrip(GameState state) {
    final rawCount = state.totalRawOreCount;
    final hopperCap = state.crusherHopperCapacity;
    final ratio = (rawCount / hopperCap).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff141d28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xff223042)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.input_rounded,
                    size: 14,
                    color: Color(0xff9cb1cc),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.gameText('Kırıcı Giriş Haznesi:'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xffd0dbe6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.gameText(
                      '{count} / {capacity} Ham Parça',
                      values: {'count': rawCount, 'capacity': hopperCap},
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: state.crusherHopperFull
                          ? const Color(0xffff8b7a)
                          : const Color(0xffc8ef70),
                    ),
                  ),
                ],
              ),
              Text(
                context.gameText(
                  'Oto Kırma: {rate}/sn',
                  values: {
                    'rate': (_game.speedLevel * 1.5 + _game.powerLevel * 0.8)
                        .toStringAsFixed(1),
                  },
                ),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff889db5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xff1d2938),
              valueColor: AlwaysStoppedAnimation(
                state.crusherHopperFull
                    ? const Color(0xffff6852)
                    : const Color(0xffc8ef70),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 24,
            child: state.rawOreInventory.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: state.rawOreInventory.entries.map((entry) {
                        final mat = oreMaterialById(entry.key);
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff1a2636),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: mat.color.withValues(alpha: .5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: mat.glow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${context.gameText(mat.name)}: ${entry.value}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xffe2eaf4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradesAndInfoPanel(GameState state) {
    return Container(
      color: const Color(0xff101722),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              context.gameText('MAKİNE & AYRIŞTIRMA GELİŞTİRMELERİ'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
                color: Color(0xff8da1b8),
              ),
            ),
          ),
          _buildUpgradeCard(
            id: 'speed',
            title: 'Merdane Devri (Hız)',
            subtitle: 'Kırıcı dişlilerin dönüş hızını ve kırma vuruş sıklığını artırır.',
            icon: Icons.speed_rounded,
            color: const Color(0xff57b8ff),
          ),
          _buildUpgradeCard(
            id: 'power',
            title: 'Ezme & Kırma Gücü',
            subtitle: 'Sert taş ve madenleri daha az vuruşta parçalama gücü kazandırır.',
            icon: Icons.fitness_center_rounded,
            color: const Color(0xffff7c54),
          ),
          _buildUpgradeCard(
            id: 'storage',
            title: 'Hazne Hacmi (Kapasite)',
            subtitle: 'Madencilerin kırma ünitesine doldurabileceği ham taş kapasitesini artırır.',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xfffab617),
          ),
          _buildUpgradeCard(
            id: 'teeth',
            title: 'Elmas Merdane Dişleri',
            subtitle: 'Her ezmede ekstra kaya ufalar, kritik vuruş ve özel parça şansını katlar.',
            icon: Icons.hardware_rounded,
            color: const Color(0xffbfa2e3),
          ),
          _buildUpgradeCard(
            id: 'gearbox',
            title: 'Ağır Hizmet Dişli Kutusu',
            subtitle: 'Kırma işlemi başına ana kasaya düşen nakit kırma gelirini artırır.',
            icon: Icons.settings_rounded,
            color: const Color(0xff5ee2a0),
          ),
          _buildUpgradeCard(
            id: 'ore',
            title: 'Elek & Saflaştırma Verimi',
            subtitle: 'Kırılan madenlerden ambara çıkan saf maden verim çarpanını yükseltir.',
            icon: Icons.filter_vintage_rounded,
            color: const Color(0xff72d6d2),
          ),
          _buildUpgradeCard(
            id: 'feed',
            title: 'Konveyör Besleme Hattı',
            subtitle: 'Hazneden kırıcı dişlilerine dökülen taşların bant ilerleme hızını artırır.',
            icon: Icons.conveyor_belt,
            color: const Color(0xffc8ef70),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final level = widget.controller.state.crusherUpgrades[id] ?? 1;
    final cost = _game.upgradeCost(id);
    final canAfford = widget.controller.state.coins.toDouble() >= cost;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff16202c),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xff233245)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: .3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.gameText(title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xffedf2f7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff223247),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.gameText('Sv. {level}', values: {'level': level}),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.gameText(subtitle),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: .55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: withButtonTapSound(
              canAfford ? () => _game.buyUpgrade(id) : null,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford
                  ? const Color(0xffc8ef70)
                  : const Color(0xff26364a),
              foregroundColor: canAfford
                  ? const Color(0xff0d1902)
                  : const Color(0xff73869c),
              disabledBackgroundColor: const Color(0xff1b2636),
              disabledForegroundColor: const Color(0xff4c5d73),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.gameText('YÜKSELT'),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                ),
                Text(
                  '$cost 🪙',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class CrusherCargoStatusBar extends StatelessWidget {
  const CrusherCargoStatusBar({
    super.key,
    required this.state,
    required this.onSell,
  });

  final GameState state;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final cargoUsed = state.cargoUsed.toInt();
    final cargoCap = state.effectiveCargoCapacity.toInt();
    final isFull = state.cargoFull;
    final ratio = state.cargoRatio.clamp(0.0, 1.0);
    final label = context.gameText(
      isFull ? 'AMBAR DOLU (KIRICI DURDURULDU):' : 'Ambar Kapasitesi (Çıkış):',
    );
    final amount = Text(
      '$cargoUsed / $cargoCap kg',
      key: const ValueKey('crusher-cargo-amount'),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isFull ? const Color(0xffff4d4d) : const Color(0xff8bc34a),
      ),
    );
    final sellButton = (isFull || cargoUsed > 0)
        ? InkWell(
            key: const ValueKey('crusher-cargo-sell-action'),
            onTap: withButtonTapSound(onSell),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isFull
                    ? const Color(0xffff4444)
                    : const Color(0xff1d402b),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isFull
                      ? const Color(0xffff8b7a)
                      : const Color(0xff3fa366),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sell_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    context.gameText(
                      isFull ? 'TÜMÜNÜ SAT & ÇALIŞTIR' : 'Tümünü Sat',
                    ),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final status = Row(
          children: [
            Icon(
              isFull ? Icons.warning_amber_rounded : Icons.warehouse_rounded,
              size: 15,
              color: isFull ? const Color(0xffff6852) : const Color(0xff9cb1cc),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                softWrap: true,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isFull
                      ? const Color(0xffff8b7a)
                      : const Color(0xffd0dbe6),
                ),
              ),
            ),
          ],
        );

        return Container(
          key: const ValueKey('crusher-cargo-status-bar'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isFull ? const Color(0xff2a1111) : const Color(0xff141d28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFull ? const Color(0xffff4444) : const Color(0xff223042),
              width: isFull ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                status,
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: amount),
                    if (sellButton != null) ...[
                      const SizedBox(width: 6),
                      sellButton,
                    ],
                  ],
                ),
              ] else
                Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 8),
                    amount,
                    if (sellButton != null) ...[
                      const SizedBox(width: 8),
                      sellButton,
                    ],
                  ],
                ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: const Color(0xff1d2938),
                  valueColor: AlwaysStoppedAnimation(
                    isFull
                        ? const Color(0xffff3b30)
                        : (ratio > 0.85
                              ? const Color(0xffffa726)
                              : const Color(0xff8bc34a)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
