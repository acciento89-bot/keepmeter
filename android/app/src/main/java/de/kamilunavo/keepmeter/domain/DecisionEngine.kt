package de.kamilunavo.keepmeter.domain

import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import kotlin.math.max
import kotlin.math.min

enum class PurchaseOutcome { ACTIVE, KEPT, RETURNED }
enum class DecisionStatus { KEEP, REVIEW, RETURN_CANDIDATE }
enum class DecisionReason {
    DEADLINE_PASSED,
    UNUSED_URGENT,
    LIGHTLY_USED_URGENT,
    UNUSED_LATE_WINDOW,
    REPEATED_USE,
    EARLY_WINDOW,
    NEEDS_MORE_SIGNAL,
}

data class PurchaseSnapshot(
    val price: Double,
    val purchaseDateEpochMillis: Long,
    val returnDeadlineEpochMillis: Long,
    val usageTimestampsEpochMillis: List<Long>,
)

data class DecisionSnapshot(
    val status: DecisionStatus,
    val reason: DecisionReason,
    val daysRemaining: Int,
    val useCount: Int,
    val costPerUse: Double?,
)

object DecisionEngine {
    fun evaluate(
        purchase: PurchaseSnapshot,
        referenceEpochMillis: Long = System.currentTimeMillis(),
        zoneId: ZoneId = ZoneId.systemDefault(),
    ): DecisionSnapshot {
        val referenceDate = Instant.ofEpochMilli(referenceEpochMillis).atZone(zoneId).toLocalDate()
        val deadlineDate = Instant.ofEpochMilli(purchase.returnDeadlineEpochMillis).atZone(zoneId).toLocalDate()
        val daysRemaining = ChronoUnit.DAYS.between(referenceDate, deadlineDate).toInt()
        val useCount = purchase.usageTimestampsEpochMillis.size

        val total = purchase.returnDeadlineEpochMillis - purchase.purchaseDateEpochMillis
        val elapsed = referenceEpochMillis - purchase.purchaseDateEpochMillis
        val elapsedRatio = if (total > 0) min(max(elapsed.toDouble() / total.toDouble(), 0.0), 1.0) else 1.0

        val (status, reason) = when {
            daysRemaining < 0 -> DecisionStatus.REVIEW to DecisionReason.DEADLINE_PASSED
            useCount == 0 && daysRemaining <= 3 -> DecisionStatus.RETURN_CANDIDATE to DecisionReason.UNUSED_URGENT
            useCount <= 1 && daysRemaining <= 3 -> DecisionStatus.REVIEW to DecisionReason.LIGHTLY_USED_URGENT
            useCount == 0 && elapsedRatio >= 0.60 -> DecisionStatus.REVIEW to DecisionReason.UNUSED_LATE_WINDOW
            useCount >= 3 -> DecisionStatus.KEEP to DecisionReason.REPEATED_USE
            elapsedRatio < 0.35 -> DecisionStatus.REVIEW to DecisionReason.EARLY_WINDOW
            else -> DecisionStatus.REVIEW to DecisionReason.NEEDS_MORE_SIGNAL
        }

        return DecisionSnapshot(
            status = status,
            reason = reason,
            daysRemaining = daysRemaining,
            useCount = useCount,
            costPerUse = if (useCount > 0) purchase.price / useCount else null,
        )
    }
}

object AccessPolicy {
    const val FREE_ACTIVE_PURCHASE_LIMIT = 5

    fun canAddActivePurchase(activePurchaseCount: Int, isPro: Boolean): Boolean =
        isPro || activePurchaseCount < FREE_ACTIVE_PURCHASE_LIMIT

    fun hasReachedFreeLimit(activePurchaseCount: Int, isPro: Boolean): Boolean =
        !canAddActivePurchase(activePurchaseCount, isPro)
}
