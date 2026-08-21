package de.kamilunavo.keepmeter

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import de.kamilunavo.keepmeter.data.PurchaseWithUsage
import de.kamilunavo.keepmeter.data.toDecisionSnapshot
import de.kamilunavo.keepmeter.domain.AccessPolicy
import de.kamilunavo.keepmeter.domain.DecisionEngine
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class KeepMeterViewModel(application: Application) : AndroidViewModel(application) {
    private val app = application as KeepMeterApplication
    private val repository = app.repository

    val allPurchases = repository.purchases.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = emptyList(),
    )

    val activePurchases = repository.purchases
        .map { items -> items.filter { it.purchase.outcome == "active" } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val archivedPurchases = repository.purchases
        .map { items -> items.filter { it.purchase.outcome != "active" } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun addPurchase(
        name: String,
        merchant: String,
        price: Double,
        returnDeadlineEpochMillis: Long,
        isPro: Boolean,
        onResult: (Boolean) -> Unit,
    ) {
        viewModelScope.launch {
            val activeCount = repository.activeCount()
            if (!AccessPolicy.canAddActivePurchase(activeCount, isPro)) {
                onResult(false)
                return@launch
            }

            val now = System.currentTimeMillis()
            val id = repository.addPurchase(
                name = name,
                merchant = merchant,
                price = price,
                purchaseDateEpochMillis = now,
                returnDeadlineEpochMillis = returnDeadlineEpochMillis,
            )
            ReturnReminderScheduler.schedule(
                context = getApplication(),
                purchaseId = id,
                purchaseName = name.trim(),
                returnDeadlineEpochMillis = returnDeadlineEpochMillis,
            )
            onResult(true)
        }
    }

    fun recordUsage(purchaseId: String) {
        viewModelScope.launch { repository.recordUsage(purchaseId) }
    }

    fun markKept(purchaseId: String) {
        viewModelScope.launch {
            repository.setOutcome(purchaseId, "kept")
            ReturnReminderScheduler.cancel(getApplication(), purchaseId)
        }
    }

    fun markReturned(purchaseId: String) {
        viewModelScope.launch {
            repository.setOutcome(purchaseId, "returned")
            ReturnReminderScheduler.cancel(getApplication(), purchaseId)
        }
    }

    fun deletePurchase(purchaseId: String) {
        viewModelScope.launch {
            repository.deletePurchase(purchaseId)
            ReturnReminderScheduler.cancel(getApplication(), purchaseId)
        }
    }

    fun decision(item: PurchaseWithUsage) = DecisionEngine.evaluate(item.toDecisionSnapshot())
}
