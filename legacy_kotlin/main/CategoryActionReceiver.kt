package com.rishabh.upi_expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Handles the one-tap category buttons on the payment notification. */
class CategoryActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getLongExtra(EXTRA_ID, -1)
        val category = intent.getStringExtra(EXTRA_CATEGORY) ?: return
        if (id < 0) return
        ExpenseDb.get(context).setCategory(id, category, null)
        PromptNotifier.cancel(context, id)
    }

    companion object {
        const val EXTRA_ID = "expense_id"
        const val EXTRA_CATEGORY = "category"
    }
}
