import 'dart:math';
import 'package:flutter/material.dart';
import 'entity.dart';
import 'Sliceable.dart';

class Fruit extends Entity implements Sliceable {
  @override
  bool isSliced = false;
  double radius;
  int points;
  String? emoji;
  String? spritePath;
  double rotation = 0;
  double scale = 1.0;

  Fruit(Offset p, Offset v, this.radius, this.points, {this.emoji, this.spritePath}) : super(p, v);

  @override
  void update() {
    position += velocity;
    velocity += const Offset(0, 0.5);
    rotation += 0.08;
    scale = 1.0 + sin(DateTime.now().millisecondsSinceEpoch / 200) * 0.05;
  }

  @override
  bool contains(Offset p) {
    return (p - position).distanceSquared <= radius * radius;
  }

  @override
  void slice() {
    isSliced = true;
  }
}

class Apple extends Fruit {
  Apple(Offset p, Offset v) : super(p, v, 28, 1, emoji: "🍎");
}

class Pear extends Fruit {
  Pear(Offset p, Offset v) : super(p, v, 30, 2, emoji: "🍐");
}

class Orange extends Fruit {
  Orange(Offset p, Offset v) : super(p, v, 32, 2, emoji: "🍊");
}

class Lemon extends Fruit {
  Lemon(Offset p, Offset v) : super(p, v, 26, 2, emoji: "🍋");
}

class Watermelon extends Fruit {
  Watermelon(Offset p, Offset v) : super(p, v, 40, 5, emoji: "🍉");
}

class Strawberry extends Fruit {
  Strawberry(Offset p, Offset v) : super(p, v, 22, 3, emoji: "🍓");
}