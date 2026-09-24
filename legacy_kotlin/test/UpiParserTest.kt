package com.rishabh.upi_expense_tracker

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * The sample texts below are modelled on typical Bank of Baroda / Paytm / super.money
 * wording, not captured from a real device. Replace or add real messages from the app's
 * Captures screen as they show up.
 */
class UpiParserTest {
    @Test
    fun bobDebitWithVpaAndRef() {
        val p = UpiParser.parseSms(
            "Rs.250.00 Dr. from A/c XXXXXX1234 and Cr. to ramesh.tea@ybl. Ref:412345678901. " +
                "AvlBal:Rs5000.50(2026:09:19 10:11:12) Not you? Call 18005700-BOB"
        )
        assertNotNull(p)
        assertEquals(25000L, p!!.amountPaise)
        assertEquals("ramesh.tea@ybl", p.payeeVpa)
        assertEquals("412345678901", p.upiRef)
    }

    @Test
    fun debitedByPhrasingWithGroupedAmount() {
        val p = UpiParser.parseSms(
            "Your a/c XXXXXX1234 is debited by Rs. 1,250.00 on 19-09-26 & credited to " +
                "paytm-123@ptys (UPI Ref no 412345678901)-BOB"
        )
        assertEquals(125000L, p!!.amountPaise)
        assertEquals("paytm-123@ptys", p.payeeVpa)
        assertEquals("412345678901", p.upiRef)
    }

    @Test
    fun debitedFromAccountAndCreditedToPayeeIsStillADebit() {
        val p = UpiParser.parseSms(
            "Rs 99 debited from A/c XX1234 and credited to shop@okaxis via UPI. Ref 412345678903"
        )
        assertEquals(9900L, p!!.amountPaise)
    }

    @Test
    fun incomingCreditIsIgnored() {
        assertNull(
            UpiParser.parseSms("Rs.500.00 Cr. to A/c XXXXXX1234 and Dr. from friend@okaxis. Ref:412345678902")
        )
        assertNull(UpiParser.parseSms("Rs 500 credited to your a/c XX1234 by UPI from friend@okaxis"))
    }

    @Test
    fun nonUpiDebitIsIgnored() {
        assertNull(UpiParser.parseSms("Rs.2000.00 Dr. from A/c XX1234 ATM WDL at MAIN ROAD"))
    }

    @Test
    fun balanceIsNotMistakenForAmount() {
        val p = UpiParser.parseSms("Available Bal Rs 9,999.00. Rs 100 Dr. from A/c XX1 to x@ybl UPI Ref 123456789012")
        assertEquals(10000L, p!!.amountPaise)
    }

    @Test
    fun paytmPaidNotification() {
        val p = UpiParser.parseNotification("net.one97.paytm", "Paid ₹250 to Ramesh Tea Stall", "Payment successful")
        assertEquals(25000L, p!!.amountPaise)
        assertEquals("Ramesh Tea Stall", p.payee)
        assertEquals("Paytm", p.app)
    }

    @Test
    fun superMoneyNotification() {
        val p = UpiParser.parseNotification("money.super.payments", "Payment successful", "₹120 paid to Zomato")
        assertEquals(12000L, p!!.amountPaise)
        assertEquals("Zomato", p.payee)
    }

    @Test
    fun receivedRefundAndPromoNotificationsAreIgnored() {
        val pkg = "net.one97.paytm"
        assertNull(UpiParser.parseNotification(pkg, "Money received", "₹500 received from Amit"))
        assertNull(UpiParser.parseNotification(pkg, "Refund", "₹50 refunded to your account"))
        assertNull(UpiParser.parseNotification(pkg, "Get up to ₹100 cashback", "Pay your bills and win"))
        assertNull(UpiParser.parseNotification(pkg, "Payment failed", "₹250 could not be paid to Ramesh"))
    }

    @Test
    fun otherAppsAreIgnored() {
        assertNull(UpiParser.parseNotification("com.whatsapp", "Paid ₹250 to Ramesh", ""))
    }

    @Test
    fun formatsIndianGrouping() {
        assertEquals("₹250", Format.rupees(25000))
        assertEquals("₹1,250.50", Format.rupees(125050))
        assertEquals("₹1,25,000", Format.rupees(12500000))
    }
}
