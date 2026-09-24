package com.rishabh.upi_expense_tracker

import java.math.BigDecimal

enum class Source(val id: String) { SMS("sms"), NOTIFICATION("notif") }

data class ParsedPayment(
    val amountPaise: Long,
    val payee: String?,
    val payeeVpa: String?,
    val upiRef: String?,
    val source: Source,
    val app: String?,
    val raw: String,
)

/**
 * Pure text parsing, no Android APIs, so it can be unit tested on the JVM.
 * Only outgoing (debit) UPI payments are returned; credits, refunds, requests and
 * promos yield null.
 */
object UpiParser {
    /** Notification sources we listen to. Add another UPI app by adding one line. */
    val UPI_APPS = mapOf(
        "net.one97.paytm" to "Paytm",
        "money.super.payments" to "super.money",
    )

    private const val AMT = """(?:\brs\.?|\binr|₹)\s*([\d,]+(?:\.\d{1,2})?)"""
    private val amountRx = Regex(AMT, RegexOption.IGNORE_CASE)

    private val vpaRx = Regex("""[\w.\-]{2,}@[a-z][a-z0-9]{1,}""", RegexOption.IGNORE_CASE)
    private val refRx = Regex(
        """(?:ref(?:erence)?\.?(?:\s*no\.?)?|utr|rrn)\s*[:\-#]?\s*(\d{9,14})""",
        RegexOption.IGNORE_CASE,
    )

    // "Dr. from A/c XX1234", "debited from your a/c", "A/c XX1234 is debited"
    private const val ACCT = """(?:a/c|acct?|account)"""
    private const val ACCT_NO = """$ACCT\s*(?:no\.?\s*)?[x*\d]+\s+(?:is\s+|has\s+been\s+)?"""
    private val debitRx = Regex(
        """\b(?:dr|debited|debit)\b\.?(?:\s+(?:from|by|in|of))?\s*(?:your\s+)?$ACCT\b|\b${ACCT_NO}debited\b""",
        RegexOption.IGNORE_CASE,
    )
    private val creditToUserRx = Regex(
        """\b(?:cr|credited|credit)\b\.?(?:\s+(?:to|in|by))?\s*(?:your\s+)?$ACCT\b|\b${ACCT_NO}credited\b""",
        RegexOption.IGNORE_CASE,
    )

    private val smsPayeeVpaRx = Regex(
        """\b(?:cr|credited)\b\.?\s*(?:to|in)?\s*(?:vpa\s*)?([\w.\-]{2,}@[a-z][a-z0-9]+)""",
        RegexOption.IGNORE_CASE,
    )
    private val smsPayeeNameRx = Regex(
        """\b(?:trf\s+to|transfer(?:red)?\s+to|paid\s+to|sent\s+to|towards)\s+([A-Za-z0-9][A-Za-z0-9 &'\-]{1,40}?)(?=\s+(?:ref|upi|utr|on|via|from)\b|[.(,]|$)""",
        RegexOption.IGNORE_CASE,
    )

    private val notifPaidRx = Regex(
        """\b(?:paid|sent|payment\s+(?:of\s+)?(?:rs\.?|inr|₹)?\s*[\d,.]+\s+successful|successfully\s+(?:paid|sent)|debited)\b""",
        RegexOption.IGNORE_CASE,
    )
    private val notifRejectRx = Regex(
        """\b(?:received|credited|refund(?:ed)?|cashback|request(?:ed|s)?|fail(?:ed|ure)?|pending|declined|reminder|due|offer|reward|scratch|won|get\s+up\s+to)\b""",
        RegexOption.IGNORE_CASE,
    )
    private val notifPayeeRx = Regex(
        """\bto\s+([^\n.!,(]{2,40}?)(?=\s+(?:on|via|using|from|with|successfully)\b|[.!,(\n]|$)""",
        RegexOption.IGNORE_CASE,
    )

    fun parseSms(body: String): ParsedPayment? {
        val text = body.replace('\n', ' ')
        if (!debitRx.containsMatchIn(text)) return null
        if (creditToUserRx.containsMatchIn(text)) return null
        val vpa = smsPayeeVpaRx.find(text)?.groupValues?.get(1)
            ?: vpaRx.find(text)?.value
        if (vpa == null && !text.contains("upi", ignoreCase = true)) return null

        val amount = firstAmount(text) ?: return null
        val name = if (vpa == null) smsPayeeNameRx.find(text)?.groupValues?.get(1)?.trim() else null
        return ParsedPayment(
            amountPaise = amount,
            payee = name ?: vpa,
            payeeVpa = vpa,
            upiRef = refRx.find(text)?.groupValues?.get(1),
            source = Source.SMS,
            app = null,
            raw = body,
        )
    }

    fun parseNotification(packageName: String, title: String, text: String): ParsedPayment? {
        val app = UPI_APPS[packageName] ?: return null
        val combined = "$title. $text".replace('\n', ' ')
        if (notifRejectRx.containsMatchIn(combined)) return null
        if (!notifPaidRx.containsMatchIn(combined)) return null

        val amount = firstAmount(combined) ?: return null
        val payee = notifPayeeRx.find(combined)?.groupValues?.get(1)?.trim()
        return ParsedPayment(
            amountPaise = amount,
            payee = payee,
            payeeVpa = payee?.takeIf { it.contains('@') },
            upiRef = refRx.find(combined)?.groupValues?.get(1),
            source = Source.NOTIFICATION,
            app = app,
            raw = "$title | $text",
        )
    }

    /** Cheap check used to decide whether an SMS is worth keeping in the debug log. */
    fun looksLikeBankTxn(body: String): Boolean =
        amountRx.containsMatchIn(body) &&
            Regex("""\b(?:dr|cr|debited|credited)\b""", RegexOption.IGNORE_CASE).containsMatchIn(body)

    /** First amount that is not an available/closing balance. */
    private fun firstAmount(text: String): Long? {
        for (m in amountRx.findAll(text)) {
            val before = text.substring(maxOf(0, m.range.first - 14), m.range.first)
            if (before.contains("bal", ignoreCase = true)) continue
            val value = m.groupValues[1].replace(",", "").toBigDecimalOrNull() ?: continue
            if (value <= BigDecimal.ZERO) continue
            return value.movePointRight(2).toLong()
        }
        return null
    }
}
