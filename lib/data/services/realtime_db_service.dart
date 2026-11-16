import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../models/device_model.dart';
import '../models/log_model.dart';

class RealtimeDbService {
  late final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://sawitguard-iot-prod-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  /// 4 Node Perimeter Default Kebun Sawit (Utara, Selatan, Timur, Barat)
  static final Map<String, Map<String, dynamic>> defaultFourNodes = {
    'node_utara_02': {
      'nama_lokasi': 'Blok Utara - Jalan Traktor',
      'status': AppConstants.statusAman,
      'baterai': 94,
      'sinyal_rssi': -98,
      'pir_status': 'Standby (Normal)',
      'laser_status': 'Terhubung (Normal)',
    },
    'node_selatan_01': {
      'nama_lokasi': 'Blok Selatan - Parit Gajah',
      'status': AppConstants.statusAman,
      'baterai': 88,
      'sinyal_rssi': -94,
      'pir_status': 'Standby (Normal)',
      'laser_status': 'Terhubung (Normal)',
    },
    'node_timur_03': {
      'nama_lokasi': 'Blok Timur - Batas Kanal',
      'status': AppConstants.statusAman,
      'baterai': 91,
      'sinyal_rssi': -92,
      'pir_status': 'Standby (Normal)',
      'laser_status': 'Terhubung (Normal)',
    },
    'node_barat_04': {
      'nama_lokasi': 'Blok Barat - Akses Rel Lori',
      'status': AppConstants.statusAman,
      'baterai': 85,
      'sinyal_rssi': -96,
      'pir_status': 'Standby (Normal)',
      'laser_status': 'Terhubung (Normal)',
    },
  };

  /// Pastikan ke-4 node perimeter (Utara, Selatan, Timur, Barat) tersedia di Firebase
  Future<void> syncAllFourNodes() async {
    try {
      final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final snap = await _db
          .ref(AppConstants.devicesPath)
          .get()
          .timeout(const Duration(seconds: 4));

      final Map existing = (snap.exists && snap.value != null)
          ? Map<dynamic, dynamic>.from(snap.value as Map)
          : {};

      final updates = <String, dynamic>{};

      defaultFourNodes.forEach((nodeId, defaultData) {
        if (!existing.containsKey(nodeId)) {
          updates[nodeId] = {
            ...defaultData,
            'last_updated': nowTs,
          };
        } else {
          // Perbarui timestamp jika data lama (misal 2024) agar tidak muncul "775 hari lalu"
          final existingNode = existing[nodeId];
          if (existingNode is Map) {
            final oldTs = (existingNode['last_updated'] as num?)?.toInt() ?? 0;
            if (nowTs - oldTs > 86400 * 14) {
              updates['$nodeId/last_updated'] = nowTs;
            }
          }
        }
      });

      if (updates.isNotEmpty) {
        await _db.ref(AppConstants.devicesPath).update(updates);
        debugPrint('[RealtimeDbService] Berhasil menyelaraskan 4 node ke Firebase RTDB');
      }
    } catch (e) {
      debugPrint('[RealtimeDbService] Note syncAllFourNodes: $e');
    }
  }

  /// Stream all devices — UI auto-rebuilds via StreamBuilder
  Stream<List<DeviceModel>> streamDevices() {
    return _db.ref(AppConstants.devicesPath).onValue.map((event) {
      final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (!event.snapshot.exists || event.snapshot.value == null) {
        // Fallback instan 4 node jika database kosong
        return defaultFourNodes.entries.map((e) {
          return DeviceModel.fromMap(e.key, {
            ...e.value,
            'last_updated': nowTs,
          });
        }).toList();
      }

      final raw = event.snapshot.value as Map<dynamic, dynamic>;
      final devices = <DeviceModel>[];

      // Parse perangkat yang ada dari Firebase
      raw.forEach((k, v) {
        if (v is Map) {
          devices.add(DeviceModel.fromMap(k.toString(), v));
        }
      });

      // Pastikan node Timur dan Barat tetap muncul jika belum tersinkronisasi
      defaultFourNodes.forEach((nodeId, defaultData) {
        if (!devices.any((d) => d.id == nodeId)) {
          devices.add(DeviceModel.fromMap(nodeId, {
            ...defaultData,
            'last_updated': nowTs,
          }));
        }
      });

      // Urutkan: Node dengan Intrusi paling atas, lalu urutkan Utara -> Selatan -> Timur -> Barat
      devices.sort((a, b) {
        if (a.isIntrusi && !b.isIntrusi) return -1;
        if (!a.isIntrusi && b.isIntrusi) return 1;
        return _nodeOrder(a.directionName).compareTo(_nodeOrder(b.directionName));
      });

      return devices;
    });
  }

  int _nodeOrder(String dir) {
    switch (dir) {
      case 'Utara':
        return 1;
      case 'Selatan':
        return 2;
      case 'Timur':
        return 3;
      case 'Barat':
        return 4;
      default:
        return 5;
    }
  }

  /// Stream single device for emergency alert listening
  Stream<DeviceModel?> streamDevice(String deviceId) {
    return _db.ref('${AppConstants.devicesPath}/$deviceId').onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return null;
      return DeviceModel.fromMap(
          deviceId, e.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  /// Reset device status back to AMAN after petani confirms
  Future<void> resetDeviceStatus(String deviceId, String confirmedByUid) async {
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Reset device status ke AMAN di Realtime Database
    await _db.ref('${AppConstants.devicesPath}/$deviceId').update({
      'status': AppConstants.statusAman,
      'last_updated': nowTs,
      'pir_status': 'Standby (Normal)',
      'laser_status': 'Terhubung (Normal)',
    });

    debugPrint('[RealtimeDbService] Status device $deviceId berhasil direset ke AMAN');

    // 2. Update log riwayat waktu_reset
    try {
      final snap = await _db
          .ref(AppConstants.historyLogsPath)
          .limitToLast(15)
          .get()
          .timeout(const Duration(seconds: 3));

      if (snap.exists && snap.value != null) {
        final logsMap = Map<dynamic, dynamic>.from(snap.value as Map);
        String? targetLogKey;
        int latestTs = 0;

        logsMap.forEach((k, v) {
          if (v is Map) {
            final logDevId = v['device_id']?.toString();
            final ts = (v['timestamp'] as num?)?.toInt() ?? 0;
            if (logDevId == deviceId && ts >= latestTs) {
              latestTs = ts;
              targetLogKey = k.toString();
            }
          }
        });

        if (targetLogKey != null) {
          await _db.ref('${AppConstants.historyLogsPath}/$targetLogKey').update({
            'dikonfirmasi_oleh': confirmedByUid,
            'waktu_reset': nowTs,
          });
        }
      }
    } catch (e) {
      debugPrint('[RealtimeDbService] Note history log reset update: $e');
    }
  }

  /// Fetch history logs ordered by timestamp (newest first)
  Future<List<HistoryLogModel>> getHistoryLogs({int limit = 50}) async {
    try {
      final snap = await _db
          .ref(AppConstants.historyLogsPath)
          .orderByChild('timestamp')
          .limitToLast(limit)
          .get();

      if (!snap.exists || snap.value == null) return [];
      final raw = snap.value as Map<dynamic, dynamic>;
      final list = raw.entries
          .map((e) => HistoryLogModel.fromMap(
              e.key as String, e.value as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      debugPrint('[RealtimeDbService] getHistoryLogs error: $e');
      return [];
    }
  }

  /// Write an intrusion log
  Future<void> writeIntrusionLog(HistoryLogModel log) async {
    final ref = _db.ref(AppConstants.historyLogsPath).push();
    await ref.set(log.toMap());
  }
}
