import 'entity.dart';
import 'Sliceable.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../gamecontroller/game_controller.dart';

abstract class Item extends Entity implements Sliceable {
  GameController? gameController;

  @override
  bool isSliced = false;
  double radius;
  bool used = false;
  String? emoji;
  String? spritePath;
  double rotation = 0;
  double glow = 0;

  Item(this.gameController, Offset p, Offset v, this.radius, {this.emoji, this.spritePath})
      : super(p, v);

  @override
  void update() {
    position += velocity;
    velocity += const Offset(0, 0.5);
    rotation += 0.06;
    glow = sin(DateTime.now().millisecondsSinceEpoch / 300) * 0.5 + 0.5;
  }

  @override
  bool contains(Offset p) {
    return (p - position).distanceSquared <= radius * radius;
  }

  @override
  void slice();
}

class Bomb extends Item {
  Bomb(GameController gc, Offset p, Offset v) : super(gc, p, v, 28, emoji: "💣");

  @override
  void slice() {
    isSliced = true;
    used = true;
    gameController?.score = max(0, gameController!.score - 5);
    gameController?.lives--;
    gameController?.combo = 0;

    gameController?.onPlayBombSound?.call();
  }
}

class TimeItem extends Item {
  TimeItem(GameController gc, Offset p, Offset v) : super(gc, p, v, 24, emoji: "⏰");

  @override
  void slice() {
    isSliced = true;
    used = true;
    gameController?.timeLeft += 3;

    gameController?.onPlayItemSound?.call();
  }
}

class X2Item extends Item {
  X2Item(GameController gc, Offset p, Offset v) : super(gc, p, v, 24, emoji: "⭐");

  
  @override
  void slice() {
    isSliced = true;
    used = true;
    gameController?.x2Active = true;
    gameController?.x2Timer = 5.0;
    gameController?.onPlayItemSound?.call();
  }
}