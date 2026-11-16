// lib/data/models/device_model.dart
import '../../core/constants/app_constants.dart';

class DeviceModel {
  final String id;
  final String namaLokasi;
  final String status;
  final int baterai;
  final int? sinyalRssi;
  final int lastUpdated;
  final String? pirStatus;
  final String? laserStatus;

  DeviceModel({
    required this.id,
    required this.namaLokasi,
    required this.status,
    required this.baterai,
    this.sinyalRssi,
    required this.lastUpdated,
    this.pirStatus,
    this.laserStatus,
  });

  bool get isIntrusi =>
      status.trim().toUpperCase() == AppConstants.statusIntrusi ||
      status.trim().toUpperCase() == 'INTRUSI' ||
      status.trim().toUpperCase() == 'BAHAYA' ||
      status.trim().toUpperCase() == 'MALING';

  /// Arah mata angin berdasarkan nama atau ID node
  String get directionName {
    final lower = (namaLokasi + id).toLowerCase();
    if (lower.contains('utara') || lower.contains('north') || lower.contains('_u')) {
      return 'Utara';
    } else if (lower.contains('selatan') || lower.contains('south') || lower.contains('_s')) {
      return 'Selatan';
    } else if (lower.contains('timur') || lower.contains('east') || lower.contains('_t')) {
      return 'Timur';
    } else if (lower.contains('barat') || lower.contains('west') || lower.contains('_b')) {
      return 'Barat';
    }
    return 'Node';
  }

  /// Inisial Arah (U, S, T, B)
  String get directionCode {
    switch (directionName) {
      case 'Utara':
        return 'U';
      case 'Selatan':
        return 'S';
      case 'Timur':
        return 'T';
      case 'Barat':
        return 'B';
      default:
        return 'N';
    }
  }

  /// Kode Zona Perimeter
  String get zoneBadge {
    switch (directionName) {
      case 'Utara':
        return 'ZONA-U01';
      case 'Selatan':
        return 'ZONA-S02';
      case 'Timur':
        return 'ZONA-T03';
      case 'Barat':
        return 'ZONA-B04';
      default:
        return id.toUpperCase();
    }
  }

  /// Kualitas Sinyal LoRa / Wi-Fi
  String get signalQuality {
    final rssi = sinyalRssi ?? -100;
    if (rssi >= -85) return 'Sangat Baik';
    if (rssi >= -95) return 'Baik';
    if (rssi >= -105) return 'Sedang';
    return 'Lemah';
  }

  factory DeviceModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return DeviceModel(
      id: id,
      namaLokasi: map['nama_lokasi'] as String? ?? 'Node Tidak Dikenal',
      status: (map['status'] as String? ?? AppConstants.statusAman).trim().toUpperCase(),
      baterai: (map['baterai'] as num?)?.toInt() ?? 85,
      sinyalRssi: (map['sinyal_rssi'] as num?)?.toInt() ?? -95,
      lastUpdated: (map['last_updated'] as num?)?.toInt() ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      pirStatus: map['pir_status'] as String?,
      laserStatus: map['laser_status'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'nama_lokasi': namaLokasi,
        'status': status,
        'baterai': baterai,
        'sinyal_rssi': sinyalRssi,
        'last_updated': lastUpdated,
        if (pirStatus != null) 'pir_status': pirStatus,
        if (laserStatus != null) 'laser_status': laserStatus,
      };

  DeviceModel copyWith({
    String? status,
    int? baterai,
    int? lastUpdated,
    int? sinyalRssi,
    String? pirStatus,
    String? laserStatus,
  }) {
    return DeviceModel(
      id: id,
      namaLokasi: namaLokasi,
      status: status ?? this.status,
      baterai: baterai ?? this.baterai,
      sinyalRssi: sinyalRssi ?? this.sinyalRssi,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      pirStatus: pirStatus ?? this.pirStatus,
      laserStatus: laserStatus ?? this.laserStatus,
    );
  }
}
