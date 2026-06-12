package com.liar.han1meplus.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liar.han1meplus.data.settings.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val appSettings: AppSettings
) : ViewModel() {

    val settings: StateFlow<AppSettingsData> = appSettings.settings.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = AppSettingsData()
    )

    fun setDarkTheme(v: DarkThemeConfig) = viewModelScope.launch { appSettings.setDarkTheme(v) }
    fun setColorScheme(v: ColorSchemeConfig) = viewModelScope.launch { appSettings.setColorScheme(v) }
    fun setBaseUrl(v: String) = viewModelScope.launch { appSettings.setBaseUrl(v) }
    fun setVideoResolution(v: VideoResolution) = viewModelScope.launch { appSettings.setVideoResolution(v) }
    fun setPlayerKernel(v: PlayerKernel) = viewModelScope.launch { appSettings.setPlayerKernel(v) }
    fun setAutoUpdate(v: Boolean) = viewModelScope.launch { appSettings.setAutoUpdate(v) }
}
