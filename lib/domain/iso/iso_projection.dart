import '../models/grid_pos.dart';

/// Pure 2:1 isometric coordinate projection and depth-sorting math.
///
/// Each grid tile `(gx, gy)` has its diamond center at `(gx, gy)` in continuous
/// grid space and spans `[gx - 0.5, gx + 0.5) x [gy - 0.5, gy + 0.5)`.
class IsoProjection {
  const IsoProjection({
    this.tileWidth = 96.0,
    this.tileHeight = 48.0,
    this.elevationScale = 24.0,
  });

  final double tileWidth;
  final double tileHeight;
  final double elevationScale;

  /// Projects continuous grid coordinates `(gx, gy)` and elevation `gz` to 2D
  /// world coordinates `(wx, wy)`.
  ({double x, double y}) gridToWorld(double gx, double gy, {double gz = 0.0}) {
    final wx = (gx - gy) * (tileWidth * 0.5);
    final wy = (gx + gy) * (tileHeight * 0.5) - gz * elevationScale;
    return (x: wx, y: wy);
  }

  /// Projects an integer [GridPos] center to 2D world coordinates.
  ({double x, double y}) tileCenterToWorld(GridPos pos, {double gz = 0.0}) =>
      gridToWorld(pos.x.toDouble(), pos.y.toDouble(), gz: gz);

  /// Inverse transform from 2D world coordinates `(wx, wy)` on plane `gz` to
  /// continuous grid coordinates `(gx, gy)`.
  ({double gx, double gy}) worldToContinuousGrid(
    double wx,
    double wy, {
    double gz = 0.0,
  }) {
    final adjustedWy = wy + gz * elevationScale;
    final gx = (wx / tileWidth) + (adjustedWy / tileHeight);
    final gy = (adjustedWy / tileHeight) - (wx / tileWidth);
    return (gx: gx, gy: gy);
  }

  /// Maps a 2D world point `(wx, wy)` to the discrete [GridPos] diamond that
  /// contains it.
  GridPos worldToTile(double wx, double wy, {double gz = 0.0}) {
    final continuous = worldToContinuousGrid(wx, wy, gz: gz);
    return GridPos(
      (continuous.gx + 0.5).floor(),
      (continuous.gy + 0.5).floor(),
    );
  }

  /// Painter's-algorithm render priority so foreground tiles and entities
  /// cleanly overlap background elements in 2.5D space.
  int computePriority(double gx, double gy, {int layerBias = 0}) {
    return ((gx + gy) * 100.0).round() + layerBias;
  }
}
