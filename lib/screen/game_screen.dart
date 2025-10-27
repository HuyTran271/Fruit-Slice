import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../gamecontroller/game_controller.dart';
import 'start_screen.dart' as sc;
import '../gamepainter/game_painter.dart';
import '../entity/slice_effect.dart';
import '../extra/leaderboard.dart';
import '../entity/item.dart';
import '../responsive/responsive.dart';

class GameScreen extends StatefulWidget {
  final String difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  late GameController controller;
  late AnimationController ticker;
  Size? screenSize;
  int bestScore = 0;
  List<Offset> trail = [];
  List<SliceEffect> sliceEffects = [];
  String currentTrail = 'default';
  List<Color> trailColors = [Colors.red, Colors.yellow];
  int lastCombo = 0;
  
  bool showFlash = false;
  Timer? flashTimer;
  
  bool isSfxEnabled = true;
  bool isMusicEnabled = true;
  bool isVibrationEnabled = true;
  
  int _frameCounter = 0;
  static const int _uiUpdateInterval = 2;
  DateTime _lastHapticTime = DateTime.now();
  DateTime _lastSoundTime = DateTime.now();
  bool _isPaused = false;

  DeviceType _deviceType = DeviceType.mobile;
  
  // Audio players
  final Map<String, AudioPlayer> _audioPlayers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioPlayers();
    _loadSettings();
    _loadBest();
    _loadTrail();
    _setFullScreen();
    controller = GameController(widget.difficulty);
    
    // Set callback để kiểm soát sound từ GameScreen
    controller.onPlaySliceSound = () {
      if (isSfxEnabled) {
        _playSound('slice');
      }
    };
    controller.onPlayBombSound = () {
      if (isSfxEnabled) {
        _playSound('bomb');
      }
    };
    controller.onPlayItemSound = () {
      if (isSfxEnabled) {
        _playSound('item'); 
      }
    };
    
    ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onTick)
      ..repeat();
    controller.startTimer(_onTimeUp);
  }

  void _initAudioPlayers() {
    // Tạo pool audio players để tránh lag
    for (int i = 0; i < 5; i++) {
      _audioPlayers['slice_$i'] = AudioPlayer();
    }
    _audioPlayers['combo'] = AudioPlayer();
    _audioPlayers['bomb'] = AudioPlayer();
    _audioPlayers['item'] = AudioPlayer();
  }

  void _setFullScreen() {
    // Full screen cho Android/iOS
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detectDeviceType();
  }

  void _detectDeviceType() {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    
    if (kIsWeb) {
      if (size.width > 1200) {
        _deviceType = DeviceType.desktop;
      } else if (size.width > 600) {
        _deviceType = DeviceType.tablet;
      } else {
        _deviceType = DeviceType.mobile;
      }
    } else {
      if (shortestSide > 600) {
        _deviceType = DeviceType.tablet;
      } else {
        _deviceType = DeviceType.mobile;
      }
    }
  }

  void _onTick() {
    controller.update(screenSize);
    
    for (var effect in sliceEffects) {
      effect.update();
    }
    sliceEffects.removeWhere((e) => e.isDead);
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _playSound(String sound) async {
    if (!isSfxEnabled) return;
    
    // Throttle sounds
    final now = DateTime.now();
    if (now.difference(_lastSoundTime).inMilliseconds < 30) return;
    _lastSoundTime = now;
    
    try {
      if (sound == 'slice') {
        // Round-robin qua các slice players
        final index = _frameCounter % 5;
        final player = _audioPlayers['slice_$index']!;
        await player.stop();
        await player.play(AssetSource('sounds/slice.mp3'), volume: 0.5);
      } else if (sound == 'combo') {
        final player = _audioPlayers['combo']!;
        await player.stop();
        await player.play(AssetSource('sounds/combo.mp3'), volume: 0.6);
      } else if (sound == 'bomb') {
        final player = _audioPlayers['bomb']!;
        await player.stop();
        await player.play(AssetSource('sounds/bomb.mp3'), volume: 0.7);
      } else if (sound == 'item') {
        final player = _audioPlayers['item']!;
        await player.stop();
        await player.play(AssetSource('sounds/item.mp3'), volume: 0.6);
      }
    } catch (e) {
      // Ignore audio errors
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
        isMusicEnabled = prefs.getBool('music_enabled') ?? true;
        isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', isSfxEnabled);
    await prefs.setBool('music_enabled', isMusicEnabled);
    await prefs.setBool('vibration_enabled', isVibrationEnabled);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      if (!_isPaused) {
        _pauseGame(showDialog: true);
      }
    } else if (state == AppLifecycleState.resumed) {
      _setFullScreen();
    }
  }

  void _pauseGame({bool showDialog = true}) {
    if (_isPaused || !ticker.isAnimating) return;
    
    _isPaused = true;
    ticker.stop();
    controller.gameTimer?.cancel();
    controller.spawnTimer?.cancel();
    
    if (controller.fruits.length > 10) {
      controller.fruits.removeRange(0, controller.fruits.length - 10);
    }
    if (controller.items.length > 5) {
      controller.items.removeRange(0, controller.items.length - 5);
    }
    
    if (showDialog && mounted) {
      _showPauseDialog();
    }
  }

  void _resumeGame() {
    if (!_isPaused) return;
    
    _isPaused = false;
    _setFullScreen();
    ticker.repeat();
    controller.startSpawning();
    controller.startTimer(_onTimeUp);
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Column(
            children: [
              Text('⏸️', style: TextStyle(fontSize: 50)),
              SizedBox(height: 10),
              Text('Game Paused', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: const Text(
          'Tap Continue để chơi tiếp',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _resumeGame();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exitFullScreen();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const sc.StartScreen()),
              );
            },
            child: const Text('Quit to Menu'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    _pauseGame(showDialog: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Column(
              children: [
                Text('⚙️', style: TextStyle(fontSize: 50)),
                SizedBox(height: 10),
                Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('🎵 Background Music'),
                subtitle: Text(isMusicEnabled ? 'Enabled' : 'Disabled'),
                value: isMusicEnabled,
                activeColor: Colors.green,
                onChanged: (value) async {
                  setDialogState(() {
                    if (mounted) {
                      setState(() {
                        isMusicEnabled = value;
                      });
                    }
                  });
                  
                  await _saveSettings();
                  
                  if (value) {
                    await controller.audioManager.resumeBackgroundMusic();
                  } else {
                    await controller.audioManager.pauseBackgroundMusic();
                  }
                  
                  if (!kIsWeb && isVibrationEnabled) {
                    HapticFeedback.lightImpact();
                  }
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('🔊 Sound Effects'),
                subtitle: Text(isSfxEnabled ? 'Enabled' : 'Disabled'),
                value: isSfxEnabled,
                activeColor: Colors.green,
                onChanged: (value) async {
                  // Chỉ play sound khi ĐANG BẬT (từ false -> true)
                  if (value == true) {
                    // Phát âm thanh test trước khi update state
                    try {
                      final index = _frameCounter % 5;
                      final player = _audioPlayers['slice_$index']!;
                      await player.stop();
                      await player.play(AssetSource('sounds/slice.mp3'), volume: 0.5);
                    } catch (e) {
                      debugPrint('Audio error: $e');
                    }
                  }
                  
                  // Cập nhật state
                  setDialogState(() {
                    if (mounted) {
                      setState(() {
                        isSfxEnabled = value;
                      });
                    }
                  });
                  
                  // Lưu settings
                  await _saveSettings();
                  
                  if (!kIsWeb && isVibrationEnabled) {
                    HapticFeedback.lightImpact();
                  }
                },
              ),
              const Divider(),
              if (!kIsWeb)
                SwitchListTile(
                  title: const Text('📳 Vibration'),
                  subtitle: Text(isVibrationEnabled ? 'Enabled' : 'Disabled'),
                  value: isVibrationEnabled,
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    setDialogState(() {
                      if (mounted) {
                        setState(() {
                          isVibrationEnabled = value;
                        });
                      }
                    });
                    
                    await _saveSettings();
                    
                    if (value) {
                      HapticFeedback.mediumImpact();
                    }
                  },
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resumeGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resume Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exitFullScreen();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const sc.StartScreen()),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Quit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        bestScore = p.getInt('best_score_${widget.difficulty}') ?? 0;
        controller.bestScore = bestScore;
      });
    }
  }

  Future<void> _loadTrail() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        currentTrail = p.getString('current_trail') ?? 'default';
        switch (currentTrail) {
          case 'fire':
            trailColors = [Colors.orange, Colors.red];
            break;
          case 'ice':
            trailColors = [Colors.cyan, Colors.blue];
            break;
          case 'rainbow':
            trailColors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
            break;
          case 'lightning':
            trailColors = [Colors.yellow, Colors.white];
            break;
          case 'toxic':
            trailColors = [Colors.green, Colors.lime];
            break;
          default:
            trailColors = [Colors.red, Colors.yellow];
        }
      });
    }
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

  void _triggerFlash() {
    if (showFlash) return;
    
    if (mounted) {
      setState(() => showFlash = true);
    }
    flashTimer?.cancel();
    flashTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => showFlash = false);
    });
  }

  void _triggerHaptic() {
    if (kIsWeb) return;
    
    final now = DateTime.now();
    if (now.difference(_lastHapticTime).inMilliseconds < 50) return;
    
    _lastHapticTime = now;
    if (isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTimeUp() async {
    if (controller.score > bestScore) {
      bestScore = controller.score;
      _saveBest();
    }
    _addCoins(controller.score);

    final playerName = await LeaderboardManager.getPlayerName();
    await LeaderboardManager.saveScore(playerName, widget.difficulty, controller.score);

    if (!mounted) return;
    
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
              Text(
                controller.lives <= 0 ? 'Game Over!' : 'Time Up!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
              setState(() {
                controller.reset();
                _isPaused = false;
              });
              _setFullScreen();
              ticker.repeat();
              controller.startTimer(_onTimeUp);
            },
            icon: const Icon(Icons.replay),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exitFullScreen();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const sc.StartScreen()));
            },
            icon: const Icon(Icons.home),
            label: const Text('Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _exitFullScreen() {
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  @override
  void dispose() {
    _exitFullScreen();
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    controller.dispose();
    flashTimer?.cancel();
    
    // Dispose audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    controller.screenSize = screenSize;
    _detectDeviceType();

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    if (_deviceType == DeviceType.mobile) {
      // Mobile: Full screen, no container
      return _buildGameContent();
    } else {
      // Tablet/Desktop: Centered with max width
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: _deviceType == DeviceType.tablet ? 600.0 : 800.0,
            maxHeight: _deviceType == DeviceType.desktop ? 900.0 : double.infinity,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildGameContent(),
          ),
        ),
      );
    }
  }

  Widget _buildGameContent() {
    final difficultyColor = widget.difficulty == 'Easy' 
        ? Colors.green 
        : widget.difficulty == 'Hard' 
            ? Colors.red 
            : Colors.orange;

    return SafeArea(
      // Chỉ apply SafeArea cho mobile
      top: _deviceType == DeviceType.mobile,
      bottom: _deviceType == DeviceType.mobile,
      left: false,
      right: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (d) {
          if (_isPaused) return;
          trail.clear();
          trail.add(d.localPosition);
        },
        onPanUpdate: (d) {
          if (_isPaused) return;
          
          trail.add(d.localPosition);
          if (trail.length > 15) {
            trail.removeRange(0, trail.length - 15);
          }
          
          int prevScore = controller.score;
          int prevCombo = controller.combo;
          bool hitFruit = false;
          bool hitBomb = false;
          bool hitItem = false;

          // Check fruits
          for (final f in controller.fruits) {
            if (!f.isSliced && f.contains(d.localPosition)) {
              hitFruit = true;
              break;
            }
          }

          // Check items
          for (final item in controller.items) {
            if (!item.used) {
              final dx = d.localPosition.dx - item.position.dx;
              final dy = d.localPosition.dy - item.position.dy;
              final distance = sqrt(dx * dx + dy * dy);
              
              if (distance < 60) {
                hitItem = true;
                if (item is Bomb) {
                  hitBomb = true;
                }
                break;
              }
            }
          }

          // Execute slice
          controller.slice(d.localPosition);

          if (controller.combo != prevCombo) {
            debugPrint('🔥 Combo: ${controller.combo} (prev: $prevCombo)');
          }

          // Sound & haptic
          if (hitFruit) {
            _triggerHaptic();
            _triggerFlash();
          } else if (hitBomb) {
            if (!kIsWeb && isVibrationEnabled) {
              HapticFeedback.heavyImpact();
            }
            _triggerFlash();
          } else if (hitItem) {
            _triggerHaptic();
          }

          // Combo sound
          if (controller.combo > prevCombo && controller.combo > 2) {
            _playSound('combo');
          }

          // Slice effects
          if (controller.score > prevScore) {
            if (sliceEffects.length < 5) {
              sliceEffects.add(SliceEffect(d.localPosition, '+${controller.score - prevScore}'));
            }
          }
        },
        onPanEnd: (_) => trail.clear(),
        onPanCancel: () => trail.clear(),
        child: Stack(
          children: [
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
            
            if (showFlash)
              Container(color: Colors.white.withOpacity(0.15)),
            
            RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: GamePainter(controller, trail, sliceEffects, trailColors),
              ),
            ),

            _buildResponsiveUI(difficultyColor),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveUI(Color difficultyColor) {
    final ResponsiveConfig config = getResponsiveConfig(context);

    return Stack(
      children: [
        Positioned(
          top: config.topPadding,
          left: config.sidePadding,
          right: config.sidePadding + config.settingsButtonSize + 8,
          child: Container(
            padding: EdgeInsets.all(config.panelPadding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(config.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: config.badgePadding,
                          vertical: config.badgePadding * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.difficulty,
                          style: TextStyle(
                            fontSize: config.smallTextSize,
                            fontWeight: FontWeight.bold,
                            color: difficultyColor,
                          ),
                        ),
                      ),
                      SizedBox(height: config.spacing),
                      Text(
                        "🏆 ${controller.score}",
                        style: TextStyle(
                          fontSize: config.scoreFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Best: $bestScore",
                        style: TextStyle(
                          fontSize: config.smallTextSize,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: config.spacing),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: config.badgePadding,
                        vertical: config.badgePadding * 0.6,
                      ),
                      decoration: BoxDecoration(
                        color: controller.timeLeft <= 10
                            ? Colors.red.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "⏱️ ${controller.timeLeft}s",
                        style: TextStyle(
                          fontSize: config.timeFontSize,
                          fontWeight: FontWeight.bold,
                          color: controller.timeLeft <= 10 ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: config.spacing),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        controller.lives,
                        (i) => Padding(
                          padding: EdgeInsets.only(left: config.spacing * 0.5),
                          child: Text(
                            "❤️",
                            style: TextStyle(fontSize: config.heartSize),
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

        Positioned(
          top: config.topPadding,
          right: config.sidePadding,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showSettingsDialog,
              borderRadius: BorderRadius.circular(config.settingsButtonSize / 2),
              child: Container(
                width: config.settingsButtonSize,
                height: config.settingsButtonSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.black87,
                  size: config.iconSize,
                ),
              ),
            ),
          ),
        ),

        if (controller.x2Active)
          Positioned(
            top: config.topPadding + config.settingsButtonSize + 16,
            right: config.sidePadding,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: config.badgePadding,
                vertical: config.badgePadding * 0.7,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "⭐",
                    style: TextStyle(fontSize: config.timeFontSize),
                  ),
                  SizedBox(width: config.spacing * 0.7),
                  Text(
                    "X2",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: config.timeFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (controller.combo > 2)
          Positioned(
            top: config.comboTop,
            left: config.sidePadding,
            right: config.sidePadding,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: config.badgePadding * 1.5,
                  vertical: config.badgePadding,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.yellow.shade600, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Text(
                  "🔥 COMBO x${controller.combo}",
                  style: TextStyle(
                    fontSize: config.comboFontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}