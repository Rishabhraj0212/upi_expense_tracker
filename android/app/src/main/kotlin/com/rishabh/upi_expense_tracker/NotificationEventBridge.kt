package com.rishabh.upi_expense_tracker

import io.flutter.plugin.common.EventChannel

/**
 * Holds the live EventChannel sink for notification events while Dart is
 * listening (i.e. the Flutter engine is attached). If nobody is listening —
 * the app isn't running — [emit] returns false so the caller can fall back
 * to [HeadlessEngineManager]. Kotlin never parses anything itself.
 */
object NotificationEventBridge : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    /** Returns true if a live listener received the event, false otherwise. */
    fun emit(packageName: String, title: String, text: String, receivedAtMillis: Long): Boolean {
        val s = sink ?: return false
        s.success(
            mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "receivedAt" to receivedAtMillis,
            )
        )
        return true
    }
}
