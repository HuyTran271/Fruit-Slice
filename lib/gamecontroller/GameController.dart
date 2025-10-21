import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../entity/Fruit.dart';
import '../entity/Item.dart';

class GameController {
  int score = 0;
  int lives = 3;
  bool x2Active = false;
  double x2Timer = 0;
  int timeLeft = 45;
  int bestScore = 0;
  int combo = 0;
  int maxCombo = 0;
  double comboTimer = 0;

  final List<Fruit> fruits = [];
  final List<Item> items = [];
  final Random rnd = Random();
  Timer? spawnTimer;
  Timer? gameTimer;
  Size? screenSize;

  final String difficulty;
  late int spawnMs;
  late double speedMultiplier;
  late double itemChance;

  GameController(this.difficulty) {
    if (difficulty == 'Easy') {
      spawnMs = 1000;
      speedMultiplier = 0.8;
      itemChance = 0.18;
      timeLeft = 60;
      lives = 5;
    } else if (difficulty == 'Hard') {
      spawnMs = 600;
      speedMultiplier = 1.2;
      itemChance = 0.26;
      timeLeft = 30;
      lives = 2;
    } else {
      spawnMs = 800;
      speedMultiplier = 0.95;
      itemChance = 0.22;
      timeLeft = 45;
      lives = 3;
    }
    startSpawning();
  }

  void startSpawning() {
    spawnTimer?.cancel();
    spawnTimer = Timer.periodic(Duration(milliseconds: spawnMs), (_) => spawnEntity());
  }

  void spawnEntity() {
    final w = screenSize?.width ?? 400;
    final h = screenSize?.height ?? 700;
    final x = 40 + rnd.nextDouble() * (w - 80);
    final vel = Offset(rnd.nextDouble() * 2 - 1, (-18 - rnd.nextDouble() * 8) * speedMultiplier);

    if (rnd.nextDouble() < 0.78) {
      int t = rnd.nextInt(6);
      if (t == 0) fruits.add(Apple(Offset(x, h), vel));
      if (t == 1) fruits.add(Pear(Offset(x, h), vel));
      if (t == 2) fruits.add(Orange(Offset(x, h), vel));
      if (t == 3) fruits.add(Lemon(Offset(x, h), vel));
      if (t == 4) fruits.add(Watermelon(Offset(x, h), vel));
      if (t == 5) fruits.add(Strawberry(Offset(x, h), vel));
    } else {
      int t = rnd.nextInt(3);
      if (t == 0) items.add(Bomb(Offset(x, h), vel));
      if (t == 1) items.add(TimeItem(Offset(x, h), vel));
      if (t == 2) items.add(X2Item(Offset(x, h), vel));
    }
  }

  void startTimer(VoidCallback onTimeUp) {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      timeLeft--;
      if (timeLeft <= 0 || lives <= 0) {
        gameTimer?.cancel();
        onTimeUp();
      }
    });
  }

  void update([Size? s]) {
    if (s != null) screenSize = s;
    for (final f in List<Fruit>.from(fruits)) f.update();
    for (final it in List<Item>.from(items)) it.update();

    final h = screenSize?.height ?? 800;
    fruits.removeWhere((f) => f.position.dy > h + 60 || f.isSliced);
    items.removeWhere((i) => i.position.dy > h + 60 || i.used);

    if (x2Active) {
      x2Timer -= 0.016;
      if (x2Timer <= 0) x2Active = false;
    }

    if (comboTimer > 0) {
      comboTimer -= 0.016;
      if (comboTimer <= 0) combo = 0;
    }
  }

  void slice(Offset p) {
    bool hitAny = false;
    
    for (final f in fruits) {
      if (!f.isSliced && f.contains(p)) {
        f.slice();
        hitAny = true;
        combo++;
        if (combo > maxCombo) maxCombo = combo;
        comboTimer = 1.5;
        
        int pts = x2Active ? f.points * 2 : f.points;
        if (combo > 2) {
          pts = (pts * (1 + combo * 0.1)).round();
        }
        score += pts;
        if (score > bestScore) bestScore = score;
      }
    }
    
    if (!hitAny) combo = 0;
    
    for (final it in items) {
      if (!it.used && it.containsPoint(p)) {
        it.used = true;
        if (it is Bomb) {
          score = max(0, score - 5);
          lives--;
          combo = 0;
        } else if (it is TimeItem) {
          timeLeft += 3;
        } else if (it is X2Item) {
          x2Active = true;
          x2Timer = 5.0;
        }
      }
    }
  }

  void reset() {
    score = 0;
    x2Active = false;
    x2Timer = 0;
    combo = 0;
    maxCombo = 0;
    comboTimer = 0;
    fruits.clear();
    items.clear();
    if (difficulty == 'Easy') {
      timeLeft = 60;
      lives = 5;
    } else if (difficulty == 'Hard') {
      timeLeft = 30;
      lives = 2;
    } else {
      timeLeft = 45;
      lives = 3;
    }
  }

  void dispose() {
    spawnTimer?.cancel();
    gameTimer?.cancel();
  }
}