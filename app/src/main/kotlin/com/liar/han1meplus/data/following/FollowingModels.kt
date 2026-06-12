package com.liar.han1meplus.data.following

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable

@Serializable
@Immutable
data class FollowingVideoItem(
    val videoCode: String,
    val title: String,
    val coverUrl: String?,
    val artistName: String?,
    val artistAvatarUrl: String?,
    val genre: String?,
    val addedAt: Long
)

@Serializable
@Immutable
data class SubscribedArtist(
    val id: String,
    val name: String,
    val avatarUrl: String?,
    val genre: String?,
    val addedAt: Long
)

@Serializable
@Immutable
data class FollowingStore(
    val watchLater: List<FollowingVideoItem> = emptyList(),
    val favorites: List<FollowingVideoItem> = emptyList(),
    val subscribedArtists: List<SubscribedArtist> = emptyList(),
    val subscriptionVideos: Map<String, List<FollowingVideoItem>> = emptyMap()
)
