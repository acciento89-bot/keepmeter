package de.kamilunavo.keepmeter

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit

class ReturnReminderWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val purchaseName = inputData.getString(KEY_NAME) ?: return Result.failure()
        val daysBefore = inputData.getInt(KEY_DAYS_BEFORE, 0)

        if (android.os.Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return Result.success()
        }

        ensureChannel(applicationContext)
        val body = when (daysBefore) {
            0 -> "$purchaseName: Die Rückgabefrist endet heute."
            1 -> "$purchaseName: Die Rückgabefrist endet morgen."
            else -> "$purchaseName: Noch $daysBefore Tage bis zum Ende der Rückgabefrist."
        }
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("KeepMeter · Rückgabefrist")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        NotificationManagerCompat.from(applicationContext).notify(id.hashCode(), notification)
        return Result.success()
    }

    private fun ensureChannel(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Rückgabefristen",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = "Erinnerungen vor dem Ende einer Rückgabefrist"
                }
            )
        }
    }

    companion object {
        const val KEY_NAME = "purchase_name"
        const val KEY_DAYS_BEFORE = "days_before"
        const val CHANNEL_ID = "return_deadlines"
    }
}

object ReturnReminderScheduler {
    private val reminderOffsets = listOf(3, 1, 0)

    fun schedule(
        context: Context,
        purchaseId: String,
        purchaseName: String,
        returnDeadlineEpochMillis: Long,
        zoneId: ZoneId = ZoneId.systemDefault(),
    ) {
        cancel(context, purchaseId)
        val deadline = Instant.ofEpochMilli(returnDeadlineEpochMillis).atZone(zoneId).toLocalDate()
        val workManager = WorkManager.getInstance(context)

        reminderOffsets.forEach { daysBefore ->
            val target: ZonedDateTime = deadline
                .minusDays(daysBefore.toLong())
                .atTime(10, 0)
                .atZone(zoneId)
            val delayMillis = Duration.between(ZonedDateTime.now(zoneId), target).toMillis()
            if (delayMillis <= 0) return@forEach

            val input = Data.Builder()
                .putString(ReturnReminderWorker.KEY_NAME, purchaseName)
                .putInt(ReturnReminderWorker.KEY_DAYS_BEFORE, daysBefore)
                .build()
            val request = OneTimeWorkRequestBuilder<ReturnReminderWorker>()
                .setInputData(input)
                .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
                .addTag(tagFor(purchaseId))
                .build()
            workManager.enqueue(request)
        }
    }

    fun cancel(context: Context, purchaseId: String) {
        WorkManager.getInstance(context).cancelAllWorkByTag(tagFor(purchaseId))
    }

    private fun tagFor(purchaseId: String): String = "return-$purchaseId"
}
