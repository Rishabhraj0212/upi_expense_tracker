package com.rishabh.upi_expense_tracker

import android.content.Context

/** Single entry point for both the notification listener and the SMS receiver. */
object PaymentProcessor {
    private val lock = Any()

    fun handle(context: Context, payment: ParsedPayment) {
        val db = ExpenseDb.get(context)
        val now = System.currentTimeMillis()
        val expense = synchronized(lock) {
            val existing = db.findDuplicate(payment, now)
            if (existing != null) {
                db.merge(existing, payment)
                return
            }
            db.get(db.insert(payment, now))
        } ?: return
        PromptNotifier.show(context, expense, db.suggestCategory(expense))
    }
}
