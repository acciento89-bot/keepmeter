package de.kamilunavo.keepmeter

import android.app.LocaleManager
import android.content.Intent
import android.graphics.*
import android.os.LocaleList
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.espresso.Espresso.pressBack
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import de.kamilunavo.keepmeter.data.*
import kotlinx.coroutines.runBlocking
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.Locale

/** Real app gallery using synthetic local purchases. Never opens billing or restoration. */
@RunWith(AndroidJUnit4::class)
class StoreGalleryNativeTest {
 @get:Rule val compose = createEmptyComposeRule()
 private val instrumentation = InstrumentationRegistry.getInstrumentation()
 private val context = instrumentation.targetContext
 private val device = UiDevice.getInstance(instrumentation)
 private fun waitText(text:String) = compose.waitUntil(15000) { compose.onAllNodesWithText(text).fetchSemanticsNodes().isNotEmpty() }
 @Test fun captureLocalizedPurchaseCentre() {
  check(BuildConfig.DEBUG)
  // Cold-boot system service startup can present an emulator-only ANR dialog.
  device.findObject(By.text("Wait"))?.click()
  device.waitForIdle()
  for (german in listOf(true,false)) {
   val language=if(german) "de-DE" else "en-US"
   instrumentation.runOnMainSync { context.getSystemService(LocaleManager::class.java).applicationLocales=LocaleList.forLanguageTags(language) }
   Locale.setDefault(Locale.forLanguageTag(language))
   context.getSharedPreferences("keepmeter",0).edit().putBoolean("onboarding_done",true).commit()
   val receipt=File(context.filesDir,"receipts/gallery-$language.jpg").apply { parentFile!!.mkdirs() }
   val bitmap=Bitmap.createBitmap(700,900,Bitmap.Config.ARGB_8888)
   val paint=Paint(Paint.ANTI_ALIAS_FLAG).apply { color=Color.rgb(30,40,55);textSize=34f }
   Canvas(bitmap).apply {
    drawColor(Color.rgb(255,253,246))
    drawText(if(german) "BEISPIELBELEG" else "EXAMPLE RECEIPT",55f,100f,paint)
    paint.textSize=26f
    drawText("AUDIO STUDIO",55f,175f,paint)
    drawText(if(german) "Studio-Kopfhörer" else "Studio Headphones",55f,300f,paint)
    drawText(if(german)"179,90 EUR" else "$179.90",55f,365f,paint)
    drawLine(55f,430f,645f,430f,paint)
    drawText(if(german) "Gesamt: 179,90 EUR" else "Total: $179.90",55f,495f,paint)
    drawText(if(german) "Vielen Dank!" else "Thank you!",55f,650f,paint)
   }
   receipt.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG,95,it) };bitmap.recycle()
   val db=KeepMeterDatabase.get(context)
   val now=System.currentTimeMillis();val day=86400000L
   runBlocking {
    db.clearAllTables()
    val names=if(german) listOf("Kopfhörer","Regenjacke","Reiserucksack") else listOf("Studio Headphones","Rain Jacket","Travel Backpack")
    names.forEachIndexed { i,name ->
     db.purchaseDao().insertPurchase(PurchaseEntity("gallery-$i",name,listOf("Audio Studio","Outdoor Store","Travel Store")[i],listOf(179.9,89.0,129.0)[i],now-5*day,now+listOf(3,6,12)[i]*day,now-i*day,"active",null,listOf("tech","clothing","leisure")[i],if(i==0)receipt.path else null))
     repeat(listOf(7,2,4)[i]) { j -> db.purchaseDao().insertUsage(UsageEventEntity("use-$i-$j","gallery-$i",now-(j+1)*day)) }
    }
   }
   val output=File(context.filesDir,"store-gallery/$language").apply { mkdirs() }
   fun capture(name:String) { compose.waitForIdle();device.waitForIdle();check(!device.hasObject(By.textContains("isn’t responding")) && !device.hasObject(By.textContains("isn't responding")));check(device.takeScreenshot(File(output,"$name.png"))) }
   val scenario=ActivityScenario.launch<MainActivity>(Intent(context,MainActivity::class.java))
   try {
    val headphones=if(german)"Kopfhörer" else "Studio Headphones"
    waitText(headphones);capture("01-purchase-centre")
    compose.onNode(isToggleable()).performClick();capture("02-return-filters")
    compose.onNodeWithText(headphones).performScrollTo().performClick()
    waitText(if(german)"Kategorie: Technik" else "Category: Technology")
    compose.onNodeWithContentDescription(if(german)"Belegfoto" else "Receipt photo").performScrollTo()
    capture("03-receipt-folder")
    pressBack()
    compose.onNodeWithText(if(german)"Auswertung" else "Insights").performClick();capture("04-usage-insights")
    compose.onNodeWithText(if(german)"Einstellungen" else "Settings").performClick()
    compose.onNodeWithText(if(german)"Käufe exportieren (CSV)" else "Export purchases (CSV)").performScrollTo();capture("05-csv-export")
   } finally { scenario.close() }
  }
 }
}
