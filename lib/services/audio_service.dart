import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentAsset;

  bool get isPlaying => _isPlaying;

  Future<void> playWhiteNoise() async {
    if (_isPlaying && _currentAsset == 'white_noise.mp3') {
      return;
    }

    try {
      // In production, you would use actual audio files
      // For now, this is a placeholder structure
      // You'll need to add white_noise.mp3 to assets/audio/
      await _player.play(AssetSource('audio/white_noise.mp3'));
      _isPlaying = true;
      _currentAsset = 'white_noise.mp3';
    } catch (e) {
      // If asset doesn't exist, handle gracefully
      debugPrint('Error playing white noise: $e');
    }
  }

  Future<void> playRain() async {
    if (_isPlaying && _currentAsset == 'rain.mp3') {
      return;
    }

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audio/rain.mp3'));
    _isPlaying = true;
    _currentAsset = 'rain.mp3';
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentAsset = null;
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    if (_currentAsset != null) {
      await _player.resume();
      _isPlaying = true;
    }
  }

  void dispose() {
    _player.dispose();
  }
}
