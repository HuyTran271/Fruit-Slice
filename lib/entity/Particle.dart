import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  double life;
  Color color;
  double size;

  Particle(this.position, this.velocity, {this.life = 1.0, this.color = Colors.white, this.size = 3});

  void update() {
    position += velocity;
    velocity += const Offset(0, 0.2);
    life -= 0.015;
    size *= 0.98;
  }

  bool get isDead => life <= 0;
}