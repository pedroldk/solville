import 'package:flutter_test/flutter_test.dart';
import 'package:solville/domain/iso/iso_projection.dart';
import 'package:solville/domain/models/grid_pos.dart';
import 'package:solville/domain/pathfinding/astar_pathfinder.dart';

void main() {
  group('IsoProjection', () {
    const iso = IsoProjection();

    test('round-trips every tile center accurately across 17x17 grid', () {
      for (var y = 0; y < 17; y++) {
        for (var x = 0; x < 17; x++) {
          final original = GridPos(x, y);
          final world = iso.tileCenterToWorld(original);
          final mapped = iso.worldToTile(world.x, world.y);
          expect(mapped, equals(original));
        }
      }
    });

    test('maps interior diamond offsets near corners to the same tile', () {
      const target = GridPos(4, 7);
      final center = iso.tileCenterToWorld(target);

      // Inside top, bottom, left, and right diamond vertices
      expect(iso.worldToTile(center.x, center.y - 20.0), equals(target));
      expect(iso.worldToTile(center.x, center.y + 20.0), equals(target));
      expect(iso.worldToTile(center.x - 40.0, center.y), equals(target));
      expect(iso.worldToTile(center.x + 40.0, center.y), equals(target));
    });

    test('assigns higher painter priority to foreground tiles', () {
      final back = iso.computePriority(1, 1);
      final front = iso.computePriority(4, 5);
      expect(front, greaterThan(back));
    });
  });

  group('AStarPathfinder', () {
    const pathfinder = AStarPathfinder();

    test('navigates cleanly around solid structures without clipping corners', () {
      final blocked = <GridPos>{
        const GridPos(3, 2),
        const GridPos(3, 3),
        const GridPos(3, 4),
      };
      final path = pathfinder.findPath(
        start: const GridPos(1, 3),
        goal: const GridPos(5, 3),
        gridSize: 8,
        isWalkable: (p) => !blocked.contains(p),
      );

      expect(path, isNotEmpty);
      expect(path.first, equals(const GridPos(1, 3)));
      expect(path.last, equals(const GridPos(5, 3)));
      for (final step in path) {
        expect(blocked.contains(step), isFalse);
      }
    });

    test('routes to adjacent walkable neighbor when goal is a solid Well', () {
      const well = GridPos(2, 3);
      final path = pathfinder.findPath(
        start: const GridPos(5, 5),
        goal: well,
        gridSize: 10,
        isWalkable: (p) => p != well,
      );

      expect(path, isNotEmpty);
      expect(path.last.manhattanDistanceTo(well), equals(1));
    });
  });
}
