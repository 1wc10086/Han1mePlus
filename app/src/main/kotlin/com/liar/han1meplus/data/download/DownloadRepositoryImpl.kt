package com.liar.han1meplus.data.download

import android.content.Context
import com.liar.han1meplus.data.comment.CommentRepository
import com.liar.han1meplus.data.settings.AppSettings
import com.liar.han1meplus.data.video.VideoDetail
import com.liar.han1meplus.data.video.VideoSource
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.Request
import okio.buffer
import okio.sink
import java.io.File
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.max

@Singleton
class DownloadRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val okHttpClient: OkHttpClient,
    private val json: Json,
    private val commentRepository: CommentRepository,
    private val appSettings: AppSettings
) : DownloadRepository {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mutex = Mutex()
    private val rootDir = File(context.getExternalFilesDir(null), "Download")
    private val storeFile = File(rootDir, "download_store.json")

    private val _store = MutableStateFlow(loadStore())
    override val store: StateFlow<DownloadStore> = _store

    override suspend fun addGroup(name: String) {
        val trimmed = name.trim()
        if (trimmed.isBlank()) return
        updateStore {
            if (groups.any { it.name == trimmed }) this
            else copy(
                groups = groups + DownloadGroup(
                    id = UUID.randomUUID().toString(),
                    name = trimmed,
                    createdAt = System.currentTimeMillis()
                )
            )
        }
    }

    override suspend fun deleteTasks(taskIds: Set<String>) {
        if (taskIds.isEmpty()) return
        val deleted = _store.value.tasks.filter { it.id in taskIds }
        deleted.forEach { task ->
            runCatching {
                File(rootDir, task.videoCode).deleteRecursively()
            }
        }
        updateStore {
            copy(tasks = tasks.filterNot { it.id in taskIds })
        }
    }

    override suspend fun createDownloadTask(
        detail: VideoDetail,
        source: VideoSource,
        groupId: String
    ) {
        val now = System.currentTimeMillis()
        val id = detail.videoCode
        val task = DownloadTask(
            id = id,
            videoCode = detail.videoCode,
            title = detail.title,
            coverUrl = detail.coverUrl,
            groupId = groupId,
            quality = source.quality,
            status = DownloadStatus.Queued,
            progress = 0f,
            downloadedBytes = 0L,
            totalBytes = 0L,
            localVideoPath = null,
            localCoverPath = null,
            localMetaPath = null,
            localCommentPath = null,
            errorMessage = null,
            createdAt = now,
            updatedAt = now
        )

        updateStore {
            copy(tasks = tasks.filterNot { it.videoCode == detail.videoCode } + task)
        }

        scope.launch {
            download(task, detail, source)
        }
    }

    override suspend fun refresh() {
        _store.value = loadStore()
    }

    override fun getCompletedLocalVideoPath(videoCode: String): String? {
        return _store.value.tasks.firstOrNull {
            it.videoCode == videoCode && it.status == DownloadStatus.Completed
        }?.localVideoPath
    }

    private suspend fun download(
        task: DownloadTask,
        detail: VideoDetail,
        source: VideoSource
    ) {
        val videoDir = File(rootDir, task.videoCode).apply { mkdirs() }
        val videoFile = File(videoDir, "video_${source.quality}.mp4")
        val coverFile = File(videoDir, "cover")
        val metaFile = File(videoDir, "detail.json")
        val commentFile = File(videoDir, "comments.json")

        runCatching {
            updateTask(task.id) {
                copy(
                    status = DownloadStatus.Downloading,
                    updatedAt = System.currentTimeMillis()
                )
            }

            saveMeta(detail, source, metaFile)
            downloadCover(detail.coverUrl, coverFile)

            val settings = appSettings.settings.first()
            val comments = runCatching {
                commentRepository.getComments(settings.baseUrl, detail.videoCode, 1).first()
            }.getOrNull()
            if (comments != null) {
                commentFile.writeText(json.encodeToString(comments))
            }

            val request = Request.Builder()
                .url(source.url)
                .get()
                .header("User-Agent", USER_AGENT)
                .header("Referer", settings.baseUrl)
                .build()

            okHttpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) error("HTTP ${response.code}")
                val body = response.body
                val total = body.contentLength().coerceAtLeast(0L)
                var downloaded = 0L
                body.source().use { input ->
                    videoFile.sink().buffer().use { output ->
                        val buffer = okio.Buffer()
                        while (true) {
                            val read = input.read(buffer, 128 * 1024)
                            if (read == -1L) break
                            output.write(buffer, read)
                            downloaded += read
                            val progress = if (total > 0L) downloaded.toFloat() / total.toFloat() else 0f
                            updateTask(task.id) {
                                copy(
                                    status = DownloadStatus.Downloading,
                                    progress = progress.coerceIn(0f, 1f),
                                    downloadedBytes = downloaded,
                                    totalBytes = total,
                                    updatedAt = System.currentTimeMillis()
                                )
                            }
                        }
                    }
                }
            }

            updateTask(task.id) {
                copy(
                    status = DownloadStatus.Completed,
                    progress = 1f,
                    localVideoPath = videoFile.absolutePath,
                    localCoverPath = coverFile.takeIf { it.exists() }?.absolutePath,
                    localMetaPath = metaFile.absolutePath,
                    localCommentPath = commentFile.takeIf { it.exists() }?.absolutePath,
                    errorMessage = null,
                    updatedAt = System.currentTimeMillis()
                )
            }
        }.onFailure { e ->
            updateTask(task.id) {
                copy(
                    status = DownloadStatus.Failed,
                    errorMessage = e.message ?: "下载失败",
                    updatedAt = System.currentTimeMillis()
                )
            }
        }
    }

    private fun saveMeta(detail: VideoDetail, source: VideoSource, file: File) {
        val meta = DownloadVideoMeta(
            videoCode = detail.videoCode,
            title = detail.title,
            coverUrl = detail.coverUrl,
            artistName = detail.artistName,
            genre = detail.genre,
            viewsText = detail.viewsText,
            uploadDate = detail.uploadDate,
            introduction = detail.introduction,
            tags = detail.tags,
            durationText = null,
            sourceQuality = source.quality,
            sourceUrl = source.url
        )
        file.writeText(json.encodeToString(meta))
    }

    private fun downloadCover(url: String?, file: File) {
        if (url.isNullOrBlank()) return
        runCatching {
            val request = Request.Builder()
                .url(url)
                .get()
                .header("User-Agent", USER_AGENT)
                .build()
            okHttpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return
                val body = response.body
                file.outputStream().use { output ->
                    body.byteStream().copyTo(output)
                }
            }
        }
    }

    private suspend fun updateTask(id: String, transform: DownloadTask.() -> DownloadTask) {
        updateStore {
            copy(tasks = tasks.map { if (it.id == id) it.transform() else it })
        }
    }

    private suspend fun updateStore(transform: DownloadStore.() -> DownloadStore) {
        mutex.withLock {
            val next = _store.value.transform()
            _store.value = next
            saveStore(next)
        }
    }

    private fun loadStore(): DownloadStore {
        rootDir.mkdirs()
        return runCatching {
            if (!storeFile.exists()) DownloadStore()
            else json.decodeFromString<DownloadStore>(storeFile.readText())
        }.getOrElse { DownloadStore() }
    }

    private fun saveStore(store: DownloadStore) {
        rootDir.mkdirs()
        storeFile.writeText(json.encodeToString(store))
    }

    private companion object {
        const val USER_AGENT =
            "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36"
    }
}
