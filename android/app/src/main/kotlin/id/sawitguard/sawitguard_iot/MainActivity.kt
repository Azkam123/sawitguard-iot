package id.sawitguard.sawitguard_iot

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "id.sawitguard/alarm"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Jalankan background monitoring service otomatis saat aplikasi dibuka
        SawitGuardService.startService(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    SawitGuardService.startService(this)
                    result.success(true)
                }
                "isAlarmRinging" -> {
                    result.success(SawitGuardService.isAlarmRinging)
                }
                "muteAlarm" -> {
                    SawitGuardService.muteAlarmFromApp()
                    result.success(true)
                }
                "unmuteAlarm" -> {
                    SawitGuardService.unmuteAlarmFromApp()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
