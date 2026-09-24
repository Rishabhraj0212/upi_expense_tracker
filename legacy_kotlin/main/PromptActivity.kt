package com.rishabh.upi_expense_tracker

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.EditText
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Small dialog shown right after a payment is detected: "₹250 paid to X - what was this for?"
 * Built from plain views so it opens instantly, without starting the Flutter engine.
 */
class PromptActivity : Activity() {
    private var expenseId = -1L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setFinishOnTouchOutside(true)
        render(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        render(intent)
    }

    private fun render(intent: Intent) {
        expenseId = intent.getLongExtra(EXTRA_ID, -1)
        val db = ExpenseDb.get(this)
        val expense = db.get(expenseId)
        if (expense == null || expense.category != null) {
            finish()
            return
        }
        val suggestion = db.suggestCategory(expense)

        val pad = dp(20)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad, pad, pad)
        }
        root.addView(TextView(this).apply {
            text = "${Format.rupees(expense.amountPaise)} paid"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        })
        expense.payee?.let { payee ->
            root.addView(TextView(this).apply {
                text = "to $payee"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            })
        }
        root.addView(TextView(this).apply {
            text = "What was this for?"
            setPadding(0, dp(16), 0, dp(8))
        })

        val note = EditText(this).apply {
            hint = "Note (optional)"
            setSingleLine()
        }
        val grid = GridLayout(this).apply { columnCount = 3 }
        val ordered = (listOfNotNull(suggestion) + Categories.ALL).distinct()
        for (category in ordered) {
            grid.addView(Button(this).apply {
                text = if (category == suggestion) "★ $category" else category
                isAllCaps = false
                setOnClickListener { save(category, note.text.toString()) }
            }, GridLayout.LayoutParams(
                GridLayout.spec(GridLayout.UNDEFINED, 1f),
                GridLayout.spec(GridLayout.UNDEFINED, 1f),
            ).apply { width = 0 })
        }
        root.addView(grid)
        root.addView(note)
        root.addView(Button(this).apply {
            text = "Later"
            isAllCaps = false
            setOnClickListener { finish() }
        }, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { gravity = Gravity.END })

        setContentView(root)
    }

    private fun save(category: String, note: String) {
        ExpenseDb.get(this).setCategory(expenseId, category, note)
        PromptNotifier.cancel(this, expenseId)
        finish()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    companion object {
        const val EXTRA_ID = "expense_id"
    }
}
