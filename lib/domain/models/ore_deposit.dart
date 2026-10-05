class OreDepositState {
  OreDepositState({
    required this.id,
    required this.worldIndex,
    required this.floorIndex,
    required this.resourceId,
    required this.amount,
    required this.hitPoints,
    required this.side,
    required this.pocket,
    this.spawnDepthMeters,
    this.damage = 0,
  });

  final String id;
  final int worldIndex;
  final int floorIndex;
  final String resourceId;
  final int amount;
  final int hitPoints;
  final int side;
  final int pocket;
  final double? spawnDepthMeters;
  int damage;

  bool get depleted => damage >= hitPoints;

  double get progress => (damage / hitPoints).clamp(0, 1).toDouble();

  Map<String, Object?> toJson() => {
    'worldIndex': worldIndex,
    'floorIndex': floorIndex,
    'resourceId': resourceId,
    'amount': amount,
    'hitPoints': hitPoints,
    'damage': damage,
    'side': side,
    'pocket': pocket,
    if (spawnDepthMeters != null) 'spawnDepthMeters': spawnDepthMeters,
  };

  factory OreDepositState.fromJson(String id, Map<String, Object?> json) {
    int readInt(String key, [int fallback = 0]) =>
        (json[key] as num?)?.toInt() ?? fallback;

    return OreDepositState(
      id: id,
      worldIndex: readInt('worldIndex').clamp(0, 2).toInt(),
      floorIndex: readInt('floorIndex').clamp(0, 10000000).toInt(),
      resourceId: json['resourceId'] as String? ?? '',
      amount: readInt('amount', 1).clamp(1, 1000000000).toInt(),
      hitPoints: readInt('hitPoints', 3).clamp(1, 1000000).toInt(),
      damage: readInt('damage').clamp(0, 1000000).toInt(),
      side: readInt('side').clamp(0, 1).toInt(),
      pocket: readInt('pocket').clamp(0, 4).toInt(),
      spawnDepthMeters: (json['spawnDepthMeters'] as num?)?.toDouble(),
    );
  }
}
