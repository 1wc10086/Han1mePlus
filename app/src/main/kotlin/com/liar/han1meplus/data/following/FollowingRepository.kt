package com.liar.han1meplus.data.following

import android.content.Context
import com.liar.han1meplus.data.video.VideoDetail
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

interface FollowingRepository {
    val store: StateFlow<FollowingStore>
    suspend fun setWatchLater(detail: VideoDetail, enabled: Boolean)
    suspend fun setFavorite(detail: VideoDetail, enabled: Boolean)
    suspend fun setSubscription(detail: VideoDetail, enabled: Boolean)
    suspend fun addSubscriptionVideoIfSubscribed(detail: VideoDetail)
    fun isWatchLater(videoCode: String): Boolean
    fun isFavorite(videoCode: String): Boolean
    fun isSubscribed(artistName: String?): Boolean
}

@Singleton
class FollowingRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val json: Json
) : FollowingRepository {

    private val mutex = Mutex()
    private val file = File(context.filesDir, "following_store.json")
    private val _store = MutableStateFlow(load())
    override val store: StateFlow<FollowingStore> = _store

    override suspend fun setWatchLater(detail: VideoDetail, enabled: Boolean) {
        update {
            val item = detail.toFollowingVideoItem()
            copy(
                watchLater = if (enabled) {
                    (listOf(item) + watchLater.filterNot { it.videoCode == item.videoCode })
                } else {
                    watchLater.filterNot { it.videoCode == item.videoCode }
                }
            )
        }
    }

    override suspend fun setFavorite(detail: VideoDetail, enabled: Boolean) {
        update {
            val item = detail.toFollowingVideoItem()
            copy(
                favorites = if (enabled) {
                    (listOf(item) + favorites.filterNot { it.videoCode == item.videoCode })
                } else {
                    favorites.filterNot { it.videoCode == item.videoCode }
                }
            )
        }
    }

    override suspend fun setSubscription(detail: VideoDetail, enabled: Boolean) {
        val artistName = detail.artistName?.trim().orEmpty()
        if (artistName.isBlank()) return
        val artistId = artistName.artistId()
        update {
            if (enabled) {
                val artist = SubscribedArtist(
                    id = artistId,
                    name = artistName,
                    avatarUrl = detail.artistAvatarUrl,
                    genre = detail.genre,
                    addedAt = System.currentTimeMillis()
                )
                val item = detail.toFollowingVideoItem()
                val videos = subscriptionVideos[artistId].orEmpty()
                copy(
                    subscribedArtists = (listOf(artist) + subscribedArtists.filterNot { it.id == artistId }),
                    subscriptionVideos = subscriptionVideos + (
                        artistId to (listOf(item) + videos.filterNot { it.videoCode == item.videoCode })
                    )
                )
            } else {
                copy(
                    subscribedArtists = subscribedArtists.filterNot { it.id == artistId },
                    subscriptionVideos = subscriptionVideos - artistId
                )
            }
        }
    }

    override suspend fun addSubscriptionVideoIfSubscribed(detail: VideoDetail) {
        val artistName = detail.artistName?.trim().orEmpty()
        if (artistName.isBlank()) return
        val artistId = artistName.artistId()
        if (!_store.value.subscribedArtists.any { it.id == artistId }) return
        update {
            val item = detail.toFollowingVideoItem()
            val videos = subscriptionVideos[artistId].orEmpty()
            copy(
                subscriptionVideos = subscriptionVideos + (
                    artistId to (listOf(item) + videos.filterNot { it.videoCode == item.videoCode })
                )
            )
        }
    }

    override fun isWatchLater(videoCode: String): Boolean {
        return _store.value.watchLater.any { it.videoCode == videoCode }
    }

    override fun isFavorite(videoCode: String): Boolean {
        return _store.value.favorites.any { it.videoCode == videoCode }
    }

    override fun isSubscribed(artistName: String?): Boolean {
        val name = artistName?.trim().orEmpty()
        if (name.isBlank()) return false
        return _store.value.subscribedArtists.any { it.id == name.artistId() }
    }

    private suspend fun update(transform: FollowingStore.() -> FollowingStore) {
        mutex.withLock {
            val next = _store.value.transform()
            _store.value = next
            save(next)
        }
    }

    private fun load(): FollowingStore {
        return runCatching {
            if (!file.exists()) FollowingStore()
            else json.decodeFromString<FollowingStore>(file.readText())
        }.getOrElse { FollowingStore() }
    }

    private fun save(store: FollowingStore) {
        file.writeText(json.encodeToString(store))
    }

    private fun VideoDetail.toFollowingVideoItem(): FollowingVideoItem {
        return FollowingVideoItem(
            videoCode = videoCode,
            title = title,
            coverUrl = coverUrl,
            artistName = artistName,
            artistAvatarUrl = artistAvatarUrl,
            genre = genre,
            addedAt = System.currentTimeMillis()
        )
    }

    private fun String.artistId(): String {
        return trim().lowercase().replace(Regex("""\s+"""), "_")
    }
}
