package de.kamilunavo.keepmeter

import android.Manifest
import android.app.Activity
import android.content.Context
import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import de.kamilunavo.keepmeter.data.PurchaseWithUsage
import de.kamilunavo.keepmeter.domain.DecisionReason
import de.kamilunavo.keepmeter.domain.DecisionStatus
import java.text.NumberFormat
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

private val Blue = Color(0xFF316BF5)
private val BlueSoft = Color(0xFF64A1FF)
private val Success = Color(0xFF22A86E)
private val Warning = Color(0xFFF2931F)
private val Danger = Color(0xFFEB454F)
private val Page = Color(0xFFF4F6FB)
private val Surface = Color(0xFFFFFFFF)
private val Ink = Color(0xFF151923)
private val Secondary = Color(0xFF6C7483)
private val Hairline = Color(0xFFE4E8F0)

private val KmColors = lightColorScheme(primary = Blue, onPrimary = Color.White, secondary = BlueSoft, background = Page, onBackground = Ink, surface = Surface, onSurface = Ink, surfaceVariant = Color(0xFFF0F3F9), onSurfaceVariant = Secondary, outline = Hairline, error = Danger)
private val KmTypography = Typography(
    displaySmall = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Bold, fontSize = 34.sp, lineHeight = 40.sp, letterSpacing = (-.5).sp),
    headlineMedium = TextStyle(fontWeight = FontWeight.Bold, fontSize = 28.sp, lineHeight = 34.sp),
    titleLarge = TextStyle(fontWeight = FontWeight.Bold, fontSize = 21.sp, lineHeight = 26.sp),
    titleMedium = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 17.sp, lineHeight = 22.sp),
    bodyLarge = TextStyle(fontSize = 16.sp, lineHeight = 24.sp),
    bodyMedium = TextStyle(fontSize = 14.sp, lineHeight = 20.sp),
    bodySmall = TextStyle(fontSize = 13.sp, lineHeight = 18.sp),
)

private enum class MainTab { ACTIVE, INSIGHTS, ARCHIVE, SETTINGS }
private enum class Destination { TABS, ADD, DETAIL, PAYWALL }
private enum class KmIcon { GAUGE, BAG, TAP, CHECK, CHART, ARCHIVE, GEAR, PLUS, HOURGLASS, EURO, RETURN, LOCK, BELL, STAR, CALENDAR, STORE }

private class Copy(private val de: Boolean) {
    fun t(german: String, english: String) = if (de) german else english
    val active = t("Aktiv", "Active"); val insights = t("Auswertung", "Insights"); val archive = t("Archiv", "Archive"); val settings = t("Einstellungen", "Settings")
    val add = t("Kauf hinzufügen", "Add purchase"); val cancel = t("Abbrechen", "Cancel"); val save = t("Speichern", "Save")
    val uses = t("Nutzungen", "Uses"); val costUse = t("Kosten / Nutzung", "Cost / use"); val daysLeft = t("Tage übrig", "Days left")
    val kept = t("Behalten", "Kept"); val returned = t("Zurückgegeben", "Returned")
}

@Composable
internal fun KeepMeterRoot(activity: Activity, vm: KeepMeterViewModel, billing: BillingManager) {
    val prefs = remember { activity.getSharedPreferences("keepmeter", Context.MODE_PRIVATE) }
    var onboardingDone by rememberSaveable { mutableStateOf(prefs.getBoolean("onboarding_done", false)) }
    val configuration = LocalConfiguration.current
    val copy = remember(configuration.locales) { Copy(configuration.locales[0]?.language == "de") }
    MaterialTheme(colorScheme = KmColors, typography = KmTypography) {
        Box(Modifier.fillMaxSize().background(Brush.linearGradient(listOf(Page, Blue.copy(alpha = .045f), Page), Offset.Zero, Offset(1100f, 1900f)))) {
            if (!onboardingDone) Onboarding(copy) { prefs.edit().putBoolean("onboarding_done", true).apply(); onboardingDone = true }
            else MainExperience(activity, vm, billing, copy) { prefs.edit().putBoolean("onboarding_done", false).apply(); onboardingDone = false }
        }
    }
}

@Composable
private fun Onboarding(copy: Copy, onDone: () -> Unit) {
    var page by rememberSaveable { mutableIntStateOf(0) }
    val pages = listOf(
        Triple(KmIcon.BAG, copy.t("Bewusster behalten", "Buy less blindly"), copy.t("Füge einen Kauf hinzu und behalte die Rückgabefrist sichtbar, statt ihn in einer Schublade zu vergessen.", "Add a purchase and keep its return deadline visible instead of forgetting it in a drawer.")),
        Triple(KmIcon.TAP, copy.t("Echte Nutzung tracken", "Track real use"), copy.t("Tippe einmal, wenn du einen Artikel nutzt. KeepMeter berechnet daraus Nutzungen und Kosten pro Nutzung.", "Tap once whenever you use an item. KeepMeter turns that into usage count and cost per use.")),
        Triple(KmIcon.CHECK, copy.t("Rechtzeitig entscheiden", "Decide in time"), copy.t("Erhalte vor Ablauf der Rückgabefrist ein nachvollziehbares Signal: BEHALTEN, PRÜFEN oder ZURÜCK.", "Get an explainable KEEP, REVIEW or RETURN signal before the return window closes.")),
    )
    Column(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing).padding(24.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            BrandMark(); Text("KeepMeter", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(start = 9.dp)); Spacer(Modifier.weight(1f))
            if (page < 2) TextButton(onClick = onDone) { Text(copy.t("Überspringen", "Skip"), color = Secondary, fontWeight = FontWeight.SemiBold) }
        }
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            KmCard(Modifier.fillMaxWidth().heightIn(min = 250.dp), 38.dp) {
                Box(Modifier.fillMaxWidth().height(250.dp), contentAlignment = Alignment.Center) {
                    Box(Modifier.size(158.dp).background(iconTint(page).copy(alpha = .11f), CircleShape).border(1.dp, iconTint(page).copy(alpha = .15f), CircleShape), contentAlignment = Alignment.Center) { KmSymbol(pages[page].first, Modifier.size(66.dp), iconTint(page)) }
                }
            }
            Spacer(Modifier.height(26.dp)); Text(pages[page].second, style = MaterialTheme.typography.displaySmall, textAlign = TextAlign.Center)
            Text(pages[page].third, style = MaterialTheme.typography.bodyLarge, color = Secondary, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 12.dp).widthIn(max = 360.dp))
        }
        Row(Modifier.align(Alignment.CenterHorizontally).padding(bottom = 22.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) { repeat(3) { i -> Box(Modifier.width(if (i == page) 30.dp else 8.dp).height(8.dp).background(if (i == page) Blue else Secondary.copy(alpha = .2f), CircleShape)) } }
        GradientButton(if (page == 2) copy.t("Tracking starten", "Start tracking") else copy.t("Weiter", "Continue")) { if (page < 2) page++ else onDone() }
    }
}

private fun iconTint(page: Int) = when (page) { 1 -> BlueSoft; 2 -> Success; else -> Blue }

@Composable
private fun MainExperience(activity: Activity, vm: KeepMeterViewModel, billing: BillingManager, copy: Copy, showOnboarding: () -> Unit) {
    var tabName by rememberSaveable { mutableStateOf(MainTab.ACTIVE.name) }
    var destinationName by rememberSaveable { mutableStateOf(Destination.TABS.name) }
    var selectedId by rememberSaveable { mutableStateOf<String?>(null) }
    val destination = Destination.valueOf(destinationName); val tab = MainTab.valueOf(tabName)
    val all by vm.allPurchases.collectAsStateWithLifecycle()
    fun go(value: Destination) { destinationName = value.name }
    BackHandler(destination != Destination.TABS) { go(Destination.TABS) }
    when (destination) {
        Destination.TABS -> MainShell(tab, copy, onTab = { tabName = it.name }, onAdd = { if (!billing.isPro && all.count { it.purchase.outcome == "active" } >= 5) go(Destination.PAYWALL) else go(Destination.ADD) }) {
            when (tab) {
                MainTab.ACTIVE -> ActiveScreen(all.filter { it.purchase.outcome == "active" }, vm, copy, billing.isPro, onOpen = { selectedId = it; go(Destination.DETAIL) }, onPaywall = { go(Destination.PAYWALL) })
                MainTab.INSIGHTS -> InsightsScreen(all, copy)
                MainTab.ARCHIVE -> ArchiveScreen(all.filter { it.purchase.outcome != "active" }, copy) { selectedId = it; go(Destination.DETAIL) }
                MainTab.SETTINGS -> SettingsScreen(activity, billing, copy, { go(Destination.PAYWALL) }, showOnboarding)
            }
        }
        Destination.ADD -> AddPurchaseScreen(vm, billing.isPro, copy, { go(Destination.TABS) }) { go(Destination.PAYWALL) }
        Destination.DETAIL -> all.firstOrNull { it.purchase.id == selectedId }?.let { DetailScreen(it, vm, copy) { go(Destination.TABS) } } ?: LaunchedEffect(Unit) { go(Destination.TABS) }
        Destination.PAYWALL -> PaywallScreen(activity, billing, copy) { go(Destination.TABS) }
    }
}

@Composable
private fun MainShell(tab: MainTab, copy: Copy, onTab: (MainTab) -> Unit, onAdd: () -> Unit, content: @Composable () -> Unit) {
    Scaffold(containerColor = Color.Transparent, contentWindowInsets = WindowInsets.safeDrawing, topBar = {
        Row(Modifier.fillMaxWidth().height(60.dp).padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(when(tab) { MainTab.ACTIVE -> "KeepMeter"; MainTab.INSIGHTS -> copy.insights; MainTab.ARCHIVE -> copy.archive; MainTab.SETTINGS -> copy.settings }, style = MaterialTheme.typography.headlineMedium, modifier = Modifier.weight(1f))
            if (tab == MainTab.ACTIVE) CircleAction(KmIcon.PLUS, copy.add, onAdd)
        }
    }, bottomBar = { BottomBar(tab, copy, onTab) }) { padding -> Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) { Box(Modifier.fillMaxWidth().widthIn(max = 720.dp)) { content() } } }
}

@Composable
private fun BottomBar(tab: MainTab, copy: Copy, onTab: (MainTab) -> Unit) {
    NavigationBar(containerColor = Surface, tonalElevation = 3.dp) {
        listOf(MainTab.ACTIVE to copy.active, MainTab.INSIGHTS to copy.insights, MainTab.ARCHIVE to copy.archive, MainTab.SETTINGS to copy.settings).forEach { (item, label) ->
            NavigationBarItem(selected = tab == item, onClick = { onTab(item) }, icon = { KmSymbol(when(item) { MainTab.ACTIVE -> KmIcon.GAUGE; MainTab.INSIGHTS -> KmIcon.CHART; MainTab.ARCHIVE -> KmIcon.ARCHIVE; MainTab.SETTINGS -> KmIcon.GEAR }, Modifier.size(23.dp), if (tab == item) Blue else Secondary) }, label = { Text(label, maxLines = 1, fontSize = 11.sp) }, colors = NavigationBarItemDefaults.colors(indicatorColor = Blue.copy(alpha = .1f), selectedIconColor = Blue, selectedTextColor = Blue, unselectedTextColor = Secondary))
        }
    }
}

@Composable
private fun ActiveScreen(items: List<PurchaseWithUsage>, vm: KeepMeterViewModel, copy: Copy, isPro: Boolean, onOpen: (String) -> Unit, onPaywall: () -> Unit) {
    if (items.isEmpty()) {
        EmptyState(KmIcon.BAG, copy.t("Keine aktiven Käufe", "No active purchases"), copy.t("Füge einen kürzlich getätigten Kauf hinzu. KeepMeter hilft dir, rechtzeitig vor Ablauf der Rückgabefrist zu entscheiden.", "Add a recent purchase and KeepMeter will help you decide before the return window closes."))
        return
    }
    val urgent = items.count { vm.decision(it).daysRemaining <= 3 }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 8.dp).padding(bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        KmCard(Modifier.fillMaxWidth()) {
            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                IconTile(if (urgent > 0) KmIcon.HOURGLASS else KmIcon.CHECK, if (urgent > 0) Warning else Blue, 58.dp)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(copy.t("Entscheidungsübersicht", "Decision dashboard"), style = MaterialTheme.typography.titleMedium)
                    Text(if (urgent > 0) copy.t("$urgent Kauf/Käufe brauchen innerhalb der nächsten drei Tage deine Aufmerksamkeit.", "$urgent purchase(s) need attention within three days.") else copy.t("Alles im Blick. Tracke weiter die echte Nutzung.", "Everything is under control. Keep logging real usage."), color = Secondary, style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
        if (!isPro && items.size >= 5) KmCard(Modifier.fillMaxWidth().clickable(role = Role.Button, onClick = onPaywall), 20.dp) {
            Row(Modifier.padding(15.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(13.dp)) { IconTile(KmIcon.STAR, Blue, 42.dp); Column(Modifier.weight(1f)) { Text(copy.t("Kostenloses Limit erreicht", "Free limit reached"), fontWeight = FontWeight.Bold); Text(copy.t("Lifetime Pro schaltet unbegrenzt viele aktive Käufe frei.", "Lifetime Pro unlocks unlimited active purchases."), color = Secondary, style = MaterialTheme.typography.bodyMedium) }; Text("›", color = Secondary, fontSize = 24.sp) }
        }
        items.forEach { PurchaseCard(it, vm, copy, onOpen) }
    }
}

@Composable
private fun PurchaseCard(item: PurchaseWithUsage, vm: KeepMeterViewModel, copy: Copy, onOpen: (String) -> Unit) {
    val decision = vm.decision(item); val tint = decisionColor(decision.status); val progress = returnProgress(item)
    KmCard(Modifier.fillMaxWidth(), 22.dp) {
        Column {
            Column(Modifier.fillMaxWidth().clickable(role = Role.Button) { onOpen(item.purchase.id) }.padding(16.dp), verticalArrangement = Arrangement.spacedBy(15.dp)) {
                Row(verticalAlignment = Alignment.Top) {
                    Column(Modifier.weight(1f)) { Text(item.purchase.name, style = MaterialTheme.typography.titleMedium, maxLines = 2, overflow = TextOverflow.Ellipsis); if (item.purchase.merchant.isNotBlank()) Text(item.purchase.merchant, color = Secondary, style = MaterialTheme.typography.bodyMedium) }
                    StatusBadge(decisionLabel(decision.status, copy), tint)
                }
                Row(Modifier.fillMaxWidth()) {
                    CompactMetric(copy.uses, decision.useCount.toString(), Modifier.weight(1f)); CompactMetric(copy.costUse, decision.costPerUse?.let(::money) ?: "—", Modifier.weight(1f)); CompactMetric(copy.daysLeft, decision.daysRemaining.toString(), Modifier.weight(1f))
                }
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row { Text(copy.t("Rückgabefrist", "Return window"), style = MaterialTheme.typography.bodySmall, color = Secondary); Spacer(Modifier.weight(1f)); Text(date(item.purchase.returnDeadlineEpochMillis), style = MaterialTheme.typography.bodySmall, color = Secondary) }
                    Box(Modifier.fillMaxWidth().height(6.dp).background(Ink.copy(alpha = .07f), CircleShape)) { Box(Modifier.fillMaxWidth(progress.toFloat().coerceIn(.03f, 1f)).height(6.dp).background(tint.copy(alpha = .78f), CircleShape)) }
                }
            }
            HorizontalDivider(color = Hairline)
            TextButton(onClick = { vm.recordUsage(item.purchase.id) }, modifier = Modifier.fillMaxWidth().height(54.dp)) { KmSymbol(KmIcon.TAP, Modifier.size(20.dp), Blue); Text(copy.t("Benutzt", "Used it"), modifier = Modifier.padding(start = 8.dp), fontWeight = FontWeight.Bold) }
        }
    }
}

@Composable
private fun DetailScreen(item: PurchaseWithUsage, vm: KeepMeterViewModel, copy: Copy, onBack: () -> Unit) {
    val decision = vm.decision(item); val tint = decisionColor(decision.status); val active = item.purchase.outcome == "active"
    FullScreen(title = item.purchase.name, onBack = onBack) {
        KmCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) { IconTile(when(decision.status) { DecisionStatus.KEEP -> KmIcon.CHECK; DecisionStatus.REVIEW -> KmIcon.HOURGLASS; DecisionStatus.RETURN_CANDIDATE -> KmIcon.RETURN }, tint, 54.dp); Column(Modifier.padding(start = 14.dp).weight(1f)) { Text(copy.t("Entscheidung", "Decision"), color = Secondary, style = MaterialTheme.typography.bodySmall); Text(decisionLabel(decision.status, copy), style = MaterialTheme.typography.titleLarge, color = tint) } }
                Text(reasonLabel(decision.reason, copy), color = Secondary, style = MaterialTheme.typography.bodyMedium)
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) { MetricCard(copy.uses, decision.useCount.toString(), KmIcon.TAP, Blue, Modifier.weight(1f)); MetricCard(copy.costUse, decision.costPerUse?.let(::money) ?: "—", KmIcon.EURO, BlueSoft, Modifier.weight(1f)); MetricCard(copy.daysLeft, decision.daysRemaining.toString(), KmIcon.HOURGLASS, Warning, Modifier.weight(1f)) }
        if (active) GradientButton(copy.t("Nutzung eintragen", "Log a use"), KmIcon.PLUS) { vm.recordUsage(item.purchase.id) }
        SectionTitle(copy.t("Kaufdetails", "Purchase details"))
        KmCard(Modifier.fillMaxWidth(), 20.dp) {
            Column(Modifier.padding(horizontal = 16.dp)) {
                InfoRow(KmIcon.CALENDAR, copy.t("Gekauft", "Purchased"), date(item.purchase.purchaseDateEpochMillis)); HorizontalDivider(color = Hairline)
                InfoRow(KmIcon.CALENDAR, copy.t("Rückgabe bis", "Return by"), date(item.purchase.returnDeadlineEpochMillis))
                if (item.purchase.merchant.isNotBlank()) { HorizontalDivider(color = Hairline); InfoRow(KmIcon.STORE, copy.t("Händler", "Merchant"), item.purchase.merchant) }
                HorizontalDivider(color = Hairline); InfoRow(KmIcon.EURO, copy.t("Preis", "Price"), money(item.purchase.price))
            }
        }
        if (active) {
            SectionTitle(copy.t("Deine endgültige Entscheidung", "Your final decision"))
            Text(copy.t("KeepMeter liefert dir ein Signal. Die Entscheidung bleibt bei dir.", "KeepMeter gives you a signal. You stay in control."), color = Secondary)
            Button(onClick = { vm.markKept(item.purchase.id); onBack() }, modifier = Modifier.fillMaxWidth().height(54.dp), shape = RoundedCornerShape(17.dp), colors = ButtonDefaults.buttonColors(containerColor = Success)) { Text(copy.t("Kauf behalten", "Keep purchase"), fontWeight = FontWeight.Bold) }
            OutlinedButton(onClick = { vm.markReturned(item.purchase.id); onBack() }, modifier = Modifier.fillMaxWidth().height(54.dp), shape = RoundedCornerShape(17.dp), colors = ButtonDefaults.outlinedButtonColors(contentColor = Danger)) { Text(copy.t("Als zurückgegeben markieren", "Mark as returned"), fontWeight = FontWeight.Bold) }
        } else TextButton(onClick = { vm.deletePurchase(item.purchase.id); onBack() }, modifier = Modifier.align(Alignment.CenterHorizontally)) { Text(copy.t("Aus Archiv löschen", "Delete from archive"), color = Danger) }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddPurchaseScreen(vm: KeepMeterViewModel, isPro: Boolean, copy: Copy, onClose: () -> Unit, onLimit: () -> Unit) {
    var name by rememberSaveable { mutableStateOf("") }; var merchant by rememberSaveable { mutableStateOf("") }; var price by rememberSaveable { mutableStateOf("") }
    var purchased by rememberSaveable { mutableLongStateOf(System.currentTimeMillis()) }; var deadline by rememberSaveable { mutableLongStateOf(System.currentTimeMillis() + 14L * 86_400_000L) }
    var pickingPurchase by rememberSaveable { mutableStateOf<Boolean?>(null) }
    FullScreen(copy.t("Neuer Kauf", "New purchase"), onClose) {
        SectionTitle(copy.t("Kauf", "Purchase"))
        KmCard(Modifier.fillMaxWidth(), 20.dp) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                StyledField(name, { name = it }, copy.t("Artikelname", "Item name"), KeyboardType.Text)
                StyledField(merchant, { merchant = it }, copy.t("Händler (optional)", "Merchant (optional)"), KeyboardType.Text)
                StyledField(price, { next -> if (next.all { it.isDigit() || it == ',' || it == '.' }) price = next }, copy.t("Preis", "Price"), KeyboardType.Decimal, currencySymbol())
            }
        }
        SectionTitle(copy.t("Daten", "Dates"))
        KmCard(Modifier.fillMaxWidth(), 20.dp) {
            Column(Modifier.padding(horizontal = 16.dp)) {
                DateRow(copy.t("Gekauft", "Purchased"), purchased) { pickingPurchase = true }; HorizontalDivider(color = Hairline)
                DateRow(copy.t("Rückgabe bis", "Return by"), deadline) { pickingPurchase = false }
            }
        }
        FormulaBox(copy.t("KeepMeter verwendet das von dir bestätigte Rückgabedatum. Händlerbedingungen und gesetzliche Rechte können davon abweichen.", "KeepMeter treats the return date as information you confirm. Merchant policies and legal rights can differ."))
        GradientButton(copy.save, enabled = name.isNotBlank() && (price.replace(',', '.').toDoubleOrNull() ?: -1.0) >= 0 && deadline >= purchased) {
            vm.addPurchase(name, merchant, price.replace(',', '.').toDoubleOrNull() ?: 0.0, purchased, deadline, isPro) { added -> if (added) onClose() else onLimit() }
        }
    }
    pickingPurchase?.let { purchaseMode ->
        val state = rememberDatePickerState(initialSelectedDateMillis = if (purchaseMode) purchased else deadline)
        DatePickerDialog(onDismissRequest = { pickingPurchase = null }, confirmButton = { TextButton(onClick = { state.selectedDateMillis?.let { if (purchaseMode) purchased = it else deadline = it }; pickingPurchase = null }) { Text(copy.t("Fertig", "Done")) } }, dismissButton = { TextButton(onClick = { pickingPurchase = null }) { Text(copy.cancel) } }) { DatePicker(state = state) }
    }
}

@Composable
private fun InsightsScreen(items: List<PurchaseWithUsage>, copy: Copy) {
    if (items.isEmpty()) { EmptyState(KmIcon.CHART, copy.t("Noch keine Auswertung", "No insights yet"), copy.t("Tracke deinen ersten Kauf und einige Nutzungen, damit eine sinnvolle Auswertung entsteht.", "Track your first purchase and log a few uses to build meaningful insights.")); return }
    val active = items.count { it.purchase.outcome == "active" }; val kept = items.count { it.purchase.outcome == "kept" }; val returned = items.count { it.purchase.outcome == "returned" }
    val uses = items.sumOf { it.usageEvents.size }; val costs = items.mapNotNull { if (it.usageEvents.isEmpty()) null else it.purchase.price / it.usageEvents.size }; val average = costs.takeIf { it.isNotEmpty() }?.average()
    val best = items.filter { it.usageEvents.isNotEmpty() }.minByOrNull { it.purchase.price / it.usageEvents.size }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 8.dp).padding(bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(22.dp)) {
        KmCard(Modifier.fillMaxWidth()) { Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) { IconTile(KmIcon.CHART, Blue, 62.dp); Column(Modifier.padding(start = 16.dp)) { Text(copy.t("Getrackter Wert", "Tracked value"), color = Secondary); Text(money(items.sumOf { it.purchase.price }), style = MaterialTheme.typography.headlineMedium) } } }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) { MetricCard(copy.t("Nutzungen gesamt", "Total uses"), uses.toString(), KmIcon.TAP, Blue, Modifier.weight(1f)); MetricCard(copy.t("Ø Kosten / Nutzung", "Avg. cost / use"), average?.let(::money) ?: "—", KmIcon.EURO, BlueSoft, Modifier.weight(1f)) }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) { MetricCard(copy.t("Offene Entscheidungen", "Active decisions"), active.toString(), KmIcon.HOURGLASS, Warning, Modifier.weight(1f)); MetricCard(copy.kept, kept.toString(), KmIcon.CHECK, Success, Modifier.weight(1f)) }
        SectionTitle(copy.t("Deine Entscheidungen", "Your decisions"))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) { CountCard(copy.kept, kept, Success, Modifier.weight(1f)); CountCard(copy.returned, returned, Danger, Modifier.weight(1f)) }
        best?.let { val cpu = it.purchase.price / it.usageEvents.size; SectionTitle(copy.t("Bester Wert bisher", "Best value so far")); KmCard(Modifier.fillMaxWidth(), 20.dp) { Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) { IconTile(KmIcon.STAR, Warning, 52.dp); Column(Modifier.padding(start = 14.dp).weight(1f)) { Text(it.purchase.name, fontWeight = FontWeight.Bold); Text("${it.usageEvents.size} ${copy.uses.lowercase()} · ${money(cpu)} / ${copy.t("Nutzung", "use")}", color = Secondary, style = MaterialTheme.typography.bodyMedium) } } } }
    }
}

@Composable
private fun ArchiveScreen(items: List<PurchaseWithUsage>, copy: Copy, onOpen: (String) -> Unit) {
    if (items.isEmpty()) { EmptyState(KmIcon.ARCHIVE, copy.t("Archiv ist leer", "Archive is empty"), copy.t("Käufe, die du behältst oder zurückgibst, erscheinen hier.", "Purchases you keep or return will appear here.")); return }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 8.dp).padding(bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) { CountCard(copy.kept, items.count { it.purchase.outcome == "kept" }, Success, Modifier.weight(1f)); CountCard(copy.returned, items.count { it.purchase.outcome == "returned" }, Danger, Modifier.weight(1f)) }
        items.forEach { item -> val kept = item.purchase.outcome == "kept"; KmCard(Modifier.fillMaxWidth().clickable(role = Role.Button) { onOpen(item.purchase.id) }, 20.dp) { Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) { IconTile(if (kept) KmIcon.CHECK else KmIcon.RETURN, if (kept) Success else Danger, 48.dp); Column(Modifier.padding(start = 14.dp).weight(1f)) { Row(verticalAlignment = Alignment.CenterVertically) { Text(item.purchase.name, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f)); StatusBadge(if (kept) copy.kept else copy.returned, if (kept) Success else Danger) }; Text("${item.usageEvents.size} ${copy.uses.lowercase()}${if (item.usageEvents.isNotEmpty()) " · ${money(item.purchase.price / item.usageEvents.size)} / ${copy.t("Nutzung", "use")}" else ""}", color = Secondary, style = MaterialTheme.typography.bodyMedium) }; Text("›", color = Secondary, fontSize = 24.sp) } } }
    }
}

@Composable
private fun SettingsScreen(activity: Activity, billing: BillingManager, copy: Copy, onPaywall: () -> Unit, showOnboarding: () -> Unit) {
    val notificationLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 8.dp).padding(bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Brush.linearGradient(if (billing.isPro) listOf(Success, Color(0xFF55C68D)) else listOf(Blue, BlueSoft))).clickable(enabled = !billing.isPro, role = Role.Button, onClick = onPaywall).padding(17.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) { IconTile(if (billing.isPro) KmIcon.CHECK else KmIcon.STAR, Color.White, 58.dp, whiteTile = true); Column(Modifier.padding(start = 15.dp).weight(1f)) { Text(if (billing.isPro) copy.t("Lifetime Pro freigeschaltet", "Lifetime Pro unlocked") else "KeepMeter Pro", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp); Text(if (billing.isPro) copy.t("Unbegrenzt viele aktive Käufe sind freigeschaltet.", "Unlimited active purchases are enabled.") else copy.t("Einmal kaufen. Kein Abo.", "One purchase. No subscription."), color = Color.White.copy(alpha = .84f)) }; if (!billing.isPro) Text("›", color = Color.White, fontSize = 24.sp) }
        }
        SettingsGroup(copy.t("Erinnerungen", "Reminders")) {
            SettingsLine(KmIcon.BELL, copy.t("Mitteilungen", "Notification permission"), copy.t("KeepMeter plant Erinnerungen vor der Rückgabefrist.", "KeepMeter schedules reminders before the return deadline."), Blue)
            if (Build.VERSION.SDK_INT >= 33) TextButton(onClick = { notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS) }) { Text(copy.t("Erinnerungen aktivieren", "Enable reminders"), fontWeight = FontWeight.Bold) }
        }
        SettingsGroup(copy.t("Datenschutz", "Privacy")) { SettingsLine(KmIcon.LOCK, copy.t("Lokal gespeichert", "Local-first"), copy.t("Deine Kauf- und Nutzungsdaten bleiben auf diesem Gerät. Kein Konto erforderlich.", "Your purchase and usage data stays on this device. No account required."), Success) }
        SettingsGroup(copy.t("Hilfe", "Help")) { TextButton(onClick = showOnboarding) { Text(copy.t("Einführung erneut anzeigen", "Show introduction again"), fontWeight = FontWeight.Bold) }; TextButton(onClick = billing::restorePurchases) { Text(copy.t("Käufe wiederherstellen", "Restore purchases"), fontWeight = FontWeight.Bold) } }
        SettingsGroup(copy.t("Über KeepMeter", "About KeepMeter")) { InfoRow(KmIcon.GAUGE, copy.t("Version", "Version"), "1.0.2"); HorizontalDivider(color = Hairline); InfoRow(KmIcon.STORE, copy.t("Entwickler", "Developer"), "Kamilunavo") }
        billing.statusMessage?.let { FormulaBox(it, true) }
    }
}

@Composable
private fun PaywallScreen(activity: Activity, billing: BillingManager, copy: Copy, onClose: () -> Unit) {
    if (billing.isPro) { LaunchedEffect(Unit) { onClose() }; return }
    FullScreen(copy.t("Pro", "Pro"), onClose) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Box(Modifier.size(142.dp).background(Blue.copy(alpha = .1f), CircleShape).border(1.dp, Blue.copy(alpha = .16f), CircleShape), contentAlignment = Alignment.Center) { KmSymbol(KmIcon.GAUGE, Modifier.size(58.dp), Blue) }
            Text("KeepMeter Pro", style = MaterialTheme.typography.displaySmall, textAlign = TextAlign.Center)
            Text(copy.t("Tracke mehr als fünf aktive Käufe mit einem einmaligen Lifetime-Pro-Kauf.", "Track more than five active purchases with a one-time Lifetime Pro unlock."), color = Secondary, textAlign = TextAlign.Center, modifier = Modifier.widthIn(max = 360.dp))
            StatusBadge(copy.t("Einmal kaufen. Kein Abo.", "One purchase. No subscription."), Success)
        }
        KmCard(Modifier.fillMaxWidth()) { Column(Modifier.padding(horizontal = 16.dp)) { Benefit(KmIcon.GAUGE, copy.t("Unbegrenzt aktive Käufe", "Unlimited active purchases"), Blue); HorizontalDivider(color = Hairline); Benefit(KmIcon.CHECK, copy.t("Kein Abonnement", "No subscription"), Success); HorizontalDivider(color = Hairline); Benefit(KmIcon.LOCK, copy.t("Lokal gespeichert", "Local-first"), Blue) } }
        GradientButton(if (billing.productPrice != null) "${copy.t("Lifetime Pro freischalten", "Unlock Lifetime Pro")} · ${billing.productPrice}" else copy.t("Lifetime Pro laden", "Load Lifetime Pro")) { billing.launchPurchase(activity) }
        TextButton(onClick = billing::restorePurchases, modifier = Modifier.align(Alignment.CenterHorizontally)) { Text(copy.t("Käufe wiederherstellen", "Restore purchases"), fontWeight = FontWeight.Bold) }
        billing.statusMessage?.let { FormulaBox(it, true) }
    }
}

@Composable
private fun FullScreen(title: String, onBack: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Scaffold(containerColor = Color.Transparent, contentWindowInsets = WindowInsets.safeDrawing, topBar = {
        Row(Modifier.fillMaxWidth().height(58.dp).padding(horizontal = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack, modifier = Modifier.width(64.dp)) { Text("‹", fontSize = 32.sp, fontWeight = FontWeight.Light) }
            Text(title, Modifier.weight(1f), style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Spacer(Modifier.width(64.dp))
        }
    }) { padding -> Column(Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).imePadding(), horizontalAlignment = Alignment.CenterHorizontally) { Column(Modifier.fillMaxWidth().widthIn(max = 680.dp).padding(horizontal = 18.dp, vertical = 12.dp).padding(bottom = 30.dp), verticalArrangement = Arrangement.spacedBy(20.dp), content = content) } }
}

@Composable
private fun KmCard(modifier: Modifier = Modifier, radius: Dp = 24.dp, content: @Composable BoxScope.() -> Unit) {
    Box(modifier.background(Surface, RoundedCornerShape(radius)).border(1.dp, Hairline, RoundedCornerShape(radius)).padding(0.dp), content = content)
}

@Composable
private fun BrandMark() { Box(Modifier.size(32.dp).background(Blue, RoundedCornerShape(10.dp)), contentAlignment = Alignment.Center) { KmSymbol(KmIcon.GAUGE, Modifier.size(19.dp), Color.White) } }

@Composable
private fun GradientButton(label: String, icon: KmIcon? = null, enabled: Boolean = true, onClick: () -> Unit) {
    Box(Modifier.fillMaxWidth().heightIn(min = 56.dp).clip(RoundedCornerShape(18.dp)).background(if (enabled) Brush.horizontalGradient(listOf(Blue, BlueSoft)) else Brush.horizontalGradient(listOf(Secondary.copy(alpha=.35f), Secondary.copy(alpha=.25f)))).clickable(enabled = enabled, role = Role.Button, onClick = onClick).padding(horizontal = 18.dp, vertical = 16.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) { if (icon != null) { KmSymbol(icon, Modifier.size(22.dp), Color.White); Spacer(Modifier.width(10.dp)) }; Text(label, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 16.sp, modifier = Modifier.weight(1f)); Text("›", color = Color.White, fontSize = 22.sp) }
    }
}

@Composable
private fun CircleAction(icon: KmIcon, label: String, onClick: () -> Unit) { Box(Modifier.size(42.dp).background(Blue.copy(alpha=.1f), CircleShape).clickable(role = Role.Button, onClick = onClick), contentAlignment = Alignment.Center) { KmSymbol(icon, Modifier.size(21.dp), Blue) } }

@Composable
private fun IconTile(icon: KmIcon, tint: Color, tileSize: Dp, whiteTile: Boolean = false) { Box(Modifier.size(tileSize).background(if (whiteTile) Color.White.copy(alpha=.16f) else tint.copy(alpha=.11f), RoundedCornerShape(tileSize * .3f)), contentAlignment = Alignment.Center) { KmSymbol(icon, Modifier.size(tileSize * .48f), tint) } }

@Composable
private fun StatusBadge(label: String, tint: Color) { Surface(color = tint.copy(alpha=.1f), shape = CircleShape) { Text(label, color = tint, fontSize = 11.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 9.dp, vertical = 5.dp)) } }

@Composable
private fun CompactMetric(label: String, value: String, modifier: Modifier = Modifier) { Column(modifier, verticalArrangement = Arrangement.spacedBy(2.dp)) { Text(value, fontWeight = FontWeight.Bold, fontSize = 17.sp, maxLines = 1, overflow = TextOverflow.Ellipsis); Text(label, color = Secondary, fontSize = 11.sp, maxLines = 2) } }

@Composable
private fun MetricCard(label: String, value: String, icon: KmIcon, tint: Color, modifier: Modifier = Modifier) { KmCard(modifier.heightIn(min=126.dp), 20.dp) { Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) { IconTile(icon, tint, 36.dp); Text(value, style = MaterialTheme.typography.titleLarge, maxLines = 1, overflow = TextOverflow.Ellipsis); Text(label, color = Secondary, style = MaterialTheme.typography.bodySmall) } } }

@Composable
private fun CountCard(label: String, count: Int, tint: Color, modifier: Modifier = Modifier) { KmCard(modifier, 18.dp) { Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) { IconTile(if(tint == Success) KmIcon.CHECK else KmIcon.RETURN, tint, 38.dp); Column(Modifier.padding(start=11.dp)) { Text(count.toString(), style=MaterialTheme.typography.titleLarge); Text(label, color=Secondary, style=MaterialTheme.typography.bodySmall) } } } }

@Composable
private fun EmptyState(icon: KmIcon, title: String, body: String) { Column(Modifier.fillMaxSize().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) { Box(Modifier.size(128.dp).background(Blue.copy(alpha=.1f), CircleShape).border(1.dp, Blue.copy(alpha=.16f), CircleShape), contentAlignment = Alignment.Center) { KmSymbol(icon, Modifier.size(52.dp), Blue) }; Text(title, style=MaterialTheme.typography.titleLarge, textAlign=TextAlign.Center, modifier=Modifier.padding(top=24.dp)); Text(body, color=Secondary, textAlign=TextAlign.Center, style=MaterialTheme.typography.bodyLarge, modifier=Modifier.padding(top=10.dp).widthIn(max=340.dp)); Spacer(Modifier.height(90.dp)) } }

@Composable
private fun SectionTitle(text: String) { Text(text, style = MaterialTheme.typography.titleMedium, modifier = Modifier.fillMaxWidth()) }

@Composable
private fun InfoRow(icon: KmIcon, title: String, value: String) { Row(Modifier.fillMaxWidth().padding(vertical=14.dp), verticalAlignment=Alignment.CenterVertically) { KmSymbol(icon, Modifier.size(22.dp), Blue); Text(title, color=Secondary, modifier=Modifier.padding(start=12.dp).weight(1f)); Text(value, fontWeight=FontWeight.SemiBold, textAlign=TextAlign.End) } }

@Composable
private fun FormulaBox(text: String, error: Boolean = false) { Row(Modifier.fillMaxWidth().background((if(error) Danger else Blue).copy(alpha=.07f), RoundedCornerShape(15.dp)).padding(14.dp), verticalAlignment=Alignment.Top) { Text(if(error) "!" else "i", color=if(error) Danger else Blue, fontWeight=FontWeight.Black); Text(text, color=if(error) Danger else Secondary, style=MaterialTheme.typography.bodySmall, modifier=Modifier.padding(start=9.dp).weight(1f)) } }

@Composable
private fun StyledField(value: String, onValue: (String)->Unit, label: String, keyboardType: KeyboardType, suffix: String? = null) { val focus=LocalFocusManager.current; OutlinedTextField(value=value,onValueChange=onValue,label={Text(label)},suffix={suffix?.let{Text(it)}},singleLine=true,modifier=Modifier.fillMaxWidth(),shape=RoundedCornerShape(14.dp),keyboardOptions=KeyboardOptions(keyboardType=keyboardType,imeAction=ImeAction.Done),keyboardActions=KeyboardActions(onDone={focus.clearFocus()}),colors=OutlinedTextFieldDefaults.colors(focusedBorderColor=Blue,unfocusedBorderColor=Hairline,focusedContainerColor=Color(0xFFF8F9FC),unfocusedContainerColor=Color(0xFFF8F9FC))) }

@Composable
private fun DateRow(label: String, epoch: Long, onClick: () -> Unit) { Row(Modifier.fillMaxWidth().clickable(role=Role.Button,onClick=onClick).padding(vertical=16.dp),verticalAlignment=Alignment.CenterVertically) { KmSymbol(KmIcon.CALENDAR,Modifier.size(22.dp),Blue); Text(label,modifier=Modifier.padding(start=12.dp).weight(1f)); Text(date(epoch),color=Blue,fontWeight=FontWeight.SemiBold) } }

@Composable
private fun SettingsGroup(title: String, content: @Composable ColumnScope.()->Unit) { Column(verticalArrangement=Arrangement.spacedBy(8.dp)) { Text(title.uppercase(), color=Secondary, fontSize=12.sp,fontWeight=FontWeight.Bold,modifier=Modifier.padding(start=4.dp)); KmCard(Modifier.fillMaxWidth(),20.dp) { Column(Modifier.padding(horizontal=16.dp),content=content) } } }

@Composable
private fun SettingsLine(icon: KmIcon,title:String,subtitle:String,tint:Color) { Row(Modifier.fillMaxWidth().padding(vertical=15.dp),verticalAlignment=Alignment.Top) { IconTile(icon,tint,38.dp); Column(Modifier.padding(start=12.dp).weight(1f)) { Text(title,fontWeight=FontWeight.SemiBold); Text(subtitle,color=Secondary,style=MaterialTheme.typography.bodySmall,modifier=Modifier.padding(top=3.dp)) } } }

@Composable
private fun Benefit(icon: KmIcon, title:String, tint:Color) { Row(Modifier.fillMaxWidth().padding(vertical=14.dp),verticalAlignment=Alignment.CenterVertically) { IconTile(icon,tint,36.dp); Text(title,fontWeight=FontWeight.SemiBold,modifier=Modifier.padding(start=13.dp).weight(1f)); Text("✓",color=tint,fontWeight=FontWeight.Bold) } }

@Composable
private fun KmSymbol(icon: KmIcon, modifier: Modifier, tint: Color) {
    Canvas(modifier) { val w=size.width; val h=size.height; val sw=(w*.09f).coerceAtLeast(2f)
        when(icon) {
            KmIcon.GAUGE -> { drawArc(tint,205f,130f,false,style=Stroke(sw,cap=StrokeCap.Round)); drawLine(tint,center,Offset(w*.72f,h*.34f),sw,StrokeCap.Round); drawCircle(tint,sw*.7f,center) }
            KmIcon.PLUS -> { drawLine(tint,Offset(w*.5f,h*.18f),Offset(w*.5f,h*.82f),sw,StrokeCap.Round); drawLine(tint,Offset(w*.18f,h*.5f),Offset(w*.82f,h*.5f),sw,StrokeCap.Round) }
            KmIcon.CHECK -> { drawCircle(tint,w*.42f,style=Stroke(sw)); drawLine(tint,Offset(w*.27f,h*.52f),Offset(w*.44f,h*.68f),sw,StrokeCap.Round); drawLine(tint,Offset(w*.44f,h*.68f),Offset(w*.75f,h*.34f),sw,StrokeCap.Round) }
            KmIcon.CHART -> { drawLine(tint,Offset(w*.15f,h*.82f),Offset(w*.15f,h*.58f),sw,StrokeCap.Round); drawLine(tint,Offset(w*.5f,h*.82f),Offset(w*.5f,h*.35f),sw,StrokeCap.Round); drawLine(tint,Offset(w*.85f,h*.82f),Offset(w*.85f,h*.17f),sw,StrokeCap.Round) }
            KmIcon.ARCHIVE -> { drawRoundRect(tint.copy(alpha=.15f),Offset(w*.12f,h*.28f),Size(w*.76f,h*.58f)); drawRect(tint,Offset(w*.08f,h*.16f),Size(w*.84f,h*.2f)); drawLine(tint,Offset(w*.38f,h*.5f),Offset(w*.62f,h*.5f),sw,StrokeCap.Round) }
            KmIcon.BAG -> { val p=Path().apply{moveTo(w*.17f,h*.34f);lineTo(w*.83f,h*.34f);lineTo(w*.75f,h*.9f);lineTo(w*.25f,h*.9f);close()};drawPath(p,tint,style=Stroke(sw));drawArc(tint,180f,180f,false,Offset(w*.33f,h*.08f),Size(w*.34f,h*.45f),style=Stroke(sw)) }
            KmIcon.TAP -> { drawCircle(tint,w*.14f,Offset(w*.52f,h*.3f),style=Stroke(sw)); drawLine(tint,Offset(w*.5f,h*.3f),Offset(w*.5f,h*.72f),sw,StrokeCap.Round); drawLine(tint,Offset(w*.5f,h*.55f),Offset(w*.72f,h*.68f),sw,StrokeCap.Round) }
            KmIcon.HOURGLASS -> { drawLine(tint,Offset(w*.25f,h*.12f),Offset(w*.75f,h*.12f),sw,StrokeCap.Round);drawLine(tint,Offset(w*.25f,h*.88f),Offset(w*.75f,h*.88f),sw,StrokeCap.Round);val p=Path().apply{moveTo(w*.3f,h*.18f);cubicTo(w*.32f,h*.4f,w*.68f,h*.4f,w*.7f,h*.18f);moveTo(w*.3f,h*.82f);cubicTo(w*.32f,h*.6f,w*.68f,h*.6f,w*.7f,h*.82f)};drawPath(p,tint,style=Stroke(sw,cap=StrokeCap.Round)) }
            KmIcon.RETURN -> { drawArc(tint,50f,260f,false,style=Stroke(sw,cap=StrokeCap.Round));drawLine(tint,Offset(w*.16f,h*.28f),Offset(w*.16f,h*.58f),sw,StrokeCap.Round);drawLine(tint,Offset(w*.16f,h*.28f),Offset(w*.43f,h*.28f),sw,StrokeCap.Round) }
            KmIcon.EURO -> { drawCircle(tint,w*.44f,style=Stroke(sw));drawLine(tint,Offset(w*.28f,h*.44f),Offset(w*.62f,h*.44f),sw*.7f);drawLine(tint,Offset(w*.28f,h*.58f),Offset(w*.62f,h*.58f),sw*.7f) }
            KmIcon.GEAR -> { drawCircle(tint,w*.2f,style=Stroke(sw));drawCircle(tint,w*.42f,style=Stroke(sw));repeat(8){i->val a=Math.toRadians(i*45.0);val c=kotlin.math.cos(a).toFloat();val s=kotlin.math.sin(a).toFloat();drawLine(tint,Offset(center.x+c*w*.35f,center.y+s*h*.35f),Offset(center.x+c*w*.48f,center.y+s*h*.48f),sw,StrokeCap.Round)} }
            KmIcon.LOCK -> { drawRoundRect(tint.copy(alpha=.13f),Offset(w*.18f,h*.42f),Size(w*.64f,h*.48f));drawArc(tint,180f,180f,false,Offset(w*.3f,h*.08f),Size(w*.4f,h*.58f),style=Stroke(sw)) }
            KmIcon.BELL -> { drawArc(tint,185f,170f,false,Offset(w*.2f,h*.18f),Size(w*.6f,h*.62f),style=Stroke(sw));drawLine(tint,Offset(w*.2f,h*.58f),Offset(w*.12f,h*.8f),sw,StrokeCap.Round);drawLine(tint,Offset(w*.12f,h*.8f),Offset(w*.88f,h*.8f),sw,StrokeCap.Round);drawCircle(tint,sw*.7f,Offset(w*.5f,h*.91f)) }
            KmIcon.STAR -> { val p=Path();repeat(10){i->val a=Math.toRadians(-90.0+i*36);val r=if(i%2==0) w*.45f else w*.2f;val point=Offset(center.x+kotlin.math.cos(a).toFloat()*r,center.y+kotlin.math.sin(a).toFloat()*r);if(i==0)p.moveTo(point.x,point.y)else p.lineTo(point.x,point.y)};p.close();drawPath(p,tint) }
            KmIcon.CALENDAR -> { drawRoundRect(tint.copy(alpha=.12f),Offset(w*.12f,h*.2f),Size(w*.76f,h*.68f));drawRect(tint,Offset(w*.12f,h*.2f),Size(w*.76f,h*.2f));drawLine(tint,Offset(w*.32f,h*.1f),Offset(w*.32f,h*.3f),sw,StrokeCap.Round);drawLine(tint,Offset(w*.68f,h*.1f),Offset(w*.68f,h*.3f),sw,StrokeCap.Round) }
            KmIcon.STORE -> { drawRect(tint.copy(alpha=.12f),Offset(w*.18f,h*.38f),Size(w*.64f,h*.5f));drawLine(tint,Offset(w*.1f,h*.38f),Offset(w*.9f,h*.38f),sw,StrokeCap.Round);drawLine(tint,Offset(w*.2f,h*.12f),Offset(w*.8f,h*.12f),sw,StrokeCap.Round);drawLine(tint,Offset(w*.2f,h*.12f),Offset(w*.1f,h*.38f),sw);drawLine(tint,Offset(w*.8f,h*.12f),Offset(w*.9f,h*.38f),sw) }
        }
    }
}

private fun decisionColor(status: DecisionStatus)=when(status){DecisionStatus.KEEP->Success;DecisionStatus.REVIEW->Warning;DecisionStatus.RETURN_CANDIDATE->Danger}
private fun decisionLabel(status: DecisionStatus,c:Copy)=when(status){DecisionStatus.KEEP->c.t("BEHALTEN","KEEP");DecisionStatus.REVIEW->c.t("PRÜFEN","REVIEW");DecisionStatus.RETURN_CANDIDATE->c.t("ZURÜCK?","RETURN?")}
private fun reasonLabel(reason:DecisionReason,c:Copy)=when(reason){
    DecisionReason.DEADLINE_PASSED->c.t("Das eingetragene Rückgabedatum ist abgelaufen. Prüfe den Kauf und die Händlerbedingungen manuell.","The return date has passed. Review the purchase and merchant policy manually.")
    DecisionReason.UNUSED_URGENT->c.t("Noch ungenutzt und die Rückgabefrist läuft bald ab. Jetzt entscheiden.","Still unused and the return window is almost over. Decide now.")
    DecisionReason.LIGHTLY_USED_URGENT->c.t("Kaum genutzt und die Rückgabefrist ist nah. Prüfe, ob der Artikel seinen Platz verdient.","Barely used and the return deadline is close. Review whether it earns its place.")
    DecisionReason.UNUSED_LATE_WINDOW->c.t("Ein Großteil der Rückgabefrist ist ohne Nutzung vergangen.","Most of the return window has passed without a logged use.")
    DecisionReason.REPEATED_USE->c.t("Mehrfach genutzt – ein positives Signal. Die endgültige Entscheidung bleibt bei dir.","Used repeatedly — a positive signal. The final decision remains yours.")
    DecisionReason.EARLY_WINDOW->c.t("Noch früh in der Rückgabefrist. Nutze den Artikel normal weiter.","It is still early in the return window. Keep using the item normally.")
    DecisionReason.NEEDS_MORE_SIGNAL->c.t("Noch nicht genug Nutzungsdaten für ein klares Signal.","There is not enough usage evidence yet for a strong signal.")
}
private fun money(value:Double)=NumberFormat.getCurrencyInstance().format(value)
private fun currencySymbol()=NumberFormat.getCurrencyInstance().currency?.symbol ?: "€"
private fun date(epoch:Long)=Instant.ofEpochMilli(epoch).atZone(ZoneId.systemDefault()).toLocalDate().format(DateTimeFormatter.ofPattern("dd.MM.yyyy"))
private fun returnProgress(item:PurchaseWithUsage):Double { val total=item.purchase.returnDeadlineEpochMillis-item.purchase.purchaseDateEpochMillis; if(total<=0)return 1.0; return min(1.0,max(0.0,(System.currentTimeMillis()-item.purchase.purchaseDateEpochMillis).toDouble()/total)) }
