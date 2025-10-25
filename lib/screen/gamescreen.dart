import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../gamecontroller/GameController.dart';
import '../screen/startscreen.dart';
import '../gamepainter/GamePainter.dart';
import '../entity/SliceEffect.dart';
import '../extra/leaderboard.dart';
import '../extra/audiomanager.dart';
import '../entity/Item.dart';
import '../reponsive/reponsive.dart';

class GameScreen extends StatefulWidget {
  final String difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameController controller;
  late AnimationController ticker;
  Size? screenSize;
  int bestScore = 0;
  List<Offset> trail = [];
  List<SliceEffect> sliceEffects = [];
  String currentTrail = 'default';
  List<Color> trailColors = [Colors.red, Colors.yellow];
  final audioManager = AudioManager();
  int lastCombo = 0;

  @override
  void initState() {
    super.initState();
    audioManager.init();
    _loadBest();
    _loadTrail();
    controller = GameController(widget.difficulty);
    ticker = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() {
        setState(() {
          controller.update(screenSize);
          
          if (controller.combo > lastCombo && controller.combo > 2) {
            audioManager.playComboSound();
          }
          lastCombo = controller.combo;
          
          for (var effect in sliceEffects) {
            effect.update();
          }
          sliceEffects.removeWhere((e) => e.isDead);
        });
      })
      ..repeat();
    controller.startTimer(_onTimeUp);
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      bestScore = p.getInt('best_score_${widget.difficulty}') ?? 0;
      controller.bestScore = bestScore;
    });
  }

  Future<void> _loadTrail() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      currentTrail = p.getString('current_trail') ?? 'default';
      switch (currentTrail) {
        case 'fire': trailColors = [Colors.orange, Colors.red]; break;
        case 'ice': trailColors = [Colors.cyan, Colors.blue]; break;
        case 'rainbow': trailColors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple]; break;
        case 'lightning': trailColors = [Colors.yellow, Colors.white]; break;
        case 'toxic': trailColors = [Colors.green, Colors.lime]; break;
        default: trailColors = [Colors.red, Colors.yellow];
      }
    });
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('best_score_${widget.difficulty}', bestScore);
  }
  
  Future<void> _addCoins(int amount) async {
    final p = await SharedPreferences.getInstance();
    final currentCoins = p.getInt('coins') ?? 0;
    await p.setInt('coins', currentCoins + amount);
  }

  void _onTimeUp() async {
    if (controller.score > bestScore) {
      bestScore = controller.score;
      _saveBest();
    }
    _addCoins(controller.score);
    
    final playerName = await LeaderboardManager.getPlayerName();
    await LeaderboardManager.saveScore(playerName, widget.difficulty, controller.score);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Center(
          child: Column(
            children: [
              const Text('⏰', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 10),
              Text(controller.lives <= 0 ? 'Game Over!' : 'Time Up!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.blue.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆 Score: ${controller.score}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('🪙 +${controller.score} coins earned!', style: const TextStyle(fontSize: 18, color: Colors.amber)),
              const SizedBox(height: 12),
              Text('⭐ Best (${widget.difficulty}): $bestScore', style: const TextStyle(fontSize: 20, color: Colors.black87)),
              if (controller.maxCombo > 3) ...[
                const SizedBox(height: 8),
                Text('🔥 Max Combo: ${controller.maxCombo}', style: const TextStyle(fontSize: 18, color: Colors.orange)),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() => controller.reset());
              controller.startTimer(_onTimeUp);
            },
            icon: const Icon(Icons.replay),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StartScreen()));
            },
            icon: const Icon(Icons.home),
            label: const Text('Home'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
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
    Responsive.init(context);
    screenSize = MediaQuery.of(context).size;
    controller.screenSize = screenSize;

    Color difficultyColor = widget.difficulty == 'Easy' ? Colors.green : widget.difficulty == 'Hard' ? Colors.red : Colors.orange;
    
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (d) {
          int prevScore = controller.score;
          bool hitFruit = false;
          bool hitBomb = false;
          
          for (final f in controller.fruits) {
            if (!f.isSliced && f.contains(d.localPosition)) {
              hitFruit = true;
              break;
            }
          }
          
          for (final it in controller.items) {
            if (!it.used && it.containsPoint(d.localPosition)) {
              if (it is Bomb) {
                hitBomb = true;
              }
              break;
            }
          }
          
          controller.slice(d.localPosition);
          
          if (hitFruit) {
            audioManager.playSliceSound();
          } else if (hitBomb) {
            audioManager.playBombSound();
          }
          
          if (controller.score > prevScore) {
            sliceEffects.add(SliceEffect(d.localPosition, '+${controller.score - prevScore}'));
          }
          
          setState(() {
            trail.add(d.localPosition);
            if (trail.length > 25) trail.removeAt(0);
          });
        },
        onPanEnd: (_) => setState(() => trail.clear()),
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: controller.x2Active
                      ? [Colors.orange.shade300, Colors.deepOrange.shade400]
                      : [Colors.lightBlue.shade200, Colors.green.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Game Canvas với kích thước responsive
            CustomPaint(
              size: Size(Responsive.screenWidth, Responsive.screenHeight),
              painter: GamePainter(
                controller,
                trail,
                sliceEffects,
                trailColors,
                devicePixelRatio: Responsive.devicePixelRatio,
              ),
            ),

            // Score Panel
            Positioned(
              top: Responsive.hp(4), // 4% chiều cao màn hình
              left: Responsive.wp(4), // 4% chiều rộng màn hình
              right: Responsive.wp(4),
              child: Container(
                padding: EdgeInsets.all(Responsive.wp(3)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(Responsive.radius(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: Responsive.radius(10),
                      offset: Offset(0, Responsive.hp(0.5)),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Score Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Score: ${controller.score}",
                            style: TextStyle(
                              fontSize: Responsive.fontSize(24),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Best: $bestScore",
                            style: TextStyle(
                              fontSize: Responsive.fontSize(16),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Timer Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.wp(3),
                            vertical: Responsive.hp(1),
                          ),
                          decoration: BoxDecoration(
                            color: controller.timeLeft <= 10
                                ? Colors.red.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Responsive.radius(10)),
                          ),
                          child: Text(
                            "${controller.timeLeft}s",
                            style: TextStyle(
                              fontSize: Responsive.fontSize(20),
                              fontWeight: FontWeight.bold,
                              color: controller.timeLeft <= 10 ? Colors.red : Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.hp(1)),
                        Row(
                          children: List.generate(
                            controller.lives,
                            (i) => Padding(
                              padding: EdgeInsets.only(left: Responsive.wp(1)),
                              child: Text(
                                "❤️",
                                style: TextStyle(fontSize: Responsive.fontSize(20)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Combo Indicator
            if (controller.combo > 2)
              Positioned(
                top: Responsive.hp(20),
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.wp(5),
                      vertical: Responsive.hp(1.5),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.yellow.shade600, Colors.orange.shade500],
                      ),
                      borderRadius: BorderRadius.circular(Responsive.radius(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: Responsive.radius(15),
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Text(
                      "COMBO x${controller.combo}",
                      style: TextStyle(
                        fontSize: Responsive.fontSize(28),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}