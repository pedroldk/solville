import 'dart:math' as math;
import 'dart:typed_data';

import '../models/grid_pos.dart';

/// Callback returning whether [pos] can be walked onto.
typedef WalkablePredicate = bool Function(GridPos pos);

/// Callback returning traversal cost for entering [pos] (default `1.0`, lower
/// on stone paths so the farmer prefers paved garden walkways!).
typedef StepCostFunction = double Function(GridPos from, GridPos to);

/// Fast deterministic A* pathfinder on the isometric grid using flat typed
/// arrays and an indexed binary min-heap for zero-boxing traversal.
class AStarPathfinder {
  const AStarPathfinder();

  static const List<(int, int)> _cardinalDirs = <(int, int)>[
    (1, 0),
    (-1, 0),
    (0, 1),
    (0, -1),
  ];

  static const List<(int, int)> _diagonalDirs = <(int, int)>[
    (1, 1),
    (1, -1),
    (-1, 1),
    (-1, -1),
  ];

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
    bool inBoundsXY(int x, int y) =>
        x >= 0 && y >= 0 && x < gridSize && y < gridSize;

    if (!inBoundsXY(start.x, start.y) || !inBoundsXY(goal.x, goal.y)) {
      return const <GridPos>[];
    }

    final totalCells = gridSize * gridSize;
    // Cache walkability in a flat Uint8List (0 = unknown, 1 = walkable, 2 = blocked)
    // so repeated corner-clipping checks never invoke the closure twice for the same tile.
    final walkableCache = Uint8List(totalCells);

    bool checkWalkable(int x, int y) {
      final idx = y * gridSize + x;
      final cached = walkableCache[idx];
      if (cached != 0) return cached == 1;
      final ok = isWalkable(GridPos(x, y));
      walkableCache[idx] = ok ? 1 : 2;
      return ok;
    }

    // Determine valid destination target indices.
    final targetIndices = <int>[];
    final isTargetMask = Uint8List(totalCells);

    void addTarget(int x, int y) {
      final idx = y * gridSize + x;
      if (isTargetMask[idx] == 0) {
        isTargetMask[idx] = 1;
        targetIndices.add(idx);
      }
    }

    if (checkWalkable(goal.x, goal.y)) {
      addTarget(goal.x, goal.y);
    } else {
      for (final (dx, dy) in _cardinalDirs) {
        final nx = goal.x + dx;
        final ny = goal.y + dy;
        if (inBoundsXY(nx, ny) && checkWalkable(nx, ny)) {
          addTarget(nx, ny);
        }
      }
      if (targetIndices.isEmpty) {
        for (final (dx, dy) in _diagonalDirs) {
          final nx = goal.x + dx;
          final ny = goal.y + dy;
          if (inBoundsXY(nx, ny) && checkWalkable(nx, ny)) {
            addTarget(nx, ny);
          }
        }
      }
    }

    if (targetIndices.isEmpty) {
      return const <GridPos>[];
    }

    final startIdx = start.y * gridSize + start.x;
    if (isTargetMask[startIdx] == 1) {
      return <GridPos>[start];
    }

    double heuristic(int x, int y) {
      var best = double.infinity;
      for (var i = 0; i < targetIndices.length; i++) {
        final tIdx = targetIndices[i];
        final tx = tIdx % gridSize;
        final ty = tIdx ~/ gridSize;
        final dx = (x - tx).toDouble();
        final dy = (y - ty).toDouble();
        final dist = math.sqrt(dx * dx + dy * dy) * 0.72;
        if (dist < best) best = dist;
      }
      return best;
    }

    final gScore = Float64List(totalCells);
    final fScore = Float64List(totalCells);
    final cameFrom = Int32List(totalCells);
    for (var i = 0; i < totalCells; i++) {
      gScore[i] = double.infinity;
      fScore[i] = double.infinity;
      cameFrom[i] = -1;
    }

    // 0 = unvisited, 1 = open, 2 = closed
    final stateMask = Uint8List(totalCells);

    // Binary min-heap of cell indices ordered by `fScore`
    final heap = Int32List(totalCells);
    final heapPos = Int32List(totalCells)..fillRange(0, totalCells, -1);
    var heapSize = 0;

    void siftUp(int idxInHeap) {
      var i = idxInHeap;
      final node = heap[i];
      final nodeF = fScore[node];
      while (i > 0) {
        final parentIdx = (i - 1) >> 1;
        final parentNode = heap[parentIdx];
        if (nodeF >= fScore[parentNode]) break;
        heap[i] = parentNode;
        heapPos[parentNode] = i;
        i = parentIdx;
      }
      heap[i] = node;
      heapPos[node] = i;
    }

    void siftDown(int idxInHeap) {
      var i = idxInHeap;
      final node = heap[i];
      final nodeF = fScore[node];
      final half = heapSize >> 1;
      while (i < half) {
        var childIdx = (i << 1) + 1;
        var childNode = heap[childIdx];
        var childF = fScore[childNode];
        final rightIdx = childIdx + 1;
        if (rightIdx < heapSize) {
          final rightNode = heap[rightIdx];
          final rightF = fScore[rightNode];
          if (rightF < childF) {
            childIdx = rightIdx;
            childNode = rightNode;
            childF = rightF;
          }
        }
        if (nodeF <= childF) break;
        heap[i] = childNode;
        heapPos[childNode] = i;
        i = childIdx;
      }
      heap[i] = node;
      heapPos[node] = i;
    }

    void pushOrDecreaseKey(int cellIdx) {
      final existingPos = heapPos[cellIdx];
      if (existingPos >= 0) {
        siftUp(existingPos);
      } else {
        final insertAt = heapSize++;
        heap[insertAt] = cellIdx;
        heapPos[cellIdx] = insertAt;
        siftUp(insertAt);
      }
    }

    int popMin() {
      final minNode = heap[0];
      heapPos[minNode] = -1;
      heapSize--;
      if (heapSize > 0) {
        final lastNode = heap[heapSize];
        heap[0] = lastNode;
        heapPos[lastNode] = 0;
        siftDown(0);
      }
      return minNode;
    }

    gScore[startIdx] = 0.0;
    fScore[startIdx] = heuristic(start.x, start.y);
    stateMask[startIdx] = 1;
    pushOrDecreaseKey(startIdx);

    while (heapSize > 0) {
      final currentIdx = popMin();
      if (isTargetMask[currentIdx] == 1) {
        return _reconstructPath(cameFrom, currentIdx, gridSize);
      }

      stateMask[currentIdx] = 2;
      final cx = currentIdx % gridSize;
      final cy = currentIdx ~/ gridSize;
      final currentG = gScore[currentIdx];
      final currentPos = stepCost != null ? GridPos(cx, cy) : null;

      void tryNeighbor(int nx, int ny, double baseMove) {
        final nextIdx = ny * gridSize + nx;
        if (stateMask[nextIdx] == 2) return;
        final tileFactor = stepCost != null
            ? stepCost(currentPos!, GridPos(nx, ny))
            : 1.0;
        final tentativeG = currentG + baseMove * tileFactor;
        if (tentativeG < gScore[nextIdx]) {
          cameFrom[nextIdx] = currentIdx;
          gScore[nextIdx] = tentativeG;
          fScore[nextIdx] = tentativeG + heuristic(nx, ny);
          stateMask[nextIdx] = 1;
          pushOrDecreaseKey(nextIdx);
        }
      }

      // Cardinal steps
      for (final (dx, dy) in _cardinalDirs) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (inBoundsXY(nx, ny) && checkWalkable(nx, ny)) {
          tryNeighbor(nx, ny, 1.0);
        }
      }

      // Diagonal steps (only when both adjacent cardinal tiles are clear)
      for (final (dx, dy) in _diagonalDirs) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (inBoundsXY(nx, ny) &&
            checkWalkable(nx, ny) &&
            checkWalkable(cx + dx, cy) &&
            checkWalkable(cx, cy + dy)) {
          tryNeighbor(nx, ny, math.sqrt2);
        }
      }
    }

    return const <GridPos>[];
  }

  List<GridPos> _reconstructPath(
    Int32List cameFrom,
    int targetIdx,
    int gridSize,
  ) {
    var length = 0;
    var cursor = targetIdx;
    while (cursor != -1) {
      length++;
      cursor = cameFrom[cursor];
    }

    final result = List<GridPos>.filled(length, const GridPos(0, 0));
    cursor = targetIdx;
    for (var i = length - 1; i >= 0; i--) {
      result[i] = GridPos(cursor % gridSize, cursor ~/ gridSize);
      cursor = cameFrom[cursor];
    }
    return result;
  }
}
