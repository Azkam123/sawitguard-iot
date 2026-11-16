// lib/providers/device_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/device_model.dart';
import '../data/models/log_model.dart';
import '../data/services/realtime_db_service.dart';
import '../data/services/audio_alert_service.dart';

class DeviceProvider extends ChangeNotifier {
  final RealtimeDbService _dbService = RealtimeDbService();
  final AudioAlertService _audioService = AudioAlertService();
  StreamSubscription<List<DeviceModel>>? _deviceSubscription;

  List<DeviceModel> _devices = [];
  List<HistoryLogModel> _historyLogs = [];
  bool _isAlarmActive = false;
  DeviceModel? _activeAlertDevice;
  bool _isLoadingHistory = false;

  DeviceProvider() {
    _startDeviceListener();
    syncAllFourNodes();
  }

  Future<void> syncAllFourNodes() async {
    await _dbService.syncAllFourNodes();
  }

  List<DeviceModel> get devices => _devices;
  List<HistoryLogModel> get historyLogs => _historyLogs;
  bool get isAlarmActive => _isAlarmActive;
  DeviceModel? get activeAlertDevice => _activeAlertDevice;
  bool get isLoadingHistory => _isLoadingHistory;

  /// Returns true if any device has INTRUSI status
  bool get hasActiveIntrusion =>
      _devices.any((d) => d.isIntrusi);

  /// Count of active intrusions
  int get intrusionCount => _devices.where((d) => d.isIntrusi).length;

  /// Inisialisasi pendengar stream otomatis di level provider (tetap aktif di seluruh aplikasi)
  void _startDeviceListener() {
    _deviceSubscription?.cancel();
    _deviceSubscription = _dbService.streamDevices().listen(
      (devices) {
        onDevicesUpdated(devices);
      },
      onError: (err) {
        debugPrint('[DeviceProvider] Stream error: $err');
      },
    );
  }

  /// Initialize device stream listener
  Stream<List<DeviceModel>> streamDevices() => _dbService.streamDevices();

  /// Called whenever devices update
  void onDevicesUpdated(List<DeviceModel> devices) {
    _devices = devices;
    final intruded = devices.where((d) => d.isIntrusi).toList();

    if (intruded.isNotEmpty && !_isAlarmActive) {
      _isAlarmActive = true;
      _activeAlertDevice = intruded.first;
      _audioService.playSiren();
    } else if (intruded.isEmpty && _isAlarmActive) {
      // Auto-reset if no device is intrusi anymore
      _stopAlarm();
    }
    notifyListeners();
  }

  /// Petani geser slider -> reset alarm
  Future<void> confirmAndReset(String deviceId, String uid) async {
    await _dbService.resetDeviceStatus(deviceId, uid);
    _stopAlarm();
    notifyListeners();
  }

  /// Mute suara sirine sementara (misal saat menelepon)
  void muteSirenTemporarily() {
    _audioService.muteTemporarily();
  }

  /// Nyalakan kembali suara sirine jika alarm masih aktif
  void unmuteSiren() {
    if (_isAlarmActive) {
      _audioService.playSiren();
    }
  }

  void _stopAlarm() {
    _isAlarmActive = false;
    _activeAlertDevice = null;
    _audioService.stopSiren();
  }

  Future<void> loadHistoryLogs() async {
    _isLoadingHistory = true;
    notifyListeners();
    _historyLogs = await _dbService.getHistoryLogs();
    _isLoadingHistory = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
