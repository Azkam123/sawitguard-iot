/**
 * SawitGuard IoT - Firebase Cloud Functions
 * ==========================================
 * Fungsi serverless yang memantau perubahan status node di Realtime Database.
 * Ketika status berubah menjadi "INTRUSI", secara otomatis:
 *   1. Mengirimkan FCM High-Priority Push Notification ke semua petani terdaftar
 *   2. Mencatat kejadian ke /history_logs dengan cap waktu server
 *
 * Deploy: firebase deploy --only functions (dari folder cloud_functions/)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.database();
const messaging = admin.messaging();

// ─── KONSTANTA ───────────────────────────────────────────────────────────────
const STATUS_INTRUSI = "INTRUSI";
const STATUS_AMAN = "AMAN";
const DEVICES_PATH = "devices";
const USERS_PATH = "users";
const HISTORY_LOGS_PATH = "history_logs";

// ─── INTERFACE TYPES ─────────────────────────────────────────────────────────
interface DeviceData {
  nama_lokasi: string;
  status: string;
  baterai: number;
  sinyal_rssi?: number;
  last_updated: number;
}

interface UserData {
  nama: string;
  no_hp: string;
  fcm_token?: string;
}

// ─── CLOUD FUNCTION: Trigger saat status device berubah ─────────────────────
/**
 * Trigger: onUpdate pada /devices/{nodeId}
 * Aksi: Kirim FCM + Tulis log jika status menjadi INTRUSI
 */
export const onDeviceStatusChange = functions
  .region("asia-southeast1") // Pilih region Asia Tenggara untuk latensi rendah ke Indonesia
  .database.ref(`/${DEVICES_PATH}/{nodeId}`)
  .onUpdate(async (change, context) => {
    const nodeId: string = context.params.nodeId;
    const beforeData = change.before.val() as DeviceData | null;
    const afterData = change.after.val() as DeviceData | null;

    if (!afterData) return null;

    const prevStatus = beforeData?.status ?? STATUS_AMAN;
    const newStatus = afterData.status;

    // Hanya proses jika transisi dari AMAN ke INTRUSI
    if (prevStatus === newStatus) {
      functions.logger.info(`[${nodeId}] Status tidak berubah: ${newStatus}. Diabaikan.`);
      return null;
    }

    if (newStatus === STATUS_INTRUSI) {
      functions.logger.warn(`🚨 INTRUSI TERDETEKSI pada node: ${nodeId} | Lokasi: ${afterData.nama_lokasi}`);

      // Jalankan secara paralel: kirim FCM + tulis log
      await Promise.all([
        sendEmergencyFcm(nodeId, afterData),
        writeIntrusionLog(nodeId, afterData),
      ]);

      return null;
    }

    if (newStatus === STATUS_AMAN && prevStatus === STATUS_INTRUSI) {
      functions.logger.info(`✅ Node ${nodeId} kembali AMAN.`);
      // Opsional: kirim notifikasi "kondisi sudah aman"
      await sendSafeNotification(nodeId, afterData);
    }

    return null;
  });

// ─── HELPER: Kirim FCM High-Priority ke semua petani ─────────────────────────
async function sendEmergencyFcm(nodeId: string, device: DeviceData): Promise<void> {
  try {
    // Ambil semua token FCM dari semua user terdaftar
    const usersSnapshot = await db.ref(USERS_PATH).get();
    if (!usersSnapshot.exists()) {
      functions.logger.warn("Tidak ada user terdaftar untuk dikirim notifikasi.");
      return;
    }

    const usersData = usersSnapshot.val() as Record<string, UserData>;
    const fcmTokens: string[] = Object.values(usersData)
      .filter((u) => u.fcm_token)
      .map((u) => u.fcm_token as string);

    if (fcmTokens.length === 0) {
      functions.logger.warn("Tidak ada token FCM valid ditemukan.");
      return;
    }

    // Susun payload FCM berprioritas tinggi
    const message: admin.messaging.MulticastMessage = {
      tokens: fcmTokens,
      notification: {
        title: "⚠️ PERINGATAN! INTRUSI TERDETEKSI",
        body: `Gerakan mencurigakan di: ${device.nama_lokasi}. Segera periksa kebun Anda!`,
      },
      data: {
        node_id: nodeId,
        lokasi: device.nama_lokasi,
        status: STATUS_INTRUSI,
        timestamp: String(Math.floor(Date.now() / 1000)),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sawitguard_emergency_channel",
          priority: "max",
          defaultSound: true,
          defaultVibrateTimings: true,
          visibility: "public",
          // Full screen intent untuk membangunkan layar kunci
          notificationCount: 1,
        },
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
            sound: "default",
            badge: 1,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    functions.logger.info(
      `FCM terkirim: ${response.successCount} berhasil, ${response.failureCount} gagal dari ${fcmTokens.length} perangkat.`
    );

    // Bersihkan token yang sudah tidak valid (expired/revoked)
    const invalidTokenUids: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errCode = resp.error?.code;
        if (
          errCode === "messaging/registration-token-not-registered" ||
          errCode === "messaging/invalid-registration-token"
        ) {
          // Cari UID yang memiliki token ini
          const invalidToken = fcmTokens[idx];
          Object.entries(usersData).forEach(([uid, user]) => {
            if (user.fcm_token === invalidToken) {
              invalidTokenUids.push(uid);
            }
          });
        }
      }
    });

    // Hapus token tidak valid dari database
    if (invalidTokenUids.length > 0) {
      const cleanupTasks = invalidTokenUids.map((uid) =>
        db.ref(`${USERS_PATH}/${uid}/fcm_token`).remove()
      );
      await Promise.all(cleanupTasks);
      functions.logger.info(`Dihapus ${invalidTokenUids.length} token FCM tidak valid.`);
    }
  } catch (error) {
    functions.logger.error("Gagal mengirim FCM:", error);
  }
}

// ─── HELPER: Kirim notifikasi "Situasi Aman" ─────────────────────────────────
async function sendSafeNotification(nodeId: string, device: DeviceData): Promise<void> {
  try {
    const usersSnapshot = await db.ref(USERS_PATH).get();
    if (!usersSnapshot.exists()) return;

    const usersData = usersSnapshot.val() as Record<string, UserData>;
    const fcmTokens: string[] = Object.values(usersData)
      .filter((u) => u.fcm_token)
      .map((u) => u.fcm_token as string);

    if (fcmTokens.length === 0) return;

    const message: admin.messaging.MulticastMessage = {
      tokens: fcmTokens,
      notification: {
        title: "✅ Situasi Aman Kembali",
        body: `Node ${device.nama_lokasi} telah direset ke status AMAN.`,
      },
      data: {
        node_id: nodeId,
        status: STATUS_AMAN,
        timestamp: String(Math.floor(Date.now() / 1000)),
      },
      android: {
        priority: "normal",
      },
    };

    await messaging.sendEachForMulticast(message);
    functions.logger.info(`Notifikasi AMAN terkirim untuk node: ${nodeId}`);
  } catch (error) {
    functions.logger.error("Gagal kirim notifikasi AMAN:", error);
  }
}

// ─── HELPER: Tulis rekaman log intrusi ke /history_logs ──────────────────────
async function writeIntrusionLog(nodeId: string, device: DeviceData): Promise<void> {
  try {
    const serverTimestamp = Math.floor(Date.now() / 1000);
    const logId = `log_${nodeId}_${serverTimestamp}`;

    await db.ref(`${HISTORY_LOGS_PATH}/${logId}`).set({
      device_id: nodeId,
      lokasi: device.nama_lokasi,
      status: STATUS_INTRUSI,
      timestamp: serverTimestamp,
      keterangan: `Terdeteksi intrusi valid - Sensor PIR (panas tubuh) dan Radar Microwave (gerak kinetik) terpicu bersamaan. Level baterai: ${device.baterai}%.`,
      baterai_saat_kejadian: device.baterai,
      rssi_saat_kejadian: device.sinyal_rssi ?? null,
    });

    functions.logger.info(`Log intrusi ditulis: ${logId}`);
  } catch (error) {
    functions.logger.error("Gagal menulis log intrusi:", error);
  }
}

// ─── CLOUD FUNCTION: Bersihkan log lama (berjalan tiap minggu) ───────────────
/**
 * Scheduled function: Hapus log intrusi yang lebih dari 90 hari
 * untuk menjaga database tidak membengkak
 */
export const cleanupOldLogs = functions
  .region("asia-southeast1")
  .pubsub.schedule("every monday 02:00")
  .timeZone("Asia/Jakarta")
  .onRun(async () => {
    const ninetyDaysAgo = Math.floor(Date.now() / 1000) - 90 * 24 * 60 * 60;

    const oldLogsQuery = db.ref(HISTORY_LOGS_PATH)
      .orderByChild("timestamp")
      .endAt(ninetyDaysAgo);

    const snapshot = await oldLogsQuery.get();
    if (!snapshot.exists()) {
      functions.logger.info("Tidak ada log lama untuk dihapus.");
      return null;
    }

    const updates: Record<string, null> = {};
    snapshot.forEach((child) => {
      updates[child.key as string] = null;
    });

    await db.ref(HISTORY_LOGS_PATH).update(updates);
    functions.logger.info(`Dihapus ${Object.keys(updates).length} log intrusi lama (>90 hari).`);
    return null;
  });

// ─── CLOUD FUNCTION: Health check endpoint ───────────────────────────────────
/**
 * HTTPS endpoint untuk memverifikasi Cloud Functions aktif
 * URL: https://asia-southeast1-{projectId}.cloudfunctions.net/healthCheck
 */
export const healthCheck = functions
  .region("asia-southeast1")
  .https.onRequest((req, res) => {
    res.status(200).json({
      status: "ok",
      service: "SawitGuard IoT Cloud Functions",
      timestamp: new Date().toISOString(),
      version: "1.0.0",
    });
  });
