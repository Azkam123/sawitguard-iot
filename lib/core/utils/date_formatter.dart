// lib/core/utils/date_formatter.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> _idMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static String toReadable(int timestamp) {
    if (timestamp <= 0) return '-';
    // Support either seconds or milliseconds
    final ts = timestamp > 1000000000000 ? timestamp : timestamp * 1000;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    try {
      return DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(dt);
    } catch (e) {
      debugPrint('[DateFormatter] Fallback toReadable: $e');
      final monthName = _idMonths[(dt.month - 1).clamp(0, 11)];
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$d $monthName ${dt.year}, $h:$m:$s';
    }
  }

  static String toShortTime(int timestamp) {
    if (timestamp <= 0) return '-';
    final ts = timestamp > 1000000000000 ? timestamp : timestamp * 1000;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    try {
      return DateFormat('HH:mm', 'id_ID').format(dt);
    } catch (_) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
  }

  static String toRelative(int timestamp) {
    if (timestamp <= 0) return 'Baru saja';
    final ts = timestamp > 1000000000000 ? timestamp : timestamp * 1000;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.isNegative || diff.inSeconds < 45) {
      return 'Baru saja';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mnt lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    }
    if (diff.inDays <= 7) {
      return '${diff.inDays} hari lalu';
    }
    // Jika data lampau/dummy mock lama, tampilkan format waktu singkat atau status aktif
    return 'Terkoneksi';
  }
}
