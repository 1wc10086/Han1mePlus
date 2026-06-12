package com.liar.han1meplus.ui.stats

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liar.han1meplus.data.watch.DailyWatchStats
import com.liar.han1meplus.data.watch.WatchProgressRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate
import javax.inject.Inject

data class WatchStatsUiState(
    val selectedDate: LocalDate = LocalDate.now(),
    val dailyStats: DailyWatchStats = DailyWatchStats(LocalDate.now().toString(), 0L, emptyList())
)

@HiltViewModel
class WatchStatsViewModel @Inject constructor(
    private val repository: WatchProgressRepository
) : ViewModel() {

    private val selectedDate = MutableStateFlow(LocalDate.now())

    val uiState: StateFlow<WatchStatsUiState> = combine(
        selectedDate,
        repository.store
    ) { date, _ ->
        WatchStatsUiState(
            selectedDate = date,
            dailyStats = repository.getDailyStats(date)
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = WatchStatsUiState()
    )

    fun selectDate(date: LocalDate) {
        selectedDate.value = date
    }
}
