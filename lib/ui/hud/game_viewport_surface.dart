import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../game/solville_game.dart';

/// Unified pointer & touch surface around [GameWidget] providing conflict-free:
/// - Single tap / left-click to append to Action Queue
/// - Shift + Drag on PC/Steam to row-paint chores across garden beds
/// - Right-click to cancel queued task on PC/Steam
/// - Mouse hover diamond preview + sprinkler radius preview
/// - Mouse wheel zoom on PC + two-finger pinch zoom & one-finger drag pan on Android
class GameViewportSurface extends StatelessWidget {
  const GameViewportSurface({super.key, required this.game});

  final SolvilleGame game;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (PointerSignalEvent signal) {
        if (signal is PointerScrollEvent) {
          game.handleMouseScroll(signal.scrollDelta.dy);
        }
      },
      child: MouseRegion(
        onHover: (PointerHoverEvent event) {
          game.handlePointerHover(event.localPosition);
        },
        onExit: (_) => game.controller.setHoveredTile(null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails details) {
            game.handlePrimaryTap(details.localPosition);
          },
          onSecondaryTapUp: (TapUpDetails details) {
            game.handleSecondaryTap(details.localPosition);
          },
          onScaleStart: (_) => game.handleScaleStart(),
          onScaleUpdate: (ScaleUpdateDetails details) {
            game.handleScaleUpdate(
              localFocalPoint: details.localFocalPoint,
              focalPointDelta: details.focalPointDelta,
              scale: details.scale,
            );
          },
          child: GameWidget<SolvilleGame>(game: game),
        ),
      ),
    );
  }
}
