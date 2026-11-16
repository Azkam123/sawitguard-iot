// lib/data/models/user_model.dart

class UserModel {
  final String uid;
  final String nama;
  final String noHp;
  final String? fcmToken;
  final int? terakhirAktif;

  UserModel({
    required this.uid,
    required this.nama,
    required this.noHp,
    this.fcmToken,
    this.terakhirAktif,
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      nama: map['nama'] as String? ?? 'Pengguna',
      noHp: map['no_hp'] as String? ?? '',
      fcmToken: map['fcm_token'] as String?,
      terakhirAktif: map['terakhir_aktif'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'no_hp': noHp,
        if (fcmToken != null) 'fcm_token': fcmToken,
        if (terakhirAktif != null) 'terakhir_aktif': terakhirAktif,
      };

  UserModel copyWith({String? fcmToken, int? terakhirAktif}) {
    return UserModel(
      uid: uid,
      nama: nama,
      noHp: noHp,
      fcmToken: fcmToken ?? this.fcmToken,
      terakhirAktif: terakhirAktif ?? this.terakhirAktif,
    );
  }
}
