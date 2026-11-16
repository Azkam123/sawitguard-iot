// lib/data/services/audio_alert_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AudioAlertService {
  static const MethodChannel _nativeChannel = MethodChannel('id.sawitguard/alarm');
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Play siren on loop until stopped
  Future<void> playSiren() async {
    if (_isPlaying) return;
    _isPlaying = true;

    // Pastikan native alarm tidak dalam kondisi mute
    try {
      await _nativeChannel.invokeMethod('unmuteAlarm');
    } catch (_) {}

    // Cek apakah service native Android sudah memainkan sirine
    bool isNativeRinging = false;
    try {
      isNativeRinging = await _nativeChannel.invokeMethod('isAlarmRinging') ?? false;
    } catch (_) {}

    if (!isNativeRinging) {
      try {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(1.0);
        await _player.play(AssetSource('audio/siren.mp3'));
      } catch (e) {
        debugPrint('[AudioAlertService] Siren audio play error: $e');
      }
      _startVibration();
    }
  }

  /// Mute sementara suara saat pengguna sedang menelepon darurat
  Future<void> muteTemporarily() async {
    try {
      await _nativeChannel.invokeMethod('muteAlarm');
    } catch (_) {}
    try {
      await _player.stop();
    } catch (_) {}
    _stopVibration();
  }

  /// Stop siren and vibration saat status kembali aman
  Future<void> stopSiren() async {
    _isPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
    _stopVibration();
  }

  void _startVibration() async {
    try {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (!hasVibrator) return;
      // Repeating pattern: vibrate 800ms, pause 400ms
      Vibration.vibrate(pattern: [0, 800, 400, 800, 400, 800], repeat: 0);
    } catch (e) {
      debugPrint('[AudioAlertService] Vibration error: $e');
    }
  }

  void _stopVibration() {
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
