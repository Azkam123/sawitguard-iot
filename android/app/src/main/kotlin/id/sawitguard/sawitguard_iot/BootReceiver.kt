package id.sawitguard.sawitguard_iot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("BootReceiver", "Broadcast diterima: $action")
        if (Intent.ACTION_BOOT_COMPLETED == action ||
            "id.sawitguard.sawitguard_iot.RESTART_SERVICE" == action ||
            Intent.ACTION_MY_PACKAGE_REPLACED == action
        ) {
            SawitGuardService.startService(context)
        }
    }
}
