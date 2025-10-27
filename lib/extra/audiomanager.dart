  import 'package:audioplayers/audioplayers.dart';
  import 'package:flutter/services.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class AudioManager {
    static final AudioManager _instance = AudioManager._internal();
    factory AudioManager() => _instance;
    AudioManager._internal();

    final AudioPlayer _sfxPlayer = AudioPlayer();
    final AudioPlayer _bgmPlayer = AudioPlayer();
    
    bool isSfxEnabled = true;
    bool isMusicEnabled = true;
    double musicVolume = 0.1;
    double sfxVolume = 0.7;
    double _effectsVolume = 1.0;

    double get effectsVolume => _effectsVolume;

      // Setter cho volume
    Future<void> setEffectsVolume(double volume) async {
      _effectsVolume = volume;
      await _sfxPlayer.setVolume(volume);
      
      // Lưu volume vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('effects_volume', volume);
    }

      // Load volume từ SharedPreferences khi khởi động
    Future<void> loadSettings() async {
      final prefs = await SharedPreferences.getInstance();
      _effectsVolume = prefs.getDouble('effects_volume') ?? 1.0;
      await _sfxPlayer.setVolume(_effectsVolume);
    }

    Future<void> init() async {
      final prefs = await SharedPreferences.getInstance();
      isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
      isMusicEnabled = prefs.getBool('music_enabled') ?? true;
      musicVolume = prefs.getDouble('music_volume') ?? 0.1;
      sfxVolume = prefs.getDouble('sfx_volume') ?? 0.7;
      
      // Cấu hình BGM player để loop
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(musicVolume);
    }

    // Background Music
    Future<void> playBackgroundMusic() async {
      if (isMusicEnabled) {
        await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.setVolume(musicVolume);
        await _bgmPlayer.play(
          AssetSource('sounds/bgm_fixed.mp3'),
        );
      }
    }

    Future<void> stopBackgroundMusic() async {
      await _bgmPlayer.stop();
    }

    Future<void> pauseBackgroundMusic() async {
      await _bgmPlayer.pause();
    }

    Future<void> resumeBackgroundMusic() async {
      if (isMusicEnabled) {
        await _bgmPlayer.resume();
      }
    }

    Future<void> setMusicVolume(double volume) async {
      musicVolume = volume;
      await _bgmPlayer.setVolume(volume);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('music_volume', volume);
    }

    Future<void> toggleMusic(bool value) async {
      isMusicEnabled = !isMusicEnabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('music_enabled', isMusicEnabled);
      
      if (isMusicEnabled) {
        await resumeBackgroundMusic();
      } else {
        await pauseBackgroundMusic();
      }
    }

    // Sound Effects
    Future<void> playSliceSound() async {
      if (isSfxEnabled) {
        await HapticFeedback.lightImpact();
        // Tạo AudioPlayer mới cho mỗi lần chém để không bị gián đoạn
        final player = AudioPlayer();
        await player.setVolume(sfxVolume);
        await player.play(AssetSource('sounds/slice.mp3'));
        player.onPlayerComplete.listen((_) => player.dispose());
      }
    }

    Future<void> playBombSound() async {
      if (isSfxEnabled) {
        await HapticFeedback.heavyImpact();
        final player = AudioPlayer();
        await player.setVolume(sfxVolume);
        await player.play(AssetSource('sounds/bomb.mp3'));
        player.onPlayerComplete.listen((_) => player.dispose());
      }
    }

    Future<void> playComboSound() async {
      if (isSfxEnabled) {
        await HapticFeedback.mediumImpact();
        final player = AudioPlayer();
        await player.setVolume(sfxVolume);
        await player.play(AssetSource('sounds/combo.mp3'));
        player.onPlayerComplete.listen((_) => player.dispose());
      }
    }

    Future<void> playItemSound() async {
      if (isSfxEnabled) {
        await HapticFeedback.selectionClick();
        final player = AudioPlayer();
        await player.setVolume(sfxVolume);
        await player.play(AssetSource('sounds/item.mp3'));
        player.onPlayerComplete.listen((_) => player.dispose());
      }
    }

    Future<void> playGameOverSound() async {
      if (isSfxEnabled) {
        final player = AudioPlayer();
        await player.setVolume(sfxVolume);
        await player.play(AssetSource('sounds/gameover.mp3'));
        player.onPlayerComplete.listen((_) => player.dispose());
      }
    }

    Future<void> setSfxVolume(double volume) async {
      sfxVolume = volume;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sfx_volume', volume);
    }

    Future<void> toggleSfx(bool value) async {
      isSfxEnabled = !isSfxEnabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sfx_enabled', isSfxEnabled);
    }

    void dispose() {
      _sfxPlayer.dispose();
      _bgmPlayer.dispose();
    }

  void pauseBGM() {}
  }