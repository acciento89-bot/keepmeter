package de.kamilunavo.keepmeter

import android.app.Activity
import android.app.Instrumentation
import android.content.ContentValues
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.provider.MediaStore
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.espresso.Espresso.pressBack
import androidx.test.espresso.intent.Intents
import androidx.test.espresso.intent.matcher.IntentMatchers.hasAction
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.regex.Pattern

/** Runs only on our isolated native QA device. No billing buttons or real transactions. */
@RunWith(AndroidJUnit4::class)
class PurchaseCentreNativeTest {
    @get:Rule val compose = createEmptyComposeRule()
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private val device = UiDevice.getInstance(instrumentation)
    private val proofs get() = File(context.filesDir, "native-qa").apply { mkdirs() }
    private fun photo(name: String) { device.takeScreenshot(File(proofs, "$name.png")) }
    private fun waitText(text: String) = compose.waitUntil(15_000) { compose.onAllNodesWithText(text).fetchSemanticsNodes().isNotEmpty() }
    private fun dbText(sql: String): String = SQLiteDatabase.openDatabase(context.getDatabasePath("keepmeter.db").path, null, SQLiteDatabase.OPEN_READONLY).use { db -> db.rawQuery(sql, null).use { c -> check(c.moveToFirst()); c.getString(0) } }

    @Test fun legacyPurchasesCategoriesReceiptSearchAndExportSurviveRecreation() {
        check(BuildConfig.DEBUG)
        instrumentation.uiAutomation.executeShellCommand("rm -f /sdcard/Download/KeepMeter-Purchases.csv").close()
        context.deleteDatabase("keepmeter.db") // Dedicated QA device, fixture database only.
        context.getDatabasePath("keepmeter.db").parentFile!!.mkdirs()
        val now = System.currentTimeMillis(); val day = 86400000L
        SQLiteDatabase.openOrCreateDatabase(context.getDatabasePath("keepmeter.db"), null).use { db ->
            db.execSQL("CREATE TABLE purchases(id TEXT NOT NULL PRIMARY KEY,name TEXT NOT NULL,merchant TEXT NOT NULL,price REAL NOT NULL,purchaseDateEpochMillis INTEGER NOT NULL,returnDeadlineEpochMillis INTEGER NOT NULL,createdAtEpochMillis INTEGER NOT NULL,outcome TEXT NOT NULL,archivedAtEpochMillis INTEGER)")
            db.execSQL("CREATE TABLE usage_events(id TEXT NOT NULL PRIMARY KEY,purchaseId TEXT NOT NULL,timestampEpochMillis INTEGER NOT NULL,FOREIGN KEY(purchaseId) REFERENCES purchases(id) ON UPDATE NO ACTION ON DELETE CASCADE)")
            db.execSQL("CREATE INDEX index_usage_events_purchaseId ON usage_events(purchaseId)")
            listOf(Triple("Kopfhörer",179.9,3),Triple("Regenjacke",89.0,12)).forEachIndexed { index, (name,price,days) ->
                db.execSQL("INSERT INTO purchases VALUES(?,?,?,?,?,?,?,?,?)", arrayOf<Any?>("legacy-$index",name,"QA Laden",price,now-day*5,now+day*days,now-index*day,"active",null))
                db.execSQL("INSERT INTO usage_events VALUES(?,?,?)", arrayOf<Any?>("use-$index","legacy-$index",now-day))
            }
            db.version = 1
        }
        context.getSharedPreferences("keepmeter",0).edit().putBoolean("onboarding_done", true).commit()
        val intent = Intent(context, MainActivity::class.java).putExtra("de.kamilunavo.keepmeter.STORE_SCREENSHOTS",true)
        val scenario = ActivityScenario.launch<MainActivity>(intent)
        try {
            waitText("Kopfhörer")
            assertEquals("2", dbText("PRAGMA user_version"))
            assertEquals("2", dbText("SELECT COUNT(*) FROM purchases"))
            assertEquals("other", dbText("SELECT category FROM purchases WHERE id='legacy-0'"))
            photo("01-legacy-purchases")
            compose.onNodeWithText("Kopfhörer").performClick()
            waitText("Kategorie: Sonstiges")
            compose.onNodeWithText("Kategorie: Sonstiges").performScrollTo().performClick()
            compose.onNodeWithText("Technik").performClick()
            compose.waitUntil(10_000) { dbText("SELECT category FROM purchases WHERE id='legacy-0'") == "tech" }
            val values = ContentValues().apply { put(MediaStore.Images.Media.DISPLAY_NAME,"KeepMeter-QA-Beleg.jpg");put(MediaStore.Images.Media.MIME_TYPE,"image/jpeg") }
            val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
            val image = Bitmap.createBitmap(600,900,Bitmap.Config.ARGB_8888)
            Canvas(image).apply { drawColor(Color.WHITE);drawText("KeepMeter QA Receipt",35f,100f,Paint().apply { color=Color.BLACK;textSize=30f });drawText("EUR 179.90",35f,200f,Paint().apply { color=Color.BLACK;textSize=30f }) }
            context.contentResolver.openOutputStream(uri)!!.use { image.compress(Bitmap.CompressFormat.JPEG,95,it) };image.recycle()
            Intents.init()
            try {
                Intents.intending(hasAction(Intent.ACTION_GET_CONTENT)).respondWith(Instrumentation.ActivityResult(Activity.RESULT_OK,Intent().setData(uri)))
                compose.onNodeWithText("Belegfoto hinzufügen").performScrollTo().performClick()
                compose.waitUntil(10_000) { dbText("SELECT COALESCE(receiptPath,'') FROM purchases WHERE id='legacy-0'").isNotEmpty() }
                val path=dbText("SELECT receiptPath FROM purchases WHERE id='legacy-0'");assertTrue(File(path).length()>0)
                compose.onNodeWithContentDescription("Belegfoto").assertExists()
                photo("02-purchase-folder")
            } finally { Intents.release() }
            pressBack(); waitText("Kopfhörer")
            compose.onNode(hasSetTextAction()).performTextInput("regen")
            compose.onNodeWithText("Kopfhörer").assertDoesNotExist();compose.onNodeWithText("Regenjacke").assertExists()
            compose.onNode(isToggleable()).performClick()
            compose.onNodeWithText("Regenjacke").assertDoesNotExist()
            compose.onNode(hasSetTextAction()).performTextClearance();compose.onNode(isToggleable()).performClick()
            compose.onNodeWithText("Kategorie: Alle Kategorien").performScrollTo().performClick();compose.onNodeWithText("Technik").performClick()
            compose.onNodeWithText("Regenjacke").assertDoesNotExist();compose.onNodeWithText("Kopfhörer").assertExists()
            device.pressBack(); compose.waitForIdle(); photo("03-search-categories")
            compose.onNodeWithText("Einstellungen").performClick()
            compose.onNodeWithText("Käufe exportieren (CSV)").performScrollTo().performClick()
            // Real system picker stays open through rotation. This catches the reviewed empty-file regression.
            assertTrue(device.wait(Until.hasObject(By.pkg("com.google.android.documentsui")),15_000))
            device.setOrientationLeft()
            val save=device.wait(Until.findObject(By.text(Pattern.compile("(?i)save|speichern"))),15_000)
            assertNotNull("System document Save button",save)
            device.dumpWindowHierarchy(File(proofs,"export-before-save.xml")); photo("export-before-save")
            save.click()
            device.waitForIdle(); device.dumpWindowHierarchy(File(proofs,"export-after-save.xml")); photo("export-after-save")
            device.setOrientationNatural()
            // Scoped storage deliberately hides a system-created CSV from broad MediaStore queries.
            // Read only our known fixture export through the instrumentation shell identity.
            var exported=""
            compose.waitUntil(15_000) {
                instrumentation.uiAutomation.executeShellCommand("cat /sdcard/Download/KeepMeter-Purchases.csv").use { descriptor ->
                    android.os.ParcelFileDescriptor.AutoCloseInputStream(descriptor).bufferedReader().use { exported=it.readText() }
                }
                exported.contains("Kopfhörer") && exported.contains("Regenjacke")
            }
            assertTrue(exported.contains("Technik"));assertTrue(exported.contains("179.90"))
            File(proofs,"native-export.csv").writeText(exported)
            photo("04-export-complete")
            scenario.recreate();waitText("Einstellungen")
            assertEquals("tech", dbText("SELECT category FROM purchases WHERE id='legacy-0'"))
            assertTrue(File(dbText("SELECT receiptPath FROM purchases WHERE id='legacy-0'")).isFile)
            File(proofs,"result.json").writeText("""{"passed":true,"legacyMigration":true,"receiptImportedAndPersisted":true,"categoryPersisted":true,"searchAndDueFilters":true,"csvAfterPickerRotation":true,"billingTransactions":false}""")
        } finally { device.unfreezeRotation(); scenario.close() }
    }
}
