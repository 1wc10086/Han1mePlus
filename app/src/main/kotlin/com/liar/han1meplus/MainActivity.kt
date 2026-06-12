package com.liar.han1meplus

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.lifecycleScope
import com.liar.han1meplus.data.settings.AppSettings
import com.liar.han1meplus.data.update.UpdateChecker
import com.liar.han1meplus.data.update.UpdateInfo
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var updateChecker: UpdateChecker

    @Inject
    lateinit var appSettings: AppSettings

    private var updateInfo by mutableStateOf<UpdateInfo?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()

        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            Han1meApp(
                updateInfo = updateInfo,
                onUpdateDialogDismiss = {
                    updateInfo = null
                }
            )
        }

        lifecycleScope.launch {
            val settings = appSettings.settings.first()

            if (settings.autoUpdate) {
                val info = updateChecker.checkForUpdate()

                if (info != null) {
                    updateInfo = info
                }
            }
        }
    }
}
