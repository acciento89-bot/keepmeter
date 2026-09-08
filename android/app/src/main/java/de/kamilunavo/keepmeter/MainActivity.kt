package de.kamilunavo.keepmeter

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.LaunchedEffect
import androidx.core.view.WindowCompat
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
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }
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
