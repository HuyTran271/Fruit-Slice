import 'package:flutter/material.dart';

class AnimatedFruit {
  Offset position;
  Offset velocity;
  String emoji;
  double rotation;

  AnimatedFruit(this.position, this.velocity, this.emoji, [this.rotation = 0]);
}