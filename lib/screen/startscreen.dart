import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../entity/AnimatedFruit.dart';
import 'difficultscreen.dart';
import '../extra/audiomanager.dart';
import '../extra/leaderboard.dart';
import 'leaderboardscreen.dart';


class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController ticker;
  final List<AnimatedFruit> fruits = [];
  final List<StarParticle> stars = [];
  final Random rnd = Random();
  Timer? spawnTimer;
  final audioManager = AudioManager();

  @override
  void initState() {
    super.initState();
    audioManager.init();
    
    for (int i = 0; i < 30; i++) {
      stars.add(StarParticle(
        Offset(rnd.nextDouble() * 400, rnd.nextDouble() * 800),
        rnd.nextDouble() * 0.5 + 0.5,
      ));
    }
    
    ticker = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() => setState(() => _updateFruits()))
      ..repeat();

    spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (_) => _spawnFruit());
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
    
    for (var s in stars) {
      s.opacity = 0.3 + sin(DateTime.now().millisecondsSinceEpoch / 1000 + s.offset) * 0.3;
    }
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
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          CustomPaint(size: Size.infinite, painter: StarPainter(stars)),
          CustomPaint(size: Size.infinite, painter: StartScreenPainter(fruits)),
          
          // Leaderboard & Shop buttons
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) => Transform.scale(scale: value, child: child),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.leaderboard, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) => Transform.scale(scale: value, child: child),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: const Text(
                          "🍉 Fruit Slice 🍓",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.pinkAccent, offset: Offset(0, 0)),
                              Shadow(blurRadius: 20, color: Colors.orangeAccent, offset: Offset(0, 0)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.bounceOut,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 100),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DifficultyScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      elevation: 10,
                      shadowColor: Colors.pinkAccent,
                    ),
                    child: const Text("START"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StarParticle {
  Offset position;
  double opacity;
  double offset;
  StarParticle(this.position, this.offset, [this.opacity = 1.0]);
}

class StarPainter extends CustomPainter {
  final List<StarParticle> stars;
  StarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(s.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(s.position, 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
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

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int coins = 0;
  String currentTrail = 'default';
  List<String> ownedTrails = ['default'];

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('coins') ?? 0;
      currentTrail = prefs.getString('current_trail') ?? 'default';
      ownedTrails = prefs.getStringList('owned_trails') ?? ['default'];
    });
  }

  Future<void> _saveShopData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', coins);
    await prefs.setString('current_trail', currentTrail);
    await prefs.setStringList('owned_trails', ownedTrails);
  }

  void _buyTrail(String trailId, int price) {
    if (coins >= price && !ownedTrails.contains(trailId)) {
      setState(() {
        coins -= price;
        ownedTrails.add(trailId);
        currentTrail = trailId;
      });
      _saveShopData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Trail purchased!')));
    }
  }

  void _equipTrail(String trailId) {
    setState(() => currentTrail = trailId);
    _saveShopData();
  }

  @override
  Widget build(BuildContext context) {
    final trails = [
      {'id': 'default', 'name': 'Classic', 'price': 0, 'colors': [Colors.red, Colors.yellow]},
      {'id': 'fire', 'name': 'Fire', 'price': 1000, 'colors': [Colors.orange, Colors.red]},
      {'id': 'ice', 'name': 'Ice', 'price': 1500, 'colors': [Colors.cyan, Colors.blue]},
      {'id': 'rainbow', 'name': 'Rainbow', 'price': 2000, 'colors': [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple]},
      {'id': 'lightning', 'name': 'Lightning', 'price': 2500, 'colors': [Colors.yellow, Colors.white]},
      {'id': 'toxic', 'name': 'Toxic', 'price': 3000, 'colors': [Colors.green, Colors.lime]},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4a148c), Color(0xFF6a1b9a), Color(0xFF8e24aa)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                    const Expanded(child: Text('🛍️ Shop', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text('$coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.all(20), child: Text('🎨 Trail Skins', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85),
                  itemCount: trails.length,
                  itemBuilder: (context, index) {
                    final trail = trails[index];
                    final isOwned = ownedTrails.contains(trail['id']);
                    final isEquipped = currentTrail == trail['id'];
                    
                    return GestureDetector(
                      onTap: () {
                        if (isOwned) {
                          _equipTrail(trail['id'] as String);
                        } else {
                          _buyTrail(trail['id'] as String, trail['price'] as int);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isEquipped ? Colors.greenAccent : Colors.white.withOpacity(0.3), width: isEquipped ? 3 : 2),
                          boxShadow: isEquipped ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(colors: (trail['colors'] as List<Color>), begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              child: CustomPaint(painter: TrailPreviewPainter(trail['colors'] as List<Color>)),
                            ),
                            const SizedBox(height: 12),
                            Text(trail['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            if (isEquipped)
                              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(20)), child: const Text('✓ Equipped', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)))
                            else if (isOwned)
                              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)), child: const Text('Tap to Equip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)))
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🪙', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text('${trail['price']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.3))),
                  child: const Text('💡 Earn coins by playing games!\n1 point = 1 coin', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class TrailPreviewPainter extends CustomPainter {
  final List<Color> colors;
  TrailPreviewPainter(this.colors);
  
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(10, size.height / 2)
      ..quadraticBezierTo(size.width / 3, 10, size.width * 2 / 3, size.height / 2)
      ..quadraticBezierTo(size.width, size.height - 10, size.width - 10, size.height / 2);
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    if (colors.length > 1) {
      paint.shader = LinearGradient(colors: colors).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = colors.first;
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}