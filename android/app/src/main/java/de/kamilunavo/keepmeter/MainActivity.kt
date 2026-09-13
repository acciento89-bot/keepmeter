package de.kamilunavo.keepmeter

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.LaunchedEffect
import androidx.lifecycle.viewmodel.compose.viewModel
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val storeScreenshotMode = BuildConfig.DEBUG &&
            intent.getBooleanExtra("de.kamilunavo.keepmeter.STORE_SCREENSHOTS", false)
        if (storeScreenshotMode) {
            Locale.setDefault(Locale.GERMANY)
            val germanConfiguration = resources.configuration
            germanConfiguration.setLocale(Locale.GERMANY)
            @Suppress("DEPRECATION")
            resources.updateConfiguration(germanConfiguration, resources.displayMetrics)
            getSharedPreferences("keepmeter", MODE_PRIVATE)
                .edit()
                .putBoolean("onboarding_done", true)
                .apply()
        }

        // KeepMeter's top surface is the blue brand gradient: use light status icons.
        // The bottom navigation is light: use dark navigation icons. Content handles
        // safe drawing insets inside Compose so carrier/time/battery never overlap UI.
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
        )

        setContent {
            val billing = androidx.compose.runtime.remember { BillingManager(applicationContext) }
            val vm: KeepMeterViewModel = viewModel()
            LaunchedEffect(storeScreenshotMode) {
                if (storeScreenshotMode) vm.seedStoreScreenshotData()
            }
            KeepMeterRoot(
                activity = this,
                vm = vm,
                billing = billing,
                forceGerman = storeScreenshotMode,
            )
        }
    }
}
