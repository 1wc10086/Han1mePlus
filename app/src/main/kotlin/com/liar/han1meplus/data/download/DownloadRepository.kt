package com.liar.han1meplus.data.download

import com.liar.han1meplus.data.video.VideoDetail
import com.liar.han1meplus.data.video.VideoSource
import kotlinx.coroutines.flow.StateFlow

interface DownloadRepository {
    val store: StateFlow<DownloadStore>
    suspend fun addGroup(name: String)
    suspend fun deleteTasks(taskIds: Set<String>)
    suspend fun createDownloadTask(
        detail: VideoDetail,
        source: VideoSource,
        groupId: String
    )
    suspend fun refresh()
    fun getCompletedLocalVideoPath(videoCode: String): String?
}
