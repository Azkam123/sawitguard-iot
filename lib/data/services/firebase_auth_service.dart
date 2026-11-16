import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://sawitguard-iot-prod-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current signed-in user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign up with email, password, and save user profile to RTDB
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String nama,
    required String noHp,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      // Pengguna sudah diverifikasi melalui kode OTP 6 digit

      // Simpan data profil pengguna ke Realtime Database
      await _db.ref('${AppConstants.usersPath}/${user.uid}').set({
        'nama': nama.trim(),
        'no_hp': noHp.trim(),
        'email': email.trim(),
        'terakhir_aktif': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    }
    return cred;
  }

  /// Send verification email to currently signed in user
  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reload user and check if email is verified
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch or create user profile in Realtime Database
  Future<UserModel?> getUserProfile(String uid) async {
    final snap =
        await _db.ref('${AppConstants.usersPath}/$uid').get();
    if (snap.exists && snap.value != null) {
      return UserModel.fromMap(uid, snap.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  /// Save/update FCM token for this user
  Future<void> saveFcmToken(String uid, String token) async {
    await _db.ref('${AppConstants.usersPath}/$uid').update({
      'fcm_token': token,
      'terakhir_aktif':
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }
}
