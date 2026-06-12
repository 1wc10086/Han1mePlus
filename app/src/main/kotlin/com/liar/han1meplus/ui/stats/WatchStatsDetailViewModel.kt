package com.liar.han1meplus.ui.stats

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liar.han1meplus.data.watch.WatchProgressRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate
import javax.inject.Inject

enum class StatsRange {
    Week,
    Month,
    Year
}

data class WatchStatsChartItem(
    val label: String,
    val valueMs: Long
)

data class WatchStatsDetailUiState(
    val range: StatsRange = StatsRange.Week,
    val watchedVideoCount: Int = 0,
    val chartItems: List<WatchStatsChartItem> = emptyList()
)

@HiltViewModel
class WatchStatsDetailViewModel @Inject constructor(
    private val repository: WatchProgressRepository
) : ViewModel() {

    private val range = kotlinx.coroutines.flow.MutableStateFlow(StatsRange.Week)

    val uiState: StateFlow<WatchStatsDetailUiState> = kotlinx.coroutines.flow.combine(
        range,
        repository.store
    ) { currentRange, store ->
        val today = LocalDate.now()
        val dates = when (currentRange) {
            StatsRange.Week -> (6 downTo 0).map { today.minusDays(it.toLong()) }
            StatsRange.Month -> (29 downTo 0).map { today.minusDays(it.toLong()) }
            StatsRange.Year -> (11 downTo 0).map { today.minusMonths(it.toLong()).withDayOfMonth(1) }
        }

        val histories = store.histories
        val chartItems = when (currentRange) {
            StatsRange.Week,
            StatsRange.Month -> dates.map { date ->
                val total = histories.filter { it.date == date.toString() }.sumOf { it.watchedMs }
                WatchStatsChartItem(date.monthValue.toString() + "/" + date.dayOfMonth, total)
            }

            StatsRange.Year -> dates.map { month ->
                val total = histories.filter {
                    val d = runCatching { LocalDate.parse(it.date) }.getOrNull()
                    d != null && d.year == month.year && d.month == month.month
                }.sumOf { it.watchedMs }
                WatchStatsChartItem(month.monthValue.toString() + "月", total)
            }
        }

        WatchStatsDetailUiState(
            range = currentRange,
            watchedVideoCount = histories.map { it.videoCode }.distinct().size,
            chartItems = chartItems
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = WatchStatsDetailUiState()
    )

    fun selectRange(range: StatsRange) {
        this.range.value = range
    }
}
