package com.liar.han1meplus.data.watch

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable

@Serializable
@Immutable
data class ContinueWatchingItem(
    val videoCode: String,
    val title: String,
    val coverUrl: String?,
    val positionMs: Long,
    val durationMs: Long,
    val updatedAt: Long
)

@Serializable
@Immutable
data class WatchHistoryItem(
    val id: String,
    val videoCode: String,
    val title: String,
    val watchedMs: Long,
    val date: String,
    val createdAt: Long
)

@Serializable
@Immutable
data class WatchStore(
    val continueItems: List<ContinueWatchingItem> = emptyList(),
    val histories: List<WatchHistoryItem> = emptyList()
)

@Immutable
data class DailyWatchStats(
    val date: String,
    val totalMs: Long,
    val items: List<DailyWatchVideoStats>
)

@Immutable
data class DailyWatchVideoStats(
    val title: String,
    val totalMs: Long
)
