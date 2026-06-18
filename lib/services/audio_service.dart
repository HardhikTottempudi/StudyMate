import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AmbientSound {
  final String id;
  final String name;
  final String emoji;
  final String url; // streaming URL
  final String description;

  const AmbientSound({
    required this.id,
    required this.name,
    required this.emoji,
    required this.url,
    required this.description,
  });
}

/// Curated list of free ambient sound streams (SomaFM + freesound CDN)
const List<AmbientSound> kAmbientSounds = [
  AmbientSound(
    id: 'rain',
    name: 'Rain',
    emoji: '🌧️',
    url: 'https://www.soundjay.com/nature/rain-01.mp3',
    description: 'Gentle rain shower',
  ),
  AmbientSound(
    id: 'ocean',
    name: 'Ocean',
    emoji: '🌊',
    url: 'https://www.soundjay.com/nature/ocean-wave-1.mp3',
    description: 'Calming ocean waves',
  ),
  AmbientSound(
    id: 'forest',
    name: 'Forest',
    emoji: '🌲',
    url: 'https://www.soundjay.com/nature/birds-singing-02.mp3',
    description: 'Birds & forest ambience',
  ),
  AmbientSound(
    id: 'drone',
    name: 'Deep Focus',
    emoji: '🎯',
    url: 'https://ice6.somafm.com/dronezone-128-mp3',
    description: 'Ambient drone zone',
  ),
  AmbientSound(
    id: 'lofi',
    name: 'Lo-Fi',
    emoji: '🎵',
    url: 'https://ice6.somafm.com/groovesalad-128-mp3',
    description: 'Chill groove salad',
  ),
  AmbientSound(
    id: 'space',
    name: 'Space',
    emoji: '🚀',
    url: 'https://ice6.somafm.com/deepspaceone-128-mp3',
    description: 'Deep space ambient',
  ),
];

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentId;
  bool _isPlaying = false;

  String? get currentId => _currentId;
  bool get isPlaying => _isPlaying;

  Future<void> play(AmbientSound sound) async {
    try {
      if (_currentId == sound.id && _isPlaying) return;
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(UrlSource(sound.url));
      _currentId = sound.id;
      _isPlaying = true;
    } catch (e) {
      debugPrint('AudioService.play error: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentId = null;
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    await _player.resume();
    _isPlaying = true;
  }

  // Legacy helpers kept for backward compat
  Future<void> playRain() => play(kAmbientSounds[0]);

  void dispose() {
    _player.dispose();
  }
}
