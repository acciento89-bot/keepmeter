package de.kamilunavo.keepmeter

import android.app.Application
import de.kamilunavo.keepmeter.data.KeepMeterDatabase
import de.kamilunavo.keepmeter.data.PurchaseRepository

class KeepMeterApplication : Application() {
    val database by lazy { KeepMeterDatabase.get(this) }
    val repository by lazy { PurchaseRepository(database.purchaseDao()) }
}
