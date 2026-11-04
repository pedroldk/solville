import 'dart:collection';
import 'dart:math' as math;

import '../models/grid_pos.dart';

/// Callback returning whether [pos] can be walked onto.
typedef WalkablePredicate = bool Function(GridPos pos);

/// Callback returning traversal cost for entering [pos] (default `1.0`, lower
/// on stone paths so the farmer prefers paved garden walkways!).
typedef StepCostFunction = double Function(GridPos from, GridPos to);

/// Fast deterministic A* pathfinder on the isometric grid.
class AStarPathfinder {
  const AStarPathfinder();

  /// Finds a path from [start] to [goal] (or to the nearest walkable cardinal
  /// neighbor of [goal] when [goal] itself is a solid structure like the Well,
  /// Barn, Market Stall, or Animal Pen).
  List<GridPos> findPath({
    required GridPos start,
    required GridPos goal,
    required int gridSize,
    required WalkablePredicate isWalkable,
    StepCostFunction? stepCost,
  }) {
    bool inBounds(GridPos p) =>
        p.x >= 0 && p.y >= 0 && p.x < gridSize && p.y < gridSize;

    if (!inBounds(start) || !inBounds(goal)) {
      return const <GridPos>[];
    }

    // Determine valid destination targets.
    final Set<GridPos> targets = <GridPos>{};
    if (isWalkable(goal)) {
      targets.add(goal);
    } else {
      for (final neighbor in goal.cardinalNeighbors) {
        if (inBounds(neighbor) && isWalkable(neighbor)) {
          targets.add(neighbor);
        }
      }
      if (targets.isEmpty) {
        for (final neighbor in goal.allNeighbors) {
          if (inBounds(neighbor) && isWalkable(neighbor)) {
            targets.add(neighbor);
          }
        }
      }
    }

    if (targets.isEmpty) {
      return const <GridPos>[];
    }
    if (targets.contains(start)) {
      return <GridPos>[start];
    }

    final gScore = HashMap<GridPos, double>()..[start] = 0.0;
    final fScore = HashMap<GridPos, double>()
      ..[start] = _heuristic(start, targets);
    final cameFrom = HashMap<GridPos, GridPos>();
    final openSet = <GridPos>{start};
    final closedSet = <GridPos>{};

    while (openSet.isNotEmpty) {
      GridPos? current;
      var bestF = double.infinity;
      for (final candidate in openSet) {
        final score = fScore[candidate] ?? double.infinity;
        if (score < bestF) {
          bestF = score;
          current = candidate;
        }
      }

      if (current == null) break;
      if (targets.contains(current)) {
        return _reconstructPath(cameFrom, current);
      }

      openSet.remove(current);
      closedSet.add(current);

      for (final next in _validNeighbors(current, gridSize, isWalkable)) {
        if (closedSet.contains(next)) continue;

        final isDiagonal = next.x != current.x && next.y != current.y;
        final baseMove = isDiagonal ? math.sqrt2 : 1.0;
        final tileFactor = stepCost != null ? stepCost(current, next) : 1.0;
        final tentativeG =
            (gScore[current] ?? double.infinity) + baseMove * tileFactor;

        if (tentativeG < (gScore[next] ?? double.infinity)) {
          cameFrom[next] = current;
          gScore[next] = tentativeG;
          fScore[next] = tentativeG + _heuristic(next, targets);
          openSet.add(next);
        }
      }
    }

    return const <GridPos>[];
  }

  Iterable<GridPos> _validNeighbors(
    GridPos current,
    int gridSize,
    WalkablePredicate isWalkable,
  ) sync* {
    bool inBounds(GridPos p) =>
        p.x >= 0 && p.y >= 0 && p.x < gridSize && p.y < gridSize;

    for (final cardinal in current.cardinalNeighbors) {
      if (inBounds(cardinal) && isWalkable(cardinal)) {
        yield cardinal;
      }
    }

    // Allow diagonal steps only when both adjacent cardinal tiles are clear
    // (prevents corner-clipping through wells, coops, and fences).
    const diagonals = <(int, int)>[
      (1, 1),
      (1, -1),
      (-1, 1),
      (-1, -1),
    ];
    for (final (dx, dy) in diagonals) {
      final diag = GridPos(current.x + dx, current.y + dy);
      final sideA = GridPos(current.x + dx, current.y);
      final sideB = GridPos(current.x, current.y + dy);
      if (inBounds(diag) &&
          isWalkable(diag) &&
          inBounds(sideA) &&
          isWalkable(sideA) &&
          inBounds(sideB) &&
          isWalkable(sideB)) {
        yield diag;
      }
    }
  }

  double _heuristic(GridPos pos, Set<GridPos> targets) {
    var best = double.infinity;
    for (final target in targets) {
      final dist = pos.euclideanDistanceTo(target) * 0.72;
      if (dist < best) best = dist;
    }
    return best;
  }

  List<GridPos> _reconstructPath(
    Map<GridPos, GridPos> cameFrom,
    GridPos current,
  ) {
    final reversed = <GridPos>[current];
    var cursor = current;
    while (cameFrom.containsKey(cursor)) {
      cursor = cameFrom[cursor]!;
      reversed.add(cursor);
    }
    return reversed.reversed.toList();
  }
}
