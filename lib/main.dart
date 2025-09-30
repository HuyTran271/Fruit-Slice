import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FruitSliceApp());

class FruitSliceApp extends StatelessWidget {
  const FruitSliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}

/// ======================== START SCREEN WITH ANIMATION ========================
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController ticker;
  final List<AnimatedFruit> fruits = [];
  final Random rnd = Random();
  Timer? spawnTimer;

  @override
  void initState() {
    super.initState();
    ticker = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() => setState(() => _updateFruits()))
      ..repeat();

    spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _spawnFruit();
    });
  }

  void _spawnFruit() {
    final size = MediaQuery.of(context).size;
    final x = 40 + rnd.nextDouble() * (size.width - 80);
    final vel = Offset(rnd.nextDouble() * 2 - 1, -12 - rnd.nextDouble() * 4);
    int t = rnd.nextInt(6);
    String emoji = ["🍎", "🍐", "🍊", "🍋", "🍉", "🍓"][t];
    fruits.add(AnimatedFruit(Offset(x, size.height), vel, emoji));
  }

  void _updateFruits() {
    final size = MediaQuery.of(context).size;
    for (var f in fruits) {
      f.position += f.velocity;
      f.velocity += const Offset(0, 0.3);
      f.rotation += 0.05;
    }
    fruits.removeWhere((f) => f.position.dy > size.height + 100 || f.position.dy < -100);
  }

  @override
  void dispose() {
    ticker.dispose();
    spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: StartScreenPainter(fruits),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "🍉 Fruit Slice 🍓",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          blurRadius: 6,
                          color: Colors.black45,
                          offset: Offset(2, 2))
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DifficultyScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 70, vertical: 20),
                    textStyle: const TextStyle(fontSize: 22),
                    elevation: 6,
                  ),
                  child: const Text("START"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedFruit {
  Offset position;
  Offset velocity;
  String emoji;
  double rotation;

  AnimatedFruit(this.position, this.velocity, this.emoji, [this.rotation = 0]);
}

class StartScreenPainter extends CustomPainter {
  final List<AnimatedFruit> fruits;
  StartScreenPainter(this.fruits);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in fruits) {
      canvas.save();
      canvas.translate(f.position.dx, f.position.dy);
      canvas.rotate(f.rotation);
      final tp = TextPainter(
        text: TextSpan(text: f.emoji, style: const TextStyle(fontSize: 40)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// ======================== DIFFICULTY SCREEN ========================
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepPurpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Chọn độ khó",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                      blurRadius: 6,
                      color: Colors.black45,
                      offset: Offset(2, 2))
                ],
              ),
            ),
            const SizedBox(height: 50),
            _buildDifficultyButton(context, "Easy"),
            const SizedBox(height: 20),
            _buildDifficultyButton(context, "Normal"),
            const SizedBox(height: 20),
            _buildDifficultyButton(context, "Hard"),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String text) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(difficulty: text),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
        textStyle: const TextStyle(fontSize: 20),
        elevation: 6,
      ),
      child: Text(text),
    );
  }
}

/// ======================== GAME SCREEN ========================
class GameScreen extends StatefulWidget {
  final String difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameController controller;
  late AnimationController ticker;
  Size? screenSize;
  int bestScore = 0;
  List<Offset> trail = [];

  @override
  void initState() {
    super.initState();
    controller = GameController(widget.difficulty);
    _loadBest();
    ticker = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() => setState(() => controller.update(screenSize)))
      ..repeat();
    controller.startTimer(_onTimeUp);
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    setState(() =>
        bestScore = p.getInt('best_score_${widget.difficulty}') ?? 0);
    controller.bestScore = bestScore;
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('best_score_${widget.difficulty}', bestScore);
  }

  void _onTimeUp() {
    if (controller.score > bestScore) {
      bestScore = controller.score;
      _saveBest();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text('⏰ Time Up',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: ${controller.score}',
                style: const TextStyle(fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Best (${widget.difficulty}): $bestScore',
                style: const TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => controller.reset());
                controller.startTimer(_onTimeUp);
              },
              child: const Text('Play Again')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StartScreen()),
                );
              },
              child: const Text('Return')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ticker.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    controller.screenSize = screenSize;
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (d) {
          controller.slice(d.localPosition);
          setState(() {
            trail.add(d.localPosition);
            if (trail.length > 20) trail.removeAt(0);
          });
        },
        onPanEnd: (_) => setState(() => trail.clear()),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
                size: screenSize!, painter: GamePainter(controller, trail)),
            Positioned(
              top: 30,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Mode: ${widget.difficulty}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Score: ${controller.score}",
                              style: const TextStyle(fontSize: 18)),
                          Text("Best: $bestScore",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                        ]),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Time: ${controller.timeLeft}",
                            style: TextStyle(
                                fontSize: 18,
                                color: controller.timeLeft <= 10
                                    ? Colors.red
                                    : Colors.black)),
                        Text("Lives: ${controller.lives}",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// ======================== ENTITIES (CONCRETE CLASSES) ========================
class Entity {
  Offset position;
  Offset velocity;
  Entity(this.position, this.velocity);

  void update() {
    position += velocity;
    velocity += const Offset(0, 0.3);
  }

  bool contains(Offset p, double r) => (position - p).distance <= r;
}

class Fruit extends Entity {
  double radius;
  bool isSliced = false;
  int points;
  String? emoji;
  String? spritePath;  // Đường dẫn đến sprite image

  Fruit(Offset p, Offset v, this.radius, this.points, {this.emoji, this.spritePath})
      : super(p, v);
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

class Item extends Entity {
  double radius;
  bool used = false;
  String? emoji;
  String? spritePath;

  Item(Offset p, Offset v, this.radius, {this.emoji, this.spritePath}) : super(p, v);

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

/// ======================== GAME CONTROLLER ========================
class GameController {
  int score = 0;
  int lives = 3;
  bool x2Active = false;
  double x2Timer = 0;
  int timeLeft = 45;
  int bestScore = 0;

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
      speedMultiplier = 0.9;
      itemChance = 0.18;
      timeLeft = 60;
      lives = 5;
    } else if (difficulty == 'Hard') {
      spawnMs = 600;
      speedMultiplier = 1.4;
      itemChance = 0.26;
      timeLeft = 30;
      lives = 2;
    } else {
      spawnMs = 800;
      speedMultiplier = 1.05;
      itemChance = 0.22;
      timeLeft = 45;
      lives = 3;
    }
    startSpawning();
  }

  void startSpawning() {
    spawnTimer?.cancel();
    spawnTimer =
        Timer.periodic(Duration(milliseconds: spawnMs), (_) => spawnEntity());
  }

  void spawnEntity() {
    final w = screenSize?.width ?? 400;
    final h = screenSize?.height ?? 700;
    final x = 40 + rnd.nextDouble() * (w - 80);
    final vel = Offset(rnd.nextDouble() * 2 - 1,
        (-11 - rnd.nextDouble() * 6) * speedMultiplier);

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
  }

  void slice(Offset p) {
    for (final f in fruits) {
      if (!f.isSliced && f.contains(p, f.radius)) {
        f.isSliced = true;
        score += x2Active ? f.points * 2 : f.points;
        if (score > bestScore) bestScore = score;
      }
    }
    for (final it in items) {
      if (!it.used && it.containsPoint(p)) {
        it.used = true;
        if (it is Bomb) {
          score = max(0, score - 5);
          lives--;
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

/// ======================== PAINTER ========================
class GamePainter extends CustomPainter {
  final GameController c;
  final List<Offset> trail;
  GamePainter(this.c, this.trail);

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ trái cây (hiện tại dùng emoji, có thể thay bằng sprite)
    for (final f in c.fruits) {
      // TODO: Nếu có sprite, dùng canvas.drawImage()
      // Hiện tại dùng emoji
      if (f.emoji != null) {
        final tp = TextPainter(
          text: TextSpan(text: f.emoji, style: TextStyle(fontSize: f.radius * 2)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, f.position - Offset(f.radius, f.radius));
      }
    }

    // Vẽ item
    for (final it in c.items) {
      if (it.emoji != null) {
        final tp = TextPainter(
          text:
              TextSpan(text: it.emoji, style: TextStyle(fontSize: it.radius * 2)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, it.position - Offset(it.radius, it.radius));
      }
    }

    // Vẽ đường chém
    if (trail.isNotEmpty) {
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.6)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(trail.first.dx, trail.first.dy);
      for (var p in trail.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}