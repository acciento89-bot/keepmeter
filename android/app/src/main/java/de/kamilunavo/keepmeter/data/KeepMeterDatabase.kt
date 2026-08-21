package de.kamilunavo.keepmeter.data

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Relation
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "purchases")
data class PurchaseEntity(
    @androidx.room.PrimaryKey val id: String,
    val name: String,
    val merchant: String,
    val price: Double,
    val purchaseDateEpochMillis: Long,
    val returnDeadlineEpochMillis: Long,
    val createdAtEpochMillis: Long,
    val outcome: String,
    val archivedAtEpochMillis: Long?,
)

@Entity(
    tableName = "usage_events",
    foreignKeys = [
        ForeignKey(
            entity = PurchaseEntity::class,
            parentColumns = ["id"],
            childColumns = ["purchaseId"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [Index("purchaseId")],
)
data class UsageEventEntity(
    @androidx.room.PrimaryKey val id: String,
    val purchaseId: String,
    val timestampEpochMillis: Long,
)

data class PurchaseWithUsage(
    @Embedded val purchase: PurchaseEntity,
    @Relation(parentColumn = "id", entityColumn = "purchaseId")
    val usageEvents: List<UsageEventEntity>,
)

@Dao
interface PurchaseDao {
    @Transaction
    @Query("SELECT * FROM purchases ORDER BY returnDeadlineEpochMillis ASC, createdAtEpochMillis DESC")
    fun observeAll(): Flow<List<PurchaseWithUsage>>

    @Transaction
    @Query("SELECT * FROM purchases WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): PurchaseWithUsage?

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertPurchase(purchase: PurchaseEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertUsage(event: UsageEventEntity)

    @Update
    suspend fun updatePurchase(purchase: PurchaseEntity)

    @Query("DELETE FROM purchases WHERE id = :id")
    suspend fun deletePurchase(id: String)

    @Query("SELECT COUNT(*) FROM purchases WHERE outcome = 'active'")
    suspend fun activePurchaseCount(): Int
}

@Database(
    entities = [PurchaseEntity::class, UsageEventEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class KeepMeterDatabase : RoomDatabase() {
    abstract fun purchaseDao(): PurchaseDao

    companion object {
        @Volatile private var instance: KeepMeterDatabase? = null

        fun get(context: Context): KeepMeterDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(
                context.applicationContext,
                KeepMeterDatabase::class.java,
                "keepmeter.db",
            ).build().also { instance = it }
        }
    }
}
