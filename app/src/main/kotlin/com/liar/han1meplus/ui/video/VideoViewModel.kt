package com.liar.han1meplus.ui.video

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.navigation.toRoute
import com.liar.han1meplus.data.comment.CommentPage
import com.liar.han1meplus.data.comment.CommentRepository
import com.liar.han1meplus.data.download.DownloadRepository
import com.liar.han1meplus.data.following.FollowingRepository
import com.liar.han1meplus.data.following.FollowingStore
import com.liar.han1meplus.data.settings.AppSettings
import com.liar.han1meplus.data.settings.VideoResolution
import com.liar.han1meplus.data.video.VideoDetail
import com.liar.han1meplus.data.video.VideoRepository
import com.liar.han1meplus.data.video.VideoSource
import com.liar.han1meplus.data.watch.WatchProgressRepository
import com.liar.han1meplus.navigation.Route
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface VideoUiState {
    data object Loading : VideoUiState
    data class Success(
        val detail: VideoDetail,
        val preferredResolution: VideoResolution,
        val isLocal: Boolean,
        val startPositionMs: Long,
        val baseUrl: String
    ) : VideoUiState
    data class Error(val message: String) : VideoUiState
}

sealed interface CommentUiState {
    data object Idle : CommentUiState
    data object Loading : CommentUiState
    data class Success(val page: CommentPage, val currentPage: Int) : CommentUiState
    data class Error(val message: String) : CommentUiState
}

data class DownloadDialogState(
    val visible: Boolean = false,
    val confirmVisible: Boolean = false,
    val selectedSource: VideoSource? = null
)

data class FollowDialogState(
    val visible: Boolean = false,
    val watchLater: Boolean = false,
    val favorite: Boolean = false
)

@HiltViewModel
class VideoViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: VideoRepository,
    private val commentRepository: CommentRepository,
    private val downloadRepository: DownloadRepository,
    private val followingRepository: FollowingRepository,
    private val watchProgressRepository: WatchProgressRepository,
    private val appSettings: AppSettings
) : ViewModel() {

    private val route = savedStateHandle.toRoute<Route.Video>()
    private val videoCode = route.videoCode

    private val _uiState = MutableStateFlow<VideoUiState>(VideoUiState.Loading)
    val uiState: StateFlow<VideoUiState> = _uiState.asStateFlow()

    private val _commentState = MutableStateFlow<CommentUiState>(CommentUiState.Idle)
    val commentState: StateFlow<CommentUiState> = _commentState.asStateFlow()

    private val _downloadDialogState = MutableStateFlow(DownloadDialogState())
    val downloadDialogState: StateFlow<DownloadDialogState> = _downloadDialogState.asStateFlow()

    private val _followDialogState = MutableStateFlow(FollowDialogState())
    val followDialogState: StateFlow<FollowDialogState> = _followDialogState.asStateFlow()

    val followingStore: StateFlow<FollowingStore> = followingRepository.store.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = FollowingStore()
    )

    private var loadJob: Job? = null
    private var commentJob: Job? = null

    init {
        load()
    }

    fun retry() = load()

    private fun load() {
        loadJob?.cancel()
        loadJob = viewModelScope.launch {
            _uiState.value = VideoUiState.Loading
            val settings = appSettings.settings.first()
            val progress = watchProgressRepository.getProgress(videoCode)
            val startPosition = when {
                route.startPositionMs >= 0L -> route.startPositionMs
                progress != null -> progress.positionMs
                else -> 0L
            }

            val flow = if (route.local) {
                repository.getLocalVideoDetail(videoCode)
            } else {
                repository.getVideoDetail(settings.baseUrl, videoCode)
            }

            flow.catch {
                _uiState.value = VideoUiState.Error(it.message ?: "未知错误")
            }.collect {
                followingRepository.addSubscriptionVideoIfSubscribed(it)
                _uiState.value = VideoUiState.Success(
                    detail = it,
                    preferredResolution = settings.videoResolution,
                    isLocal = route.local,
                    startPositionMs = startPosition,
                    baseUrl = settings.baseUrl
                )
            }
        }
    }

    fun loadComments(page: Int = 1) {
        commentJob?.cancel()
        commentJob = viewModelScope.launch {
            _commentState.value = CommentUiState.Loading
            val baseUrl = appSettings.settings.first().baseUrl
            commentRepository.getComments(baseUrl, videoCode, page)
                .catch { _commentState.value = CommentUiState.Error(it.message ?: "未知错误") }
                .collect { _commentState.value = CommentUiState.Success(it, page) }
        }
    }

    fun showDownloadResolutionDialog() {
        _downloadDialogState.value = DownloadDialogState(visible = true)
    }

    fun selectDownloadSource(source: VideoSource) {
        _downloadDialogState.value = DownloadDialogState(
            visible = false,
            confirmVisible = true,
            selectedSource = source
        )
    }

    fun dismissDownloadDialog() {
        _downloadDialogState.value = DownloadDialogState()
    }

    fun confirmDownload() {
        val source = _downloadDialogState.value.selectedSource ?: return
        val state = _uiState.value as? VideoUiState.Success ?: return
        viewModelScope.launch {
            downloadRepository.createDownloadTask(
                detail = state.detail,
                source = source,
                groupId = "default"
            )
            dismissDownloadDialog()
        }
    }

    fun showFollowDialog() {
        val detail = (_uiState.value as? VideoUiState.Success)?.detail ?: return
        _followDialogState.value = FollowDialogState(
            visible = true,
            watchLater = followingRepository.isWatchLater(detail.videoCode),
            favorite = followingRepository.isFavorite(detail.videoCode)
        )
    }

    fun dismissFollowDialog() {
        _followDialogState.value = FollowDialogState()
    }

    fun setFollowWatchLater(value: Boolean) {
        _followDialogState.value = _followDialogState.value.copy(watchLater = value)
    }

    fun setFollowFavorite(value: Boolean) {
        _followDialogState.value = _followDialogState.value.copy(favorite = value)
    }

    fun applyFollowDialog() {
        val detail = (_uiState.value as? VideoUiState.Success)?.detail ?: return
        val dialog = _followDialogState.value
        viewModelScope.launch {
            followingRepository.setWatchLater(detail, dialog.watchLater)
            followingRepository.setFavorite(detail, dialog.favorite)
            dismissFollowDialog()
        }
    }

    fun toggleSubscription() {
        val detail = (_uiState.value as? VideoUiState.Success)?.detail ?: return
        viewModelScope.launch {
            followingRepository.setSubscription(
                detail = detail,
                enabled = !followingRepository.isSubscribed(detail.artistName)
            )
        }
    }

    fun updateWatchProgress(positionMs: Long, durationMs: Long) {
        val state = _uiState.value as? VideoUiState.Success ?: return
        viewModelScope.launch {
            watchProgressRepository.updateProgress(
                videoCode = state.detail.videoCode,
                title = state.detail.title,
                coverUrl = state.detail.coverUrl,
                positionMs = positionMs,
                durationMs = durationMs
            )
        }
    }

    fun addWatchTime(watchedMs: Long) {
        val state = _uiState.value as? VideoUiState.Success ?: return
        viewModelScope.launch {
            watchProgressRepository.addWatchTime(
                videoCode = state.detail.videoCode,
                title = state.detail.title,
                watchedMs = watchedMs
            )
        }
    }
}
