import 'Entity.dart';
import 'Sliceable.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class Item extends Entity implements Sliceable {
  @override
  bool isSliced = false;
  double radius;
  bool used = false;
  String? emoji;
  String? spritePath;
  double rotation = 0;
  double glow = 0;

  Item(Offset p, Offset v, this.radius, {this.emoji, this.spritePath}) : super(p, v);

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
  void slice() {
    isSliced = true;
    used = true;
  }

  bool containsPoint(Offset pt) => (position - pt).distance <= radius;
}

class Bomb extends Item {
  Bomb(Offset p, Offset v) : super(p, v, 28, emoji: "💣");
}

class TimeItem extends Item {
  TimeItem(Offset p, Offset v) : super(p, v, 24, emoji: "⏰");
}

class X2Item extends Item {
  X2Item(Offset p, Offset v) : super(p, v, 24, emoji: "⭐");
}