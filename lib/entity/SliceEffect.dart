import 'package:flutter/material.dart';

class SliceEffect {
  Offset position;
  String text;
  double opacity;
  double offsetY;
  
  SliceEffect(this.position, this.text, [this.opacity = 1.0, this.offsetY = 0]);
  
  void update() {
    opacity -= 0.02;
    offsetY -= 2;
  }
  
  bool get isDead => opacity <= 0;
}