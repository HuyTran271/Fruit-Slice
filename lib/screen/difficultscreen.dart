import 'dart:async';
import 'package:flutter/material.dart';
import '../extra/leaderboard.dart';
import '../extra/audiomanager.dart';
import '../responsive/responsive.dart'; // ✅ dùng responsive chung
import 'gamescreen.dart';

class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({super.key});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  String playerName = 'Player';
  final AudioManager audioManager = AudioManager();

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final name = await LeaderboardManager.getPlayerName();
    setState(() => playerName = name);
  }

  Future<void> _showNameInputDialog(String difficulty) async {
    final controller = TextEditingController(text: playerName);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Text(_getDifficultyEmoji(difficulty),
                style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text(
              'Ready to play $difficulty?',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your name:',
                style: TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Player Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                      BorderSide(color: _getDifficultyColor(difficulty)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                      color: _getDifficultyColor(difficulty), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLength: 15,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getDifficultyColor(difficulty).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getDifficultyInfo(difficulty),
                style: TextStyle(
                  fontSize: 14,
                  color: _getDifficultyColor(difficulty),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              audioManager.playBackgroundMusic();
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getDifficultyColor(difficulty),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text('Start Game',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      await LeaderboardManager.savePlayerName(controller.text.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => GameScreen(difficulty: difficulty)),
        );
      }
    }
  }

  String _getDifficultyEmoji(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return '😊';
      case 'Hard':
        return '😈';
      default:
        return '😎';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getDifficultyInfo(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return '60s • 5 Lives • Slower Fruits';
      case 'Hard':
        return '30s • 2 Lives • Faster Fruits';
      default:
        return '45s • 3 Lives • Normal Speed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = getResponsiveConfig(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: config.topPadding * 2),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                "Chọn độ khó",
                style: TextStyle(
                  fontSize: config.scoreFontSize + 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(0, 4))
                  ],
                ),
              ),
              SizedBox(height: config.spacing * 6),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: config.sidePadding * 3,
                    vertical: config.panelPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(config.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person,
                        color: Colors.white, size: config.iconSize),
                    const SizedBox(width: 8),
                    Text(
                      playerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: config.timeFontSize + 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: config.spacing * 8),
              _buildDifficultyButton(
                  context, "Easy", Colors.green, "😊", config),
              SizedBox(height: config.spacing * 4),
              _buildDifficultyButton(
                  context, "Normal", Colors.orange, "😎", config),
              SizedBox(height: config.spacing * 4),
              _buildDifficultyButton(
                  context, "Hard", Colors.red, "😈", config),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String text,
      Color color, String emoji, ResponsiveConfig config) {
    return ElevatedButton(
      onPressed: () => _showNameInputDialog(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius * 2),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: config.panelPadding * 6,
          vertical: config.panelPadding * 2,
        ),
        textStyle: TextStyle(
          fontSize: config.comboFontSize,
          fontWeight: FontWeight.bold,
        ),
        elevation: 8,
        shadowColor: color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: config.timeFontSize + 12)),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}
