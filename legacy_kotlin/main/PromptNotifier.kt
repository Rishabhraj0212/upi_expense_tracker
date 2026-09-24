package com.rishabh.upi_expense_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object PromptNotifier {
    private const val CHANNEL_ID = "payment_prompt"

    fun show(context: Context, e: Expense, suggestion: String?) {
        ensureChannel(context)

        val open = PendingIntent.getActivity(
            context, e.id.toInt(), promptIntent(context, e.id),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("${Format.rupees(e.amountPaise)} paid${e.payee?.let { " to $it" } ?: ""}")
            .setContentText("What was this for?")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setContentIntent(open)

        val quick = (listOfNotNull(suggestion) + Categories.QUICK_DEFAULTS).distinct().take(3)
        quick.forEachIndexed { i, category ->
            val action = Intent(context, CategoryActionReceiver::class.java)
                .putExtra(CategoryActionReceiver.EXTRA_ID, e.id)
                .putExtra(CategoryActionReceiver.EXTRA_CATEGORY, category)
            val pi = PendingIntent.getBroadcast(
                context, (e.id * 10 + i).toInt(), action,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            builder.addAction(0, if (category == suggestion) "★ $category" else category, pi)
        }

        try {
            NotificationManagerCompat.from(context).notify(e.id.toInt(), builder.build())
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted; the expense still shows up in the app as pending.
        }

        // With "display over other apps" granted, Android lets us start the dialog from the
        // background. Some OEMs / Android 15 still block it, hence the notification above.
        if (Settings.canDrawOverlays(context)) {
            try {
                context.startActivity(promptIntent(context, e.id))
            } catch (_: Exception) {
            }
        }
    }

    fun cancel(context: Context, id: Long) {
        NotificationManagerCompat.from(context).cancel(id.toInt())
    }

    fun promptIntent(context: Context, id: Long): Intent =
        Intent(context, PromptActivity::class.java)
            .putExtra(PromptActivity.EXTRA_ID, id)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Payment prompts", NotificationManager.IMPORTANCE_HIGH)
                .apply { description = "Asks what a UPI payment was for" }
        )
    }
}

object Format {
    /** 125050 -> "₹1,250.50" (Indian digit grouping, paise hidden when zero). */
    fun rupees(paise: Long): String {
        val whole = (paise / 100).toString()
        val grouped = if (whole.length <= 3) whole else {
            val head = whole.dropLast(3).reversed().chunked(2).joinToString(",").reversed()
            "$head,${whole.takeLast(3)}"
        }
        val frac = paise % 100
        return if (frac == 0L) "₹$grouped" else "₹$grouped.${frac.toString().padStart(2, '0')}"
    }
}
