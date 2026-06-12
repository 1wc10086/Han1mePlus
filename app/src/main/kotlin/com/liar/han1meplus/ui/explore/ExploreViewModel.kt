package com.liar.han1meplus.ui.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liar.han1meplus.data.explore.ExploreRepository
import com.liar.han1meplus.data.explore.HomePage
import com.liar.han1meplus.data.settings.AppSettings
import com.liar.han1meplus.data.watch.ContinueWatchingItem
import com.liar.han1meplus.data.watch.WatchProgressRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface ExploreLoadState {
    data object Loading : ExploreLoadState
    data class Success(val homePage: HomePage, val isRefreshing: Boolean = false) : ExploreLoadState
    data class Error(val message: String) : ExploreLoadState
}

data class ExploreUiState(
    val loadState: ExploreLoadState = ExploreLoadState.Loading,
    val continueWatching: List<ContinueWatchingItem> = emptyList()
)

@HiltViewModel
class ExploreViewModel @Inject constructor(
    private val repository: ExploreRepository,
    private val appSettings: AppSettings,
    watchProgressRepository: WatchProgressRepository
) : ViewModel() {

    private val loadState = MutableStateFlow<ExploreLoadState>(ExploreLoadState.Loading)

    val uiState: StateFlow<ExploreUiState> = combine(
        loadState,
        watchProgressRepository.store
    ) { state, watchStore ->
        ExploreUiState(
            loadState = state,
            continueWatching = watchStore.continueItems.sortedByDescending { it.updatedAt }.take(6)
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = ExploreUiState()
    )

    private var loadJob: Job? = null

    init {
        loadHomePage()
    }

    fun retry() = loadHomePage()

    private fun loadHomePage() {
        loadJob?.cancel()
        loadJob = viewModelScope.launch {
            val baseUrl = appSettings.settings.first().baseUrl
            var isFirstEmit = true

            repository.getHomePage(baseUrl)
                .catch { e ->
                    val current = loadState.value
                    if (current is ExploreLoadState.Success) {
                        loadState.update { current.copy(isRefreshing = false) }
                    } else {
                        loadState.value = ExploreLoadState.Error(e.message ?: "未知错误")
                    }
                }
                .collect { homePage ->
                    if (isFirstEmit) {
                        isFirstEmit = false
                        loadState.value = ExploreLoadState.Success(homePage, isRefreshing = false)
                    } else {
                        loadState.value = ExploreLoadState.Success(homePage, isRefreshing = false)
                    }
                }
        }
    }
}
