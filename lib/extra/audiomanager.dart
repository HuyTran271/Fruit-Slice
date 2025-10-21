import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool isSfxEnabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
  }

  Future<void> playSliceSound() async {
    if (isSfxEnabled) {
      await HapticFeedback.lightImpact();
      await _player.play(AssetSource('sounds/slice.mp3'));
    }
  }

  Future<void> playBombSound() async {
    if (isSfxEnabled) {
      await HapticFeedback.heavyImpact();
      await _player.play(AssetSource('sounds/bomb.mp3'));
    }
  }

  Future<void> playComboSound() async {
    if (isSfxEnabled) {
      await HapticFeedback.mediumImpact();
      await _player.play(AssetSource('sounds/combo.mp3'));
    }
  }
}
