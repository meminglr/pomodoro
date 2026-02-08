import 'package:flutter/services.dart';

class SoundService {
  // final AudioPlayer _player = AudioPlayer();

  // Singleton pattern
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  Future<void> playStart() async {
    // Determine which sound to play
    // For now, we assume assets exist.
    // If not, we can't do much with AudioPlayer without files.
    // Ideally we'd bundle some default sounds.
    try {
      // await _player.play(AssetSource('sounds/start.mp3'));
      // Fallback or SystemSound if no assets? SystemSound is limited.
      // Haptic is handled separately.
      // Since we don't have assets yet, let's just log or prepare.
      print("Playing Start Sound");
    } catch (e) {
      print("Error playing start sound: $e");
    }
  }

  Future<void> playStop() async {
    try {
      // await _player.play(AssetSource('sounds/stop.mp3'));
      print("Playing Stop Sound");
    } catch (e) {
      print("Error playing stop sound: $e");
    }
  }

  Future<void> playFinish() async {
    try {
      // await _player.play(AssetSource('sounds/alarm.mp3'));
      print("Playing Finish Sound");
    } catch (e) {
      print("Error playing finish sound: $e");
    }
  }

  // Haptics
  Future<void> vibrateStart() async {
    await HapticFeedback.mediumImpact();
  }

  Future<void> vibrateStop() async {
    await HapticFeedback.heavyImpact();
  }

  Future<void> vibrateFinish() async {
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 500));
    await HapticFeedback.vibrate();
  }

  Future<void> vibrateStrictPenalty() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
  }
}
