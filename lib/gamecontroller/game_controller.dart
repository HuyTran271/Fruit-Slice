import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../extra/audio_manager.dart';
import '../entity/fruit.dart';
import '../entity/item.dart';

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
  AudioManager audioManager = AudioManager();

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

  // Callbacks để GameScreen kiểm soát sound
  VoidCallback? onPlaySliceSound;
  VoidCallback? onPlayBombSound;
  VoidCallback? onPlayItemSound;

  GameController(this.difficulty) {
    if (difficulty == 'Easy') {
      spawnMs = 1000;
      speedMultiplier = 0.85;
      itemChance = 0.18;
      timeLeft = 60;
      lives = 5;
    } else if (difficulty == 'Hard') {
      spawnMs = 650;
      speedMultiplier = 1.15;
      itemChance = 0.26;
      timeLeft = 30;
      lives = 2;
    } else {
      spawnMs = 850;
      speedMultiplier = 1.0;
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
    
    // Spawn position: 20% từ bottom để tránh quá thấp
    final spawnY = h * 0.8;
    
    // X position: Spawn từ edges với margin 40px
    final x = 40 + rnd.nextDouble() * (w - 80);
    
    // Velocity được điều chỉnh dựa trên màn hình
    final screenHeightRatio = (h / 800).clamp(0.8, 1.5);
    
    // Base velocity - tăng theo chiều cao màn hình
    final baseVelocityY = -15.0 * speedMultiplier * screenHeightRatio;
    final velocityVariation = rnd.nextDouble() * 6; // Random 0-6
    final finalVelocityY = baseVelocityY - velocityVariation;
    
    // Horizontal velocity - nhẹ hơn để dễ chém
    final velocityX = (rnd.nextDouble() * 3 - 1.5) * speedMultiplier;
    
    final vel = Offset(velocityX, finalVelocityY);

    if (rnd.nextDouble() < 0.78) {
      // Spawn fruits
      int t = rnd.nextInt(6);
      if (t == 0) fruits.add(Apple(Offset(x, spawnY), vel));
      if (t == 1) fruits.add(Pear(Offset(x, spawnY), vel));
      if (t == 2) fruits.add(Orange(Offset(x, spawnY), vel));
      if (t == 3) fruits.add(Lemon(Offset(x, spawnY), vel));
      if (t == 4) fruits.add(Watermelon(Offset(x, spawnY), vel));
      if (t == 5) fruits.add(Strawberry(Offset(x, spawnY), vel));
    } else {
      // Spawn items
      int t = rnd.nextInt(3);
      if (t == 0) items.add(Bomb(Offset(x, spawnY), vel));
      if (t == 1) items.add(TimeItem(Offset(x, spawnY), vel));
      if (t == 2) items.add(X2Item(Offset(x, spawnY), vel));
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

    final fruitsCopy = List<Fruit>.from(fruits);
    final itemsCopy = List<Item>.from(items);

    for (final f in fruitsCopy) {
      f.update();
    }
    for (final it in itemsCopy) {
      it.update();
    }

    final h = screenSize?.height ?? 800;

    // Remove entities that fall below screen or are sliced
    fruits.removeWhere((f) => f.position.dy > h + 100 || f.isSliced);
    items.removeWhere((i) => i.position.dy > h + 100 || i.used);
    
    // Limit entities to prevent lag
    if (fruits.length > 20) {
      fruits.removeRange(0, fruits.length - 20);
    }
    if (items.length > 10) {
      items.removeRange(0, items.length - 10);
    }

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
        
        // Gọi callback thay vì gọi trực tiếp audioManager
        onPlaySliceSound?.call();
        
        if (score > bestScore) bestScore = score;
      }
    }
    
    if (!hitAny) combo = 0;
    
    for (final it in items) {
      if (!it.used && it.contains(p)) {
        it.used = true;
        if (it is Bomb) {
          score = max(0, score - 5);
          lives--;
          combo = 0;
          
          // Gọi callback thay vì gọi trực tiếp audioManager
          onPlayBombSound?.call();
        } else if (it is TimeItem) {
          timeLeft += 3;
          
          // Gọi callback thay vì gọi trực tiếp audioManager
          onPlayItemSound?.call();
        } else if (it is X2Item) {
          x2Active = true;
          x2Timer = 5.0;
          
          // Gọi callback thay vì gọi trực tiếp audioManager
          onPlayItemSound?.call();
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