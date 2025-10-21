import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'gamescreen.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
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
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, 4))],
              ),
            ),
            const SizedBox(height: 50),
            _buildDifficultyButton(context, "Easy", Colors.green, "😊"),
            const SizedBox(height: 20),
            _buildDifficultyButton(context, "Normal", Colors.orange, "😎"),
            const SizedBox(height: 20),
            _buildDifficultyButton(context, "Hard", Colors.red, "😈"),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String text, Color color, String emoji) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (text == "Easy" ? 0 : text == "Normal" ? 200 : 400)),
      curve: Curves.elasticOut,
      builder: (context, double value, child) => Transform.scale(scale: value, child: child),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => GameScreen(difficulty: text)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          elevation: 8,
          shadowColor: color,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(text),
          ],
        ),
      ),
    );
  }
}