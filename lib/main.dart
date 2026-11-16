import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/history/history_screen.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for DateFormat
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Date formatting init note: $e');
  }

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint('Firebase already initialized natively by Android.');
    } else {
      debugPrint('FirebaseException during init: ${e.code} - ${e.message}');
    }
  } catch (e) {
    debugPrint('Firebase init note: $e');
  }

  // Initialize Supabase if configured
  try {
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      debugPrint('[Supabase] Initialized successfully with project URL.');
    }
  } catch (e) {
    debugPrint('[Supabase] Init note: $e');
  }

  runApp(const SawitGuardApp());
}

class SawitGuardApp extends StatefulWidget {
  const SawitGuardApp({super.key});

  @override
  State<SawitGuardApp> createState() => _SawitGuardAppState();
}

class _SawitGuardAppState extends State<SawitGuardApp> {
  final FcmService _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    _startNativeMonitoring();
    _initFcm();
  }

  Future<void> _startNativeMonitoring() async {
    try {
      const MethodChannel('id.sawitguard/alarm').invokeMethod('startService');
    } catch (e) {
      debugPrint('Error starting native monitoring: $e');
    }
  }

  Future<void> _initFcm() async {
    try {
      await _fcmService.initialize(
        onForegroundMessage: (msg) async {
          await _fcmService.showForegroundBanner(msg);
        },
        onMessageOpenedApp: (msg) {
          if (msg != null) {
            // Navigate to dashboard to see the alert
            // Navigation handled by rootNavigatorKey if needed
          }
        },
      );

      // Get and save FCM token
      final token = await _fcmService.getToken();
      if (token != null) {
        // Saved via AuthProvider.saveFcmToken after login
      }

      // Listen for token refresh
      _fcmService.onTokenRefresh.listen((newToken) {
        // Will be saved next time user logs in or on explicit save
      });
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: MaterialApp(
        title: 'SawitGuard IoT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/otp': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments as OtpScreenArgs;
            return OtpScreen(args: args);
          },
          '/verify-email': (ctx) {
            final email = ModalRoute.of(ctx)?.settings.arguments as String?;
            return VerifyEmailScreen(email: email);
          },
          '/dashboard': (_) => const DashboardScreen(),
          '/history': (_) => const HistoryScreen(),
        },
        // AlertScreen is pushed programmatically with device arg
        onUnknownRoute: (_) =>
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
      ),
    );
  }
}
