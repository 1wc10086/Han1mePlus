package com.liar.han1meplus.data.download

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable

@Serializable
enum class DownloadStatus {
    Queued,
    Downloading,
    Completed,
    Failed
}

@Serializable
@Immutable
data class DownloadGroup(
    val id: String,
    val name: String,
    val createdAt: Long
)

@Serializable
@Immutable
data class DownloadVideoMeta(
    val videoCode: String,
    val title: String,
    val coverUrl: String?,
    val artistName: String?,
    val genre: String?,
    val viewsText: String?,
    val uploadDate: String?,
    val introduction: String?,
    val tags: List<String>,
    val durationText: String?,
    val sourceQuality: String,
    val sourceUrl: String
)

@Serializable
@Immutable
data class DownloadTask(
    val id: String,
    val videoCode: String,
    val title: String,
    val coverUrl: String?,
    val groupId: String,
    val quality: String,
    val status: DownloadStatus,
    val progress: Float,
    val downloadedBytes: Long,
    val totalBytes: Long,
    val localVideoPath: String?,
    val localCoverPath: String?,
    val localMetaPath: String?,
    val localCommentPath: String?,
    val errorMessage: String?,
    val createdAt: Long,
    val updatedAt: Long
)

@Serializable
@Immutable
data class DownloadStore(
    val groups: List<DownloadGroup> = listOf(
        DownloadGroup(
            id = "default",
            name = "默认分组",
            createdAt = 0L
        )
    ),
    val tasks: List<DownloadTask> = emptyList()
)
