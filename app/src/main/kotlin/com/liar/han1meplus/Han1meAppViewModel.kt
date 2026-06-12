package com.liar.han1meplus

import androidx.lifecycle.ViewModel
import com.liar.han1meplus.data.settings.AppSettings
import com.liar.han1meplus.data.settings.AppSettingsData
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

@HiltViewModel
class Han1meAppViewModel @Inject constructor(
    appSettings: AppSettings
) : ViewModel() {

    val settings: StateFlow<AppSettingsData> = appSettings.settings.stateIn(
        scope = viewModelScope,
        started = SharingStarted.Eagerly,
        initialValue = AppSettingsData()
    )
}
