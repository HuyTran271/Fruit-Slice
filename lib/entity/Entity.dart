import 'package:flutter/material.dart';

abstract class Entity {
  Offset position;
  Offset velocity;

  Entity(this.position, this.velocity);

  void update();
  bool contains(Offset p);
}