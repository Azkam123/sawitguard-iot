package id.sawitguard.sawitguard_iot

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class SawitGuardService : Service() {

    companion object {
        private const val TAG = "SawitGuardService"
        const val MONITOR_CHANNEL_ID = "sawitguard_monitor_channel"
        const val EMERGENCY_CHANNEL_ID = "sawitguard_emergency_channel"
        private const val NOTIFICATION_ID = 9001
        private const val EMERGENCY_NOTIFICATION_ID = 9002
        private const val DATABASE_URL = "https://sawitguard-iot-prod-default-rtdb.asia-southeast1.firebasedatabase.app"

        @Volatile
        var isAlarmRinging = false
            private set

        fun startService(context: Context) {
            try {
                val intent = Intent(context, SawitGuardService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Gagal menjalankan service: ${e.message}", e)
            }
        }

        fun muteAlarmFromApp() {
            instance?.muteAlarm()
        }

        fun unmuteAlarmFromApp() {
            instance?.unmuteAlarm()
        }

        private var instance: SawitGuardService? = null
    }

    private var mediaPlayer: MediaPlayer? = null
    private var silentPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var serviceCpuWakeLock: PowerManager.WakeLock? = null
    private var isMutedByUser = false

    private var database: FirebaseDatabase? = null
    private var rootRef: DatabaseReference? = null
    private var devicesRef: DatabaseReference? = null
    private var rootListener: ValueEventListener? = null
    private var devicesListener: ValueEventListener? = null

    // Gunakan background thread executor murni agar tidak terpengaruh looper utama / aplikasi lain
    private var scheduledExecutor: ScheduledExecutorService? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "SawitGuardService onCreate dipanggil")
        initCpuWakeLock()
        initChannels()
        initVibrator()
        startAsForeground()
        startSilentKeepAlive()
        initFirebase()
        startBackgroundPoller()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "SawitGuardService onStartCommand dipanggil")
        startAsForeground()
        startSilentKeepAlive()
        if (scheduledExecutor == null || scheduledExecutor!!.isShutdown) {
            startBackgroundPoller()
        }
        return START_STICKY
    }

    private fun initCpuWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            serviceCpuWakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "sawitguard:service_cpu_wakelock"
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
            Log.d(TAG, "Partial CPU WakeLock didapatkan.")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal mendapatkan CPU WakeLock: ${e.message}")
        }
    }

    private fun initChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val monitorChannel = NotificationChannel(
                MONITOR_CHANNEL_ID,
                "Pemantauan Kebun SawitGuard",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Layanan pemantauan sensor intrusi latar belakang 24/7"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(monitorChannel)

            val emergencyChannel = NotificationChannel(
                EMERGENCY_CHANNEL_ID,
                "Alarm Darurat Intrusi",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Peringatan darurat ketika terdeteksi maling/penyusup"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 800, 300, 800, 300, 800)
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(emergencyChannel)
        }
    }

    private fun initVibrator() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator ?: getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun startAsForeground() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, MONITOR_CHANNEL_ID)
            .setContentTitle("🛡️ SawitGuard Aktif (24/7)")
            .setContentText("Memantau kebun sawit secara realtime...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        var fgsType = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            fgsType = ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
        }

        try {
            ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, fgsType)
        } catch (e: Exception) {
            Log.e(TAG, "Error startForeground: ${e.message}", e)
        }
    }

    private fun startSilentKeepAlive() {
        if (isAlarmRinging) return
        try {
            if (silentPlayer == null) {
                silentPlayer = MediaPlayer.create(this, R.raw.silence)?.apply {
                    isLooping = true
                    setVolume(0.01f, 0.01f)
                    start()
                }
            } else if (!silentPlayer!!.isPlaying) {
                silentPlayer?.start()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Silent keepalive error: ${e.message}")
        }
    }

    private fun stopSilentKeepAlive() {
        try {
            silentPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            silentPlayer = null
        } catch (e: Exception) {
            Log.e(TAG, "Gagal stop silent keepalive: ${e.message}")
        }
    }

    private fun initFirebase() {
        try {
            if (FirebaseApp.getApps(this).isEmpty()) {
                FirebaseApp.initializeApp(this)
            }

            database = FirebaseDatabase.getInstance(DATABASE_URL).apply {
                goOnline()
            }

            // Dengarkan node 'devices'
            devicesRef = database?.getReference("devices")?.apply {
                keepSynced(true)
            }
            devicesListener = object : ValueEventListener {
                override fun onDataChange(snapshot: DataSnapshot) {
                    Log.i(TAG, "Devices onDataChange: count=${snapshot.childrenCount}, data=${snapshot.value}")
                    processSnapshot(snapshot)
                }

                override fun onCancelled(error: DatabaseError) {
                    Log.e(TAG, "Devices listener cancelled: ${error.message}")
                }
            }
            devicesRef?.addValueEventListener(devicesListener!!)

            Log.i(TAG, "Firebase devices listener berhasil diaktifkan.")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal inisialisasi Firebase: ${e.message}", e)
        }
    }

    private fun startBackgroundPoller() {
        scheduledExecutor?.shutdownNow()
        scheduledExecutor = Executors.newSingleThreadScheduledExecutor()

        scheduledExecutor?.scheduleWithFixedDelay({
            try {
                database?.goOnline()
                val task = devicesRef?.get()
                if (task != null) {
                    // Tasks.await berjalan sinkron murni di thread latar belakang tanpa bergantung pada UI Looper
                    val snapshot = Tasks.await(task, 3, TimeUnit.SECONDS)
                    processSnapshot(snapshot)
                }
            } catch (ignored: Exception) {
                // Timeout atau jeda jaringan wajar, siklus berikutnya akan mencoba kembali
            }
        }, 1, 1, TimeUnit.SECONDS) // Jalankan setiap 1 detik di thread background independen
    }

    /**
     * Memindai status intrusi secara rekursif sehingga format atau struktur apapun tertangkap seketika
     */
    private fun processSnapshot(snapshot: DataSnapshot?) {
        if (snapshot == null) return
        try {
            val (found, deviceName) = searchIntrusion(snapshot)
            if (found) {
                if (!isAlarmRinging) {
                    Log.w(TAG, "🚨 TERDETEKSI INTRUSI DI: $deviceName! MEMBUNYIKAN SIRINE SEGERA!")
                    triggerIntrusionAlarm(deviceName)
                }
            } else {
                if (isAlarmRinging) {
                    Log.i(TAG, "✅ Status database kembali aman. Mematikan sirine.")
                    stopIntrusionAlarm()
                }
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Error in processSnapshot: ${t.message}", t)
        }
    }

    private fun searchIntrusion(node: DataSnapshot): Pair<Boolean, String> {
        try {
            // Cek apakah node ini memiliki child 'status'
            val statusRaw = node.child("status").value
            val statusVal = (statusRaw as? String)?.trim()?.uppercase()
            val isIntrusiVal = (node.child("isIntrusi").value as? Boolean)
                ?: (node.child("intrusi").value as? Boolean)
                ?: false

            if (statusVal == "INTRUSI" || statusVal == "BAHAYA" || statusVal == "MALING" || statusVal == "ALERT" || isIntrusiVal) {
                val name = (node.child("nama_lokasi").value as? String)
                    ?: (node.child("nama_perangkat").value as? String)
                    ?: (node.child("name").value as? String)
                    ?: node.key ?: "Kebun Sawit"
                return Pair(true, name)
            }

            // Cek jika node ini sendiri berupa string primitif "INTRUSI"
            val rawVal = node.value
            if (rawVal is String) {
                val nodeString = rawVal.trim().uppercase()
                if (nodeString == "INTRUSI" || nodeString == "BAHAYA" || nodeString == "MALING") {
                    return Pair(true, node.key ?: "Kebun Sawit")
                }
            }

            // Periksa semua anak secara rekursif
            for (child in node.children) {
                val (childFound, childName) = searchIntrusion(child)
                if (childFound) return Pair(true, childName)
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Error in searchIntrusion: ${t.message}")
        }

        return Pair(false, "")
    }

    private fun triggerIntrusionAlarm(deviceName: String) {
        isAlarmRinging = true
        isMutedByUser = false // Selalu reset status mute agar sirine berbunyi kencang seketika
        stopSilentKeepAlive()

        // 1. Bangunkan layar HP seketika jika layar sedang mati / terkunci
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (wakeLock == null || !wakeLock!!.isHeld) {
                @Suppress("DEPRECATION")
                wakeLock = powerManager.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                    "sawitguard:alarm_wakelock"
                ).apply {
                    acquire(60 * 1000L)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menyalakan wakeLock: ${e.message}")
        }

        // 2. Minta Audio Focus Eksklusif (potong/pause audio aplikasi lain seperti WhatsApp)
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .build()
                audioManager.requestAudioFocus(focusRequest)
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error audio focus: ${e.message}")
        }

        // 3. Maksimalkan Volume Alarm di HP ke 100%
        try {
            val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVol, 0)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal mengatur volume alarm: ${e.message}")
        }

        // 4. Putar Suara Sirine Pemadam Kebakaran dengan Saluran ALARM
        if (!isMutedByUser) {
            try {
                if (mediaPlayer == null) {
                    mediaPlayer = MediaPlayer.create(this, R.raw.siren)?.apply {
                        isLooping = true
                        setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()
                        )
                        setVolume(1.0f, 1.0f)
                        start()
                    }
                } else if (!mediaPlayer!!.isPlaying) {
                    mediaPlayer?.start()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Gagal memutar sirine alarm: ${e.message}", e)
            }
        }

        // 5. Getarkan HP secara berulang
        try {
            val pattern = longArrayOf(0, 800, 300, 800, 300, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menggetarkan HP: ${e.message}")
        }

        // 6. Munculkan Notifikasi Darurat Prioritas Tertinggi
        showEmergencyNotification(deviceName)

        // 7. Buka Aplikasi SawitGuard ke Layar Utama di atas aplikasi lain (misal WhatsApp)
        try {
            val bringToFrontIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            if (bringToFrontIntent != null) {
                startActivity(bringToFrontIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Gagal bring activity to front: ${e.message}")
        }
    }

    private fun showEmergencyNotification(deviceName: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, EMERGENCY_CHANNEL_ID)
            .setContentTitle("🚨 BAHAYA! INTRUSI TERDETEKSI!")
            .setContentText("Maling/penyusup terdeteksi pada $deviceName! Klik untuk melihat radar!")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(EMERGENCY_NOTIFICATION_ID, notification)
    }

    private fun stopIntrusionAlarm() {
        isAlarmRinging = false
        isMutedByUser = false

        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            mediaPlayer = null
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menghentikan media player: ${e.message}")
        }

        try {
            vibrator?.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menghentikan vibrator: ${e.message}")
        }

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "Gagal melepaskan wakelock: ${e.message}")
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(EMERGENCY_NOTIFICATION_ID)

        startSilentKeepAlive()
    }

    fun muteAlarm() {
        isMutedByUser = true
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.pause()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error muting alarm: ${e.message}")
        }
    }

    fun unmuteAlarm() {
        isMutedByUser = false
        if (isAlarmRinging) {
            try {
                if (mediaPlayer == null) {
                    mediaPlayer = MediaPlayer.create(this, R.raw.siren)?.apply {
                        isLooping = true
                        start()
                    }
                } else if (!mediaPlayer!!.isPlaying) {
                    mediaPlayer?.start()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error unmuting alarm: ${e.message}")
            }
        }
    }

    override fun onDestroy() {
        instance = null
        scheduledExecutor?.shutdownNow()
        scheduledExecutor = null
        stopIntrusionAlarm()
        stopSilentKeepAlive()
        try {
            if (serviceCpuWakeLock?.isHeld == true) {
                serviceCpuWakeLock?.release()
            }
            serviceCpuWakeLock = null
        } catch (ignored: Exception) {}
        super.onDestroy()
        Log.w(TAG, "SawitGuardService onDestroy dipanggil, mengirim broadcast restart...")
        val restartIntent = Intent(applicationContext, BootReceiver::class.java).apply {
            action = "id.sawitguard.sawitguard_iot.RESTART_SERVICE"
        }
        sendBroadcast(restartIntent)
    }
}
