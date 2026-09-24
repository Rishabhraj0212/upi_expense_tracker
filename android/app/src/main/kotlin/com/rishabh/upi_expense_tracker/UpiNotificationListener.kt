package com.rishabh.upi_expense_tracker

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Capture only, no parsing: forwards title+text from known UPI/payment apps.
 * If a live listener is attached (app running), delivery is instant via
 * [NotificationEventBridge]. Otherwise this falls back to
 * [HeadlessEngineManager] — no goAsync()-style extension needed here, since
 * this service being bound already keeps the hosting process alive.
 *
 * Filtering by package here (rather than forwarding every notification on
 * the device) is a deliberate privacy/noise call, not business logic: this
 * service otherwise sees every notification system-wide, and most of that
 * is unrelated personal content that has no reason to flow through the
 * pipeline or into the on-device capture log at all.
 */
class UpiNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName
        if (pkg !in KNOWN_UPI_APP_PACKAGES) return
        if (sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        if (title.isEmpty() && text.isEmpty()) return

        val now = System.currentTimeMillis()
        if (NotificationEventBridge.emit(pkg, title, text, now)) return

        HeadlessEngineManager.enqueue(
            applicationContext,
            mapOf("kind" to "notification", "packageName" to pkg, "title" to title, "text" to text, "receivedAt" to now),
        ) {}
    }

    companion object {
        // Keep in sync with lib/parsing/notification/upi_apps.dart.
        private val KNOWN_UPI_APP_PACKAGES = setOf(
            "com.google.android.apps.nbu.paisa.user",
            "com.phonepe.app",
            "net.one97.paytm",
            "in.org.npci.upiapp",
            "money.super.payments",
            "com.dreamplug.androidapp",
        )
    }
}
