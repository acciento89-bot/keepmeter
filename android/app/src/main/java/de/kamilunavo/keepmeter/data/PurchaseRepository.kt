package de.kamilunavo.keepmeter.data

import de.kamilunavo.keepmeter.domain.PurchaseSnapshot
import java.util.UUID
import kotlinx.coroutines.flow.Flow

class PurchaseRepository(private val dao: PurchaseDao) {
    val purchases: Flow<List<PurchaseWithUsage>> = dao.observeAll()

    suspend fun addPurchase(
        name: String,
        merchant: String,
        price: Double,
        purchaseDateEpochMillis: Long,
        returnDeadlineEpochMillis: Long,
    ): String {
        val id = UUID.randomUUID().toString()
        dao.insertPurchase(
            PurchaseEntity(
                id = id,
                name = name.trim(),
                merchant = merchant.trim(),
                price = price,
                purchaseDateEpochMillis = purchaseDateEpochMillis,
                returnDeadlineEpochMillis = returnDeadlineEpochMillis,
                createdAtEpochMillis = System.currentTimeMillis(),
                outcome = "active",
                archivedAtEpochMillis = null,
            )
        )
        return id
    }

    suspend fun recordUsage(purchaseId: String, timestampEpochMillis: Long = System.currentTimeMillis()) {
        dao.insertUsage(
            UsageEventEntity(
                id = UUID.randomUUID().toString(),
                purchaseId = purchaseId,
                timestampEpochMillis = timestampEpochMillis,
            )
        )
    }

    suspend fun setOutcome(purchaseId: String, outcome: String) {
        val current = dao.getById(purchaseId)?.purchase ?: return
        val archivedAt = if (outcome == "active") null else System.currentTimeMillis()
        dao.updatePurchase(current.copy(outcome = outcome, archivedAtEpochMillis = archivedAt))
    }

    suspend fun deletePurchase(purchaseId: String) {
        dao.deletePurchase(purchaseId)
    }

    suspend fun activeCount(): Int = dao.activePurchaseCount()
}

fun PurchaseWithUsage.toDecisionSnapshot(): PurchaseSnapshot = PurchaseSnapshot(
    price = purchase.price,
    purchaseDateEpochMillis = purchase.purchaseDateEpochMillis,
    returnDeadlineEpochMillis = purchase.returnDeadlineEpochMillis,
    usageTimestampsEpochMillis = usageEvents.map { it.timestampEpochMillis },
)
