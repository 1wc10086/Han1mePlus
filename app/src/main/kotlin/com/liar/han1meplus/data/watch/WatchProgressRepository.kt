package com.liar.han1meplus.data.watch

import kotlinx.coroutines.flow.StateFlow
import java.time.LocalDate

interface WatchProgressRepository {
    val store: StateFlow<WatchStore>
    suspend fun updateProgress(
        videoCode: String,
        title: String,
        coverUrl: String?,
        positionMs: Long,
        durationMs: Long
    )
    suspend fun addWatchTime(
        videoCode: String,
        title: String,
        watchedMs: Long
    )
    fun getProgress(videoCode: String): ContinueWatchingItem?
    fun getContinueWatching(): List<ContinueWatchingItem>
    fun getDailyStats(date: LocalDate): DailyWatchStats
}
