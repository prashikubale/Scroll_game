import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  late AudioPlayer _player;
  bool _isMuted = false;

  SoundManager._internal() {
    try {
      _player = AudioPlayer();
      // Preload sounds if possible
      // _player.setSource(AssetSource('audio/pop.mp3'));
    } catch (e) {
      // AudioPlayer might fail on web, create a dummy instance
      _player = AudioPlayer();
      if (kDebugMode) {
        print('AudioPlayer initialization warning: $e');
      }
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  Future<void> _playSound(String fileName, {double volume = 0.5}) async {
    return; // Temporarily disabled sound effects
    /*
    if (_isMuted) return;
    try {
      // In a real app, we might use a pool of players for overlapping sounds
      // For now, simple fire-and-forget
      await _player.play(AssetSource('audio/$fileName'), volume: volume, mode: PlayerMode.lowLatency);
    } catch (e) {
      // Suppress specific web errors to avoid console spam
      if (kDebugMode && !e.toString().contains('NotSupportedError')) {
        debugPrint("Error playing sound '$fileName': $e");
      }
    }
    */
  }

  Future<void> playTap() async {
    // Haptics removed for web compatibility
    await _playSound('pop.mp3', volume: 0.3);
  }

  Future<void> playScore() async {
    // Haptics removed for web compatibility
    await _playSound('score.mp3', volume: 0.6);
  }

  Future<void> playGameOver() async {
    // Haptics removed for web compatibility
    await _playSound('game_over.mp3', volume: 0.8);
  }

  Future<void> playSwipe() async {
    // Haptics removed for web compatibility
    // Optional: soft swoosh
    // await _playSound('swoosh.mp3', volume: 0.2);
  }
}
