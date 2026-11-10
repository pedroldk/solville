import 'dart:math' as math;

/// Immutable integer coordinates on the Solville isometric farm grid.
class GridPos {
  const GridPos(this.x, this.y);

  final int x;
  final int y;

  /// Cardinal 4-directional neighbors.
  List<GridPos> get cardinalNeighbors => <GridPos>[
    GridPos(x + 1, y),
    GridPos(x - 1, y),
    GridPos(x, y + 1),
    GridPos(x, y - 1),
  ];

  /// All 8 surrounding neighbors (cardinal + diagonal).
  List<GridPos> get allNeighbors => <GridPos>[
    GridPos(x + 1, y),
    GridPos(x - 1, y),
    GridPos(x, y + 1),
    GridPos(x, y - 1),
    GridPos(x + 1, y + 1),
    GridPos(x + 1, y - 1),
    GridPos(x - 1, y + 1),
    GridPos(x - 1, y - 1),
  ];

  int manhattanDistanceTo(GridPos other) =>
      (x - other.x).abs() + (y - other.y).abs();

  int chebyshevDistanceTo(GridPos other) =>
      math.max((x - other.x).abs(), (y - other.y).abs());

  double euclideanDistanceTo(GridPos other) {
    final dx = (x - other.x).toDouble();
    final dy = (y - other.y).toDouble();
    return math.sqrt(dx * dx + dy * dy);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'x': x, 'y': y};

  factory GridPos.fromJson(Map<String, dynamic> json) =>
      GridPos(json['x'] as int, json['y'] as int);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos && x == other.x && y == other.y;

  @override
  int get hashCode => (y << 16) ^ (x & 0xFFFF);

  @override
  String toString() => 'GridPos($x, $y)';
}
