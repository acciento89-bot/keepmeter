package de.kamilunavo.keepmeter

import android.app.Application
import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
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
        purchaseDateEpochMillis: Long,
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

            val id = repository.addPurchase(
                name = name,
                merchant = merchant,
                price = price,
                purchaseDateEpochMillis = purchaseDateEpochMillis,
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

    fun updateCategory(purchaseId: String, category: String, onError: () -> Unit) {
        viewModelScope.launch {
            try {
                repository.updateCategory(purchaseId, category)
            } catch (_: Exception) { onError() }
        }
    }

    fun updateReceipt(purchaseId: String, uri: Uri?, onResult: (Boolean) -> Unit) {
        viewModelScope.launch {
            var newPath: String? = null
            try {
                val old = repository.getPurchase(purchaseId) ?: error("Purchase missing")
                if (uri != null) newPath = withContext(Dispatchers.IO) { ReceiptStorage.save(getApplication(), uri) }
                repository.updateReceipt(purchaseId, newPath)
                withContext(Dispatchers.IO) { ReceiptStorage.delete(getApplication(), old.receiptPath) }
                onResult(true)
            } catch (_: Exception) {
                withContext(Dispatchers.IO) { ReceiptStorage.delete(getApplication(), newPath) }
                onResult(false)
            }
        }
    }

    fun deletePurchase(purchaseId: String) {
        viewModelScope.launch {
            val old = repository.getPurchase(purchaseId)
            repository.deletePurchase(purchaseId)
            withContext(Dispatchers.IO) { ReceiptStorage.delete(getApplication(), old?.receiptPath) }
            ReturnReminderScheduler.cancel(getApplication(), purchaseId)
        }
    }

    /** Populates deterministic, real app data for Play Store captures in debug builds only. */
    fun seedStoreScreenshotData() {
        if (!BuildConfig.DEBUG) return
        viewModelScope.launch {
            if (repository.activeCount() > 0) return@launch
            val now = System.currentTimeMillis()
            val day = 24L * 60L * 60L * 1_000L
            val id = repository.addPurchase(
                name = "Kopfhörer",
                merchant = "TechStore",
                price = 179.0,
                purchaseDateEpochMillis = now - (5L * day),
                returnDeadlineEpochMillis = now + (9L * day),
            )
            repeat(7) { index ->
                repository.recordUsage(id, now - ((6L - index) * day))
            }
        }
    }

    fun decision(item: PurchaseWithUsage) = DecisionEngine.evaluate(item.toDecisionSnapshot())
}
