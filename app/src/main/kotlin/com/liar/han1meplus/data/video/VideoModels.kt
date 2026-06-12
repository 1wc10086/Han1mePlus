package com.liar.han1meplus.data.video

import androidx.compose.runtime.Immutable

@Immutable
data class VideoDetail(
    val videoCode: String,
    val title: String,
    val coverUrl: String?,
    val artistName: String?,
    val artistAvatarUrl: String?,
    val genre: String?,
    val viewsText: String?,
    val uploadDate: String?,
    val introduction: String?,
    val tags: List<String>,
    val downloadUrl: String?,
    val videoSources: List<VideoSource>,
    val playlist: List<VideoSimpleItem>,
    val relatedVideos: List<VideoSimpleItem>
)

@Immutable
data class VideoSource(
    val quality: String,
    val url: String,
    val type: String?
)

@Immutable
data class VideoSimpleItem(
    val videoCode: String,
    val title: String,
    val coverUrl: String,
    val duration: String?,
    val views: String?,
    val rating: String?,
    val artist: String?,
    val isPlaying: Boolean = false
)
