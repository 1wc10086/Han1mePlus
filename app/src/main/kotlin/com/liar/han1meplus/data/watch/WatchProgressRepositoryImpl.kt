package com.liar.han1meplus.data.watch

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WatchProgressRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val json: Json
) : WatchProgressRepository {

    private val mutex = Mutex()
    private val file = File(context.filesDir, "watch_store.json")
    private val _store = MutableStateFlow(load())
    override val store: StateFlow<WatchStore> = _store

    override suspend fun updateProgress(
        videoCode: String,
        title: String,
        coverUrl: String?,
        positionMs: Long,
        durationMs: Long
    ) {
        val now = System.currentTimeMillis()
        update {
            val next = ContinueWatchingItem(
                videoCode = videoCode,
                title = title,
                coverUrl = coverUrl,
                positionMs = positionMs.coerceAtLeast(0L),
                durationMs = durationMs.coerceAtLeast(0L),
                updatedAt = now
            )
            copy(
                continueItems = (listOf(next) + continueItems.filterNot { it.videoCode == videoCode })
                    .take(6)
            )
        }
    }

    override suspend fun addWatchTime(
        videoCode: String,
        title: String,
        watchedMs: Long
    ) {
        if (watchedMs <= 0L) return
        val now = System.currentTimeMillis()
        update {
            copy(
                histories = histories + WatchHistoryItem(
                    id = UUID.randomUUID().toString(),
                    videoCode = videoCode,
                    title = title,
                    watchedMs = watchedMs,
                    date = LocalDate.now().toString(),
                    createdAt = now
                )
            )
        }
    }

    override fun getProgress(videoCode: String): ContinueWatchingItem? {
        return _store.value.continueItems.firstOrNull { it.videoCode == videoCode }
    }

    override fun getContinueWatching(): List<ContinueWatchingItem> {
        return _store.value.continueItems.sortedByDescending { it.updatedAt }.take(6)
    }

    override fun getDailyStats(date: LocalDate): DailyWatchStats {
        val day = date.toString()
        val items = _store.value.histories
            .filter { it.date == day }
            .groupBy { it.title }
            .map { (title, histories) ->
                DailyWatchVideoStats(
                    title = title,
                    totalMs = histories.sumOf { it.watchedMs }
                )
            }
            .sortedByDescending { it.totalMs }

        return DailyWatchStats(
            date = day,
            totalMs = items.sumOf { it.totalMs },
            items = items
        )
    }

    private suspend fun update(transform: WatchStore.() -> WatchStore) {
        mutex.withLock {
            val next = _store.value.transform()
            _store.value = next
            save(next)
        }
    }

    private fun load(): WatchStore {
        return runCatching {
            if (!file.exists()) WatchStore()
            else json.decodeFromString<WatchStore>(file.readText())
        }.getOrElse { WatchStore() }
    }

    private fun save(store: WatchStore) {
        file.writeText(json.encodeToString(store))
    }
}
