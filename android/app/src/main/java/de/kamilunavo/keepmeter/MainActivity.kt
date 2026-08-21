package de.kamilunavo.keepmeter

import android.Manifest
import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import de.kamilunavo.keepmeter.data.PurchaseWithUsage
import de.kamilunavo.keepmeter.domain.DecisionReason
import de.kamilunavo.keepmeter.domain.DecisionStatus
import java.text.NumberFormat
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val billing = remember { BillingManager(applicationContext) }
            val vm: KeepMeterViewModel = viewModel()
            KeepMeterApp(activity = this, vm = vm, billing = billing)
        }
    }
}

private enum class MainTab { ACTIVE, INSIGHTS, ARCHIVE, SETTINGS }

@Composable
private fun KeepMeterApp(activity: Activity, vm: KeepMeterViewModel, billing: BillingManager) {
    val prefs = remember { activity.getSharedPreferences("keepmeter", Context.MODE_PRIVATE) }
    var onboardingDone by remember { mutableStateOf(prefs.getBoolean("onboarding_done", false)) }

    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Color(0xFF4F7CF7),
            secondary = Color(0xFF64A1FF),
            background = Color(0xFF0D1117),
            surface = Color(0xFF171D26),
        )
    ) {
        if (!onboardingDone) {
            Onboarding {
                prefs.edit().putBoolean("onboarding_done", true).apply()
                onboardingDone = true
            }
        } else {
            MainShell(activity, vm, billing)
        }
    }
}

@Composable
private fun Onboarding(onDone: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        Text("KeepMeter", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Black)
        Text("Behalten oder zurückgeben – bevor die Rückgabefrist vorbei ist.", modifier = Modifier.padding(top = 12.dp))
        Text(
            "Erfasse Käufe, zähle reale Nutzungen und lass dir anhand der Rückgabefrist eine klare Entscheidungshilfe anzeigen.",
            color = Color.LightGray,
            modifier = Modifier.padding(top = 12.dp, bottom = 24.dp),
        )
        Button(onClick = onDone, modifier = Modifier.fillMaxWidth()) { Text("Loslegen") }
    }
}

@Composable
private fun MainShell(activity: Activity, vm: KeepMeterViewModel, billing: BillingManager) {
    var selectedTab by remember { mutableIntStateOf(0) }
    var showAdd by remember { mutableStateOf(false) }
    var showPaywall by remember { mutableStateOf(false) }
    val tabs = MainTab.entries

    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEachIndexed { index, tab ->
                    NavigationBarItem(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        icon = { Text(tabIcon(tab)) },
                        label = { Text(tabTitle(tab)) },
                    )
                }
            }
        },
        floatingActionButton = {
            if (tabs[selectedTab] == MainTab.ACTIVE) {
                FloatingActionButton(onClick = { showAdd = true }) { Text("+") }
            }
        },
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            when (tabs[selectedTab]) {
                MainTab.ACTIVE -> ActiveScreen(vm, billing.isPro)
                MainTab.INSIGHTS -> InsightsScreen(vm)
                MainTab.ARCHIVE -> ArchiveScreen(vm)
                MainTab.SETTINGS -> SettingsScreen(activity, billing) { showPaywall = true }
            }
        }
    }

    if (showAdd) {
        AddPurchaseDialog(
            isPro = billing.isPro,
            vm = vm,
            onDismiss = { showAdd = false },
            onFreeLimit = {
                showAdd = false
                showPaywall = true
            },
        )
    }

    if (showPaywall) {
        PaywallDialog(activity, billing) { showPaywall = false }
    }
}

private fun tabIcon(tab: MainTab): String = when (tab) {
    MainTab.ACTIVE -> "●"
    MainTab.INSIGHTS -> "▥"
    MainTab.ARCHIVE -> "□"
    MainTab.SETTINGS -> "⚙"
}

private fun tabTitle(tab: MainTab): String = when (tab) {
    MainTab.ACTIVE -> "Aktiv"
    MainTab.INSIGHTS -> "Insights"
    MainTab.ARCHIVE -> "Archiv"
    MainTab.SETTINGS -> "Einstellungen"
}

@Composable
private fun ActiveScreen(vm: KeepMeterViewModel, isPro: Boolean) {
    val items by vm.activePurchases.collectAsStateWithLifecycle()

    Header("Aktive Käufe", if (isPro) "KeepMeter Pro" else "Free · ${items.size}/5 aktiv")
    if (items.isEmpty()) {
        InfoCard("Noch keine aktiven Käufe", "Lege deinen ersten Kauf an und KeepMeter beobachtet Nutzung und Rückgabefrist.")
    } else {
        items.forEach { item -> PurchaseCard(item, vm, active = true) }
    }
}

@Composable
private fun InsightsScreen(vm: KeepMeterViewModel) {
    val active by vm.activePurchases.collectAsStateWithLifecycle()
    val archived by vm.archivedPurchases.collectAsStateWithLifecycle()
    val all by vm.allPurchases.collectAsStateWithLifecycle()
    val totalValue = active.sumOf { it.purchase.price }
    val totalUses = all.sumOf { it.usageEvents.size }
    val returnCandidates = active.count { vm.decision(it).status == DecisionStatus.RETURN_CANDIDATE }

    Header("Insights", "Deine Kaufentscheidungen auf einen Blick")
    MetricCard("Aktiver Warenwert", money(totalValue))
    MetricCard("Erfasste Nutzungen", totalUses.toString())
    MetricCard("Rückgabe-Kandidaten", returnCandidates.toString())
    MetricCard("Abgeschlossene Entscheidungen", archived.size.toString())
}

@Composable
private fun ArchiveScreen(vm: KeepMeterViewModel) {
    val items by vm.archivedPurchases.collectAsStateWithLifecycle()
    Header("Archiv", "Behaltene und zurückgegebene Käufe")
    if (items.isEmpty()) {
        InfoCard("Archiv ist leer", "Sobald du einen Kauf behältst oder zurückgibst, erscheint er hier.")
    } else {
        items.forEach { item -> PurchaseCard(item, vm, active = false) }
    }
}

@Composable
private fun SettingsScreen(activity: Activity, billing: BillingManager, onPaywall: () -> Unit) {
    val notificationLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }

    Header("Einstellungen", if (billing.isPro) "Lifetime Pro aktiv" else "KeepMeter Free")
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("KeepMeter Pro", fontWeight = FontWeight.Bold)
            Text(
                if (billing.isPro) "Unbegrenzt aktive Käufe sind freigeschaltet."
                else "Free erlaubt bis zu 5 aktive Käufe. Lifetime Pro hebt dieses Limit dauerhaft auf.",
                color = Color.LightGray,
            )
            if (!billing.isPro) Button(onClick = onPaywall, modifier = Modifier.fillMaxWidth()) { Text("Lifetime Pro ansehen") }
            OutlinedButton(onClick = billing::restorePurchases, modifier = Modifier.fillMaxWidth()) { Text("Käufe wiederherstellen") }
        }
    }

    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Rückgabefrist-Erinnerungen", fontWeight = FontWeight.Bold)
            Text("KeepMeter plant Erinnerungen 3 Tage, 1 Tag und am Tag der Rückgabefrist.", color = Color.LightGray)
            if (Build.VERSION.SDK_INT >= 33) {
                OutlinedButton(
                    onClick = { notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS) },
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Benachrichtigungen erlauben") }
            }
        }
    }

    billing.statusMessage?.let { Text(it, color = MaterialTheme.colorScheme.error) }
    Text("Daten bleiben lokal auf diesem Gerät. Kein Konto, keine Werbung, kein Tracking.", color = Color.LightGray)
}

@Composable
private fun AddPurchaseDialog(
    isPro: Boolean,
    vm: KeepMeterViewModel,
    onDismiss: () -> Unit,
    onFreeLimit: () -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var merchant by remember { mutableStateOf("") }
    var price by remember { mutableStateOf("") }
    var days by remember { mutableStateOf("14") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Kauf hinzufügen") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(name, { name = it }, label = { Text("Produkt") }, singleLine = true)
                OutlinedTextField(merchant, { merchant = it }, label = { Text("Händler") }, singleLine = true)
                OutlinedTextField(
                    price,
                    { next -> if (next.all { it.isDigit() || it == ',' || it == '.' }) price = next },
                    label = { Text("Preis €") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                )
                OutlinedTextField(
                    days,
                    { next -> if (next.all(Char::isDigit)) days = next },
                    label = { Text("Rückgabefrist in Tagen") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                )
            }
        },
        confirmButton = {
            Button(
                enabled = name.isNotBlank() && (price.replace(',', '.').toDoubleOrNull() ?: 0.0) >= 0 && (days.toLongOrNull() ?: 0) > 0,
                onClick = {
                    val deadline = System.currentTimeMillis() + (days.toLongOrNull() ?: 14L) * 86_400_000L
                    vm.addPurchase(
                        name = name,
                        merchant = merchant,
                        price = price.replace(',', '.').toDoubleOrNull() ?: 0.0,
                        returnDeadlineEpochMillis = deadline,
                        isPro = isPro,
                    ) { added ->
                        if (added) onDismiss() else onFreeLimit()
                    }
                },
            ) { Text("Hinzufügen") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Abbrechen") } },
    )
}

@Composable
private fun PaywallDialog(activity: Activity, billing: BillingManager, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("KeepMeter Pro – Lifetime") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Unbegrenzt aktive Käufe. Einmal zahlen.")
                Text("Kein Abo. Lifetime-Freischaltung über Google Play.", color = Color.LightGray)
            }
        },
        confirmButton = {
            Button(onClick = { billing.launchPurchase(activity) }, enabled = billing.billingReady) {
                Text("Lifetime Pro${billing.productPrice?.let { " · $it" } ?: ""}")
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Später") } },
    )
}

@Composable
private fun PurchaseCard(item: PurchaseWithUsage, vm: KeepMeterViewModel, active: Boolean) {
    val decision = vm.decision(item)
    val purchase = item.purchase
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(purchase.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            if (purchase.merchant.isNotBlank()) Text(purchase.merchant, color = Color.LightGray)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(money(purchase.price))
                Text("${item.usageEvents.size}× genutzt")
            }
            Text("Rückgabe bis ${date(purchase.returnDeadlineEpochMillis)}", color = Color.LightGray)

            if (active) {
                Text(decisionLabel(decision.status), fontWeight = FontWeight.Bold, color = decisionColor(decision.status))
                Text(reasonLabel(decision.reason), color = Color.LightGray)
                decision.costPerUse?.let { Text("Kosten/Nutzung: ${money(it)}", color = Color.LightGray) }
                OutlinedButton(onClick = { vm.recordUsage(purchase.id) }, modifier = Modifier.fillMaxWidth()) { Text("Nutzung +1") }
                Button(onClick = { vm.markKept(purchase.id) }, modifier = Modifier.fillMaxWidth()) { Text("Behalten") }
                OutlinedButton(onClick = { vm.markReturned(purchase.id) }, modifier = Modifier.fillMaxWidth()) { Text("Zurückgegeben") }
            } else {
                Text(if (purchase.outcome == "kept") "Behalten" else "Zurückgegeben", fontWeight = FontWeight.Bold)
                TextButton(onClick = { vm.deletePurchase(purchase.id) }) { Text("Aus Archiv löschen") }
            }
        }
    }
}

@Composable
private fun Header(title: String, subtitle: String) {
    Text(title, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
    Text(subtitle, color = Color.LightGray)
}

@Composable
private fun InfoCard(title: String, body: String) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(Modifier.padding(16.dp)) {
            Text(title, fontWeight = FontWeight.Bold)
            Text(body, color = Color.LightGray, modifier = Modifier.padding(top = 6.dp))
        }
    }
}

@Composable
private fun MetricCard(title: String, value: String) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(Modifier.fillMaxWidth().padding(16.dp)) {
            Text(title, color = Color.LightGray)
            Text(value, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
        }
    }
}

private fun decisionLabel(status: DecisionStatus): String = when (status) {
    DecisionStatus.KEEP -> "Eher behalten"
    DecisionStatus.REVIEW -> "Prüfen"
    DecisionStatus.RETURN_CANDIDATE -> "Rückgabe prüfen"
}

private fun decisionColor(status: DecisionStatus): Color = when (status) {
    DecisionStatus.KEEP -> Color(0xFF22A86E)
    DecisionStatus.REVIEW -> Color(0xFFF2931F)
    DecisionStatus.RETURN_CANDIDATE -> Color(0xFFEB454F)
}

private fun reasonLabel(reason: DecisionReason): String = when (reason) {
    DecisionReason.DEADLINE_PASSED -> "Rückgabefrist ist bereits vorbei."
    DecisionReason.UNUSED_URGENT -> "Noch ungenutzt und nur wenige Tage Rückgabefrist."
    DecisionReason.LIGHTLY_USED_URGENT -> "Kaum genutzt und Rückgabefrist endet bald."
    DecisionReason.UNUSED_LATE_WINDOW -> "Großer Teil der Rückgabefrist vorbei, aber noch ungenutzt."
    DecisionReason.REPEATED_USE -> "Mehrfach genutzt – starkes Behalten-Signal."
    DecisionReason.EARLY_WINDOW -> "Noch früh in der Rückgabefrist – mehr Nutzungssignal sammeln."
    DecisionReason.NEEDS_MORE_SIGNAL -> "Noch kein eindeutiges Signal."
}

private fun money(value: Double): String = NumberFormat.getCurrencyInstance(Locale.GERMANY).format(value)

private fun date(epochMillis: Long): String = Instant.ofEpochMilli(epochMillis)
    .atZone(ZoneId.systemDefault())
    .toLocalDate()
    .format(DateTimeFormatter.ofPattern("dd.MM.yyyy"))
