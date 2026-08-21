package de.kamilunavo.keepmeter.domain

import java.time.LocalDate
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DecisionEngineTest {
    private fun epoch(date: LocalDate): Long = date.atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli()

    @Test
    fun unusedPurchaseNearDeadlineIsReturnCandidate() {
        val now = LocalDate.of(2026, 8, 21)
        val snapshot = PurchaseSnapshot(
            price = 100.0,
            purchaseDateEpochMillis = epoch(now.minusDays(10)),
            returnDeadlineEpochMillis = epoch(now.plusDays(2)),
            usageTimestampsEpochMillis = emptyList(),
        )
        val result = DecisionEngine.evaluate(snapshot, epoch(now), ZoneOffset.UTC)
        assertEquals(DecisionStatus.RETURN_CANDIDATE, result.status)
        assertEquals(DecisionReason.UNUSED_URGENT, result.reason)
    }

    @Test
    fun repeatedUseProducesKeep() {
        val now = LocalDate.of(2026, 8, 21)
        val snapshot = PurchaseSnapshot(
            price = 90.0,
            purchaseDateEpochMillis = epoch(now.minusDays(10)),
            returnDeadlineEpochMillis = epoch(now.plusDays(10)),
            usageTimestampsEpochMillis = listOf(epoch(now.minusDays(5)), epoch(now.minusDays(3)), epoch(now.minusDays(1))),
        )
        val result = DecisionEngine.evaluate(snapshot, epoch(now), ZoneOffset.UTC)
        assertEquals(DecisionStatus.KEEP, result.status)
        assertEquals(30.0, result.costPerUse!!, 0.0001)
    }

    @Test
    fun passedDeadlineNeedsReview() {
        val now = LocalDate.of(2026, 8, 21)
        val snapshot = PurchaseSnapshot(50.0, epoch(now.minusDays(20)), epoch(now.minusDays(1)), emptyList())
        val result = DecisionEngine.evaluate(snapshot, epoch(now), ZoneOffset.UTC)
        assertEquals(DecisionReason.DEADLINE_PASSED, result.reason)
    }

    @Test
    fun freeLimitMatchesIosPolicy() {
        assertTrue(AccessPolicy.canAddActivePurchase(4, false))
        assertFalse(AccessPolicy.canAddActivePurchase(5, false))
        assertTrue(AccessPolicy.canAddActivePurchase(99, true))
    }
}
