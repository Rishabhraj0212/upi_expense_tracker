package com.rishabh.upi_expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * Capture only, no parsing: stitches a multi-part SMS from the same sender
 * back into one body, then forwards sender+body to Dart. If a live listener
 * is attached (app running), delivery is instant via [SmsEventBridge].
 * Otherwise this falls back to [HeadlessEngineManager], holding the
 * broadcast open via goAsync() long enough for a background engine to
 * process it (best-effort — see Milestone 8 discussion).
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val now = System.currentTimeMillis()
        val needsHeadless = mutableListOf<Pair<String, String>>()
        for ((sender, body) in stitchMultipartMessages(intent)) {
            if (!SmsEventBridge.emit(sender, body, now)) needsHeadless += sender to body
        }
        if (needsHeadless.isEmpty()) return

        val pendingResult = goAsync()
        var remaining = needsHeadless.size
        for ((sender, body) in needsHeadless) {
            HeadlessEngineManager.enqueue(
                context,
                mapOf("kind" to "sms", "origin" to sender, "text" to body, "receivedAt" to now),
            ) {
                remaining--
                if (remaining <= 0) pendingResult.finish()
            }
        }
    }

    companion object {
        /**
         * A long SMS arrives as several parts from the same sender; this
         * joins them back into a single message body per sender.
         */
        fun stitchMultipartMessages(intent: Intent): Map<String, String> =
            Telephony.Sms.Intents.getMessagesFromIntent(intent)
                .groupBy({ it.originatingAddress.orEmpty() }, { it.messageBody.orEmpty() })
                .mapValues { it.value.joinToString("") }
    }
}
