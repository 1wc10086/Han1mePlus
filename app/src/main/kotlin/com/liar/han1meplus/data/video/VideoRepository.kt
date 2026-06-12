package com.liar.han1meplus.data.video

import com.liar.han1meplus.data.download.DownloadRepository
import com.liar.han1meplus.data.download.DownloadVideoMeta
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import javax.inject.Inject

interface VideoRepository {
    fun getVideoDetail(baseUrl: String, videoCode: String): Flow<VideoDetail>
    fun getLocalVideoDetail(videoCode: String): Flow<VideoDetail>
}

class VideoRepositoryImpl @Inject constructor(
    private val okHttpClient: OkHttpClient,
    private val downloadRepository: DownloadRepository,
    private val json: Json
) : VideoRepository {

    override fun getVideoDetail(baseUrl: String, videoCode: String): Flow<VideoDetail> = flow {
        val url = "$baseUrl/watch?v=$videoCode"

        val request = Request.Builder()
            .url(url)
            .get()
            .header("User-Agent", USER_AGENT)
            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
            .header("Accept-Language", "zh-CN,zh;q=0.9,zh-TW;q=0.8,en;q=0.7")
            .header("Referer", baseUrl)
            .build()

        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throw IllegalStateException("请求失败：HTTP ${response.code}")
            val html = response.body.string()
            emit(VideoDetailParser.parse(html = html, baseUrl = baseUrl, videoCode = videoCode))
        }
    }.flowOn(Dispatchers.IO)

    override fun getLocalVideoDetail(videoCode: String): Flow<VideoDetail> = flow {
        val task = downloadRepository.store.value.tasks.firstOrNull { it.videoCode == videoCode }
            ?: throw IllegalStateException("本地缓存不存在")

        val metaPath = task.localMetaPath ?: throw IllegalStateException("本地简介不存在")
        val videoPath = task.localVideoPath ?: throw IllegalStateException("本地视频不存在")
        val meta = json.decodeFromString<DownloadVideoMeta>(File(metaPath).readText())

        emit(
            VideoDetail(
                videoCode = meta.videoCode,
                title = meta.title,
                coverUrl = task.localCoverPath ?: meta.coverUrl,
                artistName = meta.artistName,
                artistAvatarUrl = null,
                genre = meta.genre,
                viewsText = meta.viewsText,
                uploadDate = meta.uploadDate,
                introduction = meta.introduction,
                tags = meta.tags,
                downloadUrl = null,
                videoSources = listOf(
                    VideoSource(
                        quality = meta.sourceQuality,
                        url = File(videoPath).toURI().toString(),
                        type = "video/mp4"
                    )
                ),
                playlist = emptyList(),
                relatedVideos = emptyList()
            )
        )
    }.flowOn(Dispatchers.IO)

    private companion object {
        const val USER_AGENT =
            "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36"
    }
}
