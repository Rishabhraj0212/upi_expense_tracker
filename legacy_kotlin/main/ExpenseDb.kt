package com.rishabh.upi_expense_tracker

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

object Categories {
    val ALL = listOf(
        "Food", "Groceries", "Travel", "Shopping", "Bills", "Recharge",
        "Health", "Entertainment", "Rent", "Transfer", "Other",
    )

    /** Ordered so the first three are the default quick actions on the notification. */
    val QUICK_DEFAULTS = listOf("Food", "Groceries", "Travel", "Shopping", "Other")
}

data class Expense(
    val id: Long,
    val amountPaise: Long,
    val payee: String?,
    val payeeVpa: String?,
    val upiRef: String?,
    val sources: String,
    val app: String?,
    val category: String?,
    val note: String?,
    val createdAt: Long,
    val raw: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "amountPaise" to amountPaise,
        "payee" to payee,
        "payeeVpa" to payeeVpa,
        "upiRef" to upiRef,
        "sources" to sources,
        "app" to app,
        "category" to category,
        "note" to note,
        "createdAt" to createdAt,
        "raw" to raw,
    )
}

class ExpenseDb private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, "expenses.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """CREATE TABLE expenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount_paise INTEGER NOT NULL,
                payee TEXT, payee_vpa TEXT, upi_ref TEXT,
                sources TEXT NOT NULL, app TEXT,
                category TEXT, note TEXT,
                created_at INTEGER NOT NULL,
                raw TEXT)"""
        )
        db.execSQL("CREATE INDEX idx_expenses_created ON expenses(created_at)")
        db.execSQL("CREATE TABLE payee_memory (key TEXT PRIMARY KEY, category TEXT NOT NULL)")
        db.execSQL(
            """CREATE TABLE captures (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ts INTEGER NOT NULL, source TEXT NOT NULL, origin TEXT,
                text TEXT NOT NULL, result TEXT NOT NULL)"""
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

    // ---- expenses -------------------------------------------------------------------------

    fun insert(p: ParsedPayment, now: Long): Long {
        val v = ContentValues().apply {
            put("amount_paise", p.amountPaise)
            put("payee", p.payee)
            put("payee_vpa", p.payeeVpa)
            put("upi_ref", p.upiRef)
            put("sources", p.source.id)
            put("app", p.app)
            put("created_at", now)
            put("raw", p.raw)
        }
        return writableDatabase.insertOrThrow("expenses", null, v)
    }

    /**
     * The same real-world payment usually arrives twice (app notification + bank SMS).
     * - same UPI ref            -> same payment
     * - same amount, other source, within 5 min -> same payment
     * - same amount, same source, same payee, within 60 s -> repeated notification
     */
    fun findDuplicate(p: ParsedPayment, now: Long): Expense? {
        p.upiRef?.let { ref ->
            query("upi_ref = ?", arrayOf(ref), 1).firstOrNull()?.let { return it }
        }
        val recent = query(
            "amount_paise = ? AND created_at >= ?",
            arrayOf(p.amountPaise.toString(), (now - MERGE_WINDOW_MS).toString()),
            5,
        )
        return recent.firstOrNull { e ->
            if (p.source.id !in e.sources.split(',')) true
            else now - e.createdAt <= REPEAT_WINDOW_MS &&
                e.payee?.lowercase() == p.payee?.lowercase()
        }
    }

    /** Fills gaps and prefers a human name over a bare VPA. */
    fun merge(existing: Expense, p: ParsedPayment) {
        val v = ContentValues()
        if (existing.upiRef == null && p.upiRef != null) v.put("upi_ref", p.upiRef)
        if (existing.payeeVpa == null && p.payeeVpa != null) v.put("payee_vpa", p.payeeVpa)
        if (existing.app == null && p.app != null) v.put("app", p.app)
        val betterName = p.payee != null && !p.payee.contains('@') &&
            (existing.payee == null || existing.payee.contains('@'))
        if (betterName) v.put("payee", p.payee)
        else if (existing.payee == null && p.payee != null) v.put("payee", p.payee)
        val sources = existing.sources.split(',')
        if (p.source.id !in sources) v.put("sources", (sources + p.source.id).joinToString(","))
        if (v.size() > 0) writableDatabase.update("expenses", v, "id = ?", arrayOf(existing.id.toString()))
    }

    fun get(id: Long): Expense? = query("id = ?", arrayOf(id.toString()), 1).firstOrNull()

    fun list(limit: Int): List<Expense> = query(null, null, limit)

    fun setCategory(id: Long, category: String, note: String?) {
        val v = ContentValues().apply {
            put("category", category)
            put("note", note?.trim()?.takeIf { it.isNotEmpty() })
        }
        writableDatabase.update("expenses", v, "id = ?", arrayOf(id.toString()))
        get(id)?.let { e ->
            for (key in payeeKeys(e)) rememberPayee(key, category)
        }
    }

    fun delete(id: Long) {
        writableDatabase.delete("expenses", "id = ?", arrayOf(id.toString()))
    }

    // ---- payee -> category memory -------------------------------------------------------

    fun suggestCategory(e: Expense): String? {
        for (key in payeeKeys(e)) {
            readableDatabase.rawQuery(
                "SELECT category FROM payee_memory WHERE key = ?", arrayOf(key)
            ).use { if (it.moveToFirst()) return it.getString(0) }
        }
        return null
    }

    private fun rememberPayee(key: String, category: String) {
        val v = ContentValues().apply { put("key", key); put("category", category) }
        writableDatabase.insertWithOnConflict("payee_memory", null, v, SQLiteDatabase.CONFLICT_REPLACE)
    }

    private fun payeeKeys(e: Expense): List<String> =
        listOfNotNull(e.payeeVpa, e.payee).map { it.trim().lowercase() }.filter { it.isNotEmpty() }.distinct()

    // ---- raw capture log (for tuning parsers against real messages) ----------------------

    fun logCapture(source: Source, origin: String?, text: String, result: String, now: Long) {
        val v = ContentValues().apply {
            put("ts", now); put("source", source.id); put("origin", origin)
            put("text", text); put("result", result)
        }
        val db = writableDatabase
        db.insert("captures", null, v)
        db.execSQL(
            "DELETE FROM captures WHERE id NOT IN (SELECT id FROM captures ORDER BY id DESC LIMIT $CAPTURE_CAP)"
        )
    }

    fun captures(limit: Int): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        readableDatabase.rawQuery(
            "SELECT ts, source, origin, text, result FROM captures ORDER BY id DESC LIMIT ?",
            arrayOf(limit.toString()),
        ).use { c ->
            while (c.moveToNext()) {
                out += mapOf(
                    "ts" to c.getLong(0), "source" to c.getString(1), "origin" to c.getString(2),
                    "text" to c.getString(3), "result" to c.getString(4),
                )
            }
        }
        return out
    }

    fun clearCaptures() {
        writableDatabase.delete("captures", null, null)
    }

    // ---- helpers ------------------------------------------------------------------------

    private fun query(where: String?, args: Array<String>?, limit: Int): List<Expense> {
        val out = mutableListOf<Expense>()
        readableDatabase.query(
            "expenses", null, where, args, null, null, "created_at DESC", limit.toString()
        ).use { c -> while (c.moveToNext()) out += c.toExpense() }
        return out
    }

    private fun Cursor.toExpense() = Expense(
        id = getLong(getColumnIndexOrThrow("id")),
        amountPaise = getLong(getColumnIndexOrThrow("amount_paise")),
        payee = getStringOrNull("payee"),
        payeeVpa = getStringOrNull("payee_vpa"),
        upiRef = getStringOrNull("upi_ref"),
        sources = getString(getColumnIndexOrThrow("sources")),
        app = getStringOrNull("app"),
        category = getStringOrNull("category"),
        note = getStringOrNull("note"),
        createdAt = getLong(getColumnIndexOrThrow("created_at")),
        raw = getStringOrNull("raw"),
    )

    private fun Cursor.getStringOrNull(col: String): String? {
        val i = getColumnIndexOrThrow(col)
        return if (isNull(i)) null else getString(i)
    }

    companion object {
        private const val MERGE_WINDOW_MS = 5 * 60_000L
        private const val REPEAT_WINDOW_MS = 60_000L
        private const val CAPTURE_CAP = 200

        @Volatile private var instance: ExpenseDb? = null
        fun get(context: Context): ExpenseDb =
            instance ?: synchronized(this) {
                instance ?: ExpenseDb(context).also { instance = it }
            }
    }
}
