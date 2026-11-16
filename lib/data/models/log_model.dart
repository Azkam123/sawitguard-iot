// lib/data/models/log_model.dart

class HistoryLogModel {
  final String id;
  final String deviceId;
  final String lokasi;
  final String status;
  final int timestamp;
  final String keterangan;
  final String? dikonfirmasiOleh;
  final int? waktuReset;

  HistoryLogModel({
    required this.id,
    required this.deviceId,
    required this.lokasi,
    required this.status,
    required this.timestamp,
    required this.keterangan,
    this.dikonfirmasiOleh,
    this.waktuReset,
  });

  factory HistoryLogModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return HistoryLogModel(
      id: id,
      deviceId: map['device_id'] as String? ?? '',
      lokasi: map['lokasi'] as String? ?? '-',
      status: map['status'] as String? ?? 'INTRUSI',
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      keterangan: map['keterangan'] as String? ?? '',
      dikonfirmasiOleh: map['dikonfirmasi_oleh'] as String?,
      waktuReset: (map['waktu_reset'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'device_id': deviceId,
        'lokasi': lokasi,
        'status': status,
        'timestamp': timestamp,
        'keterangan': keterangan,
        if (dikonfirmasiOleh != null) 'dikonfirmasi_oleh': dikonfirmasiOleh,
        if (waktuReset != null) 'waktu_reset': waktuReset,
      };
}
