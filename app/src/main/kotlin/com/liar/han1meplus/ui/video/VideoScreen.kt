package com.liar.han1meplus.ui.video

import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import androidx.activity.compose.BackHandler
import androidx.activity.compose.LocalActivity
import androidx.annotation.OptIn
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.FastForward
import androidx.compose.material.icons.filled.Fullscreen
import androidx.compose.material.icons.filled.FullscreenExit
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.VideoLibrary
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularWavyProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LinearWavyProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import coil3.compose.AsyncImage
import com.liar.han1meplus.data.comment.Comment
import com.liar.han1meplus.data.following.FollowingStore
import com.liar.han1meplus.data.settings.VideoResolution
import com.liar.han1meplus.data.video.VideoDetail
import com.liar.han1meplus.data.video.VideoSimpleItem
import com.liar.han1meplus.data.video.VideoSource
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull

@Composable
fun VideoScreen(
    onBackClick: () -> Unit,
    onVideoClick: (String) -> Unit,
    viewModel: VideoViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val commentState by viewModel.commentState.collectAsStateWithLifecycle()
    val downloadDialogState by viewModel.downloadDialogState.collectAsStateWithLifecycle()
    val followDialogState by viewModel.followDialogState.collectAsStateWithLifecycle()
    val followingStore by viewModel.followingStore.collectAsStateWithLifecycle()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        when (val state = uiState) {
            VideoUiState.Loading -> LoadingContent()
            is VideoUiState.Error -> ErrorContent(
                message = state.message,
                onRetry = viewModel::retry,
                modifier = Modifier.fillMaxSize()
            )
            is VideoUiState.Success -> VideoDetailContent(
                detail = state.detail,
                preferredResolution = state.preferredResolution,
                isLocal = state.isLocal,
                startPositionMs = state.startPositionMs,
                baseUrl = state.baseUrl,
                followingStore = followingStore,
                onBackClick = onBackClick,
                onVideoClick = onVideoClick,
                commentState = commentState,
                onLoadComments = viewModel::loadComments,
                onDownloadClick = viewModel::showDownloadResolutionDialog,
                onFollowClick = viewModel::showFollowDialog,
                onSubscribeClick = viewModel::toggleSubscription,
                onUpdateProgress = viewModel::updateWatchProgress,
                onAddWatchTime = viewModel::addWatchTime,
                modifier = Modifier.fillMaxSize()
            )
        }
    }

    val state = uiState
    if (state is VideoUiState.Success) {
        if (downloadDialogState.visible) {
            ResolutionPickerDialog(
                sources = state.detail.videoSources,
                onDismiss = viewModel::dismissDownloadDialog,
                onSelect = viewModel::selectDownloadSource
            )
        }

        if (downloadDialogState.confirmVisible) {
            DownloadConfirmDialog(
                title = state.detail.title,
                quality = downloadDialogState.selectedSource?.quality ?: "",
                downloadUrl = state.detail.downloadUrl,
                onDismiss = viewModel::dismissDownloadDialog,
                onConfirm = viewModel::confirmDownload
            )
        }

        if (followDialogState.visible) {
            FollowDialog(
                state = followDialogState,
                onWatchLaterChange = viewModel::setFollowWatchLater,
                onFavoriteChange = viewModel::setFollowFavorite,
                onDismiss = viewModel::dismissFollowDialog,
                onConfirm = viewModel::applyFollowDialog
            )
        }
    }
}

@Composable
private fun ResolutionPickerDialog(
    sources: List<VideoSource>,
    onDismiss: () -> Unit,
    onSelect: (VideoSource) -> Unit
) {
    var selected by remember { mutableStateOf(sources.firstOrNull()) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("选择下载分辨率") },
        text = {
            Column {
                sources.forEach { source ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { selected = source }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = selected?.url == source.url,
                            onClick = { selected = source }
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(source.quality, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { selected?.let { onSelect(it) } },
                enabled = selected != null
            ) {
                Text("下一步")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("取消") }
        }
    )
}

@Composable
private fun DownloadConfirmDialog(
    title: String,
    quality: String,
    downloadUrl: String?,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    val context = LocalContext.current
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("确认下载") },
        text = {
            Column {
                Text(title, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.height(4.dp))
                Text(
                    "分辨率：$quality",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        confirmButton = {
            Button(onClick = onConfirm) { Text("确定") }
        },
        dismissButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TextButton(
                    onClick = {
                        downloadUrl?.let { url ->
                            context.startActivity(Intent(Intent.ACTION_VIEW, url.toUri()))
                        }
                        onDismiss()
                    },
                    enabled = !downloadUrl.isNullOrBlank()
                ) {
                    Text("跳转")
                }
                TextButton(onClick = onDismiss) { Text("取消") }
            }
        }
    )
}

@Composable
private fun FollowDialog(
    state: FollowDialogState,
    onWatchLaterChange: (Boolean) -> Unit,
    onFavoriteChange: (Boolean) -> Unit,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("加入追番") },
        text = {
            Column {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { onWatchLaterChange(!state.watchLater) }
                        .padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(checked = state.watchLater, onCheckedChange = onWatchLaterChange)
                    Spacer(Modifier.width(8.dp))
                    Text("稍后观看")
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { onFavoriteChange(!state.favorite) }
                        .padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(checked = state.favorite, onCheckedChange = onFavoriteChange)
                    Spacer(Modifier.width(8.dp))
                    Text("喜欢的影片")
                }
            }
        },
        confirmButton = { Button(onClick = onConfirm) { Text("确定") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("取消") } }
    )
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun VideoDetailContent(
    detail: VideoDetail,
    preferredResolution: VideoResolution,
    isLocal: Boolean,
    startPositionMs: Long,
    baseUrl: String,
    followingStore: FollowingStore,
    onBackClick: () -> Unit,
    onVideoClick: (String) -> Unit,
    commentState: CommentUiState,
    onLoadComments: (Int) -> Unit,
    onDownloadClick: () -> Unit,
    onFollowClick: () -> Unit,
    onSubscribeClick: () -> Unit,
    onUpdateProgress: (positionMs: Long, durationMs: Long) -> Unit,
    onAddWatchTime: (watchedMs: Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val activity = LocalActivity.current
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

    val selectedSource = remember(detail.videoSources, preferredResolution) {
        selectBestSource(detail.videoSources, preferredResolution)
    }

    val exoPlayer = remember(selectedSource?.url) {
        selectedSource?.url?.let { url ->
            ExoPlayer.Builder(context)
                .build()
                .apply {
                    setMediaItem(MediaItem.fromUri(url))
                    prepare()
                    if (startPositionMs > 0L) seekTo(startPositionMs)
                    playWhenReady = false
                    repeatMode = Player.REPEAT_MODE_OFF
                }
        }
    }

    val watchStartMs = remember { System.currentTimeMillis() }

    DisposableEffect(exoPlayer) {
        onDispose {
            exoPlayer?.let { player ->
                val posMs = player.currentPosition.coerceAtLeast(0L)
                val durMs = player.duration.takeIf { it > 0L } ?: 0L
                onUpdateProgress(posMs, durMs)
                val elapsed = System.currentTimeMillis() - watchStartMs
                if (elapsed > 2000L) onAddWatchTime(elapsed)
                player.stop()
                player.clearMediaItems()
                player.release()
            }
        }
    }

    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = remember { listOf("简介", "评论") }
    val listState = rememberLazyListState()

    val shouldCollapsePlayer by remember {
        derivedStateOf {
            listState.firstVisibleItemIndex > 0 || listState.firstVisibleItemScrollOffset > 180
        }
    }

    var forceShowPlayer by remember { mutableStateOf(false) }
    val playerCollapsed = shouldCollapsePlayer && !forceShowPlayer

    if (isLandscape) {
        LandscapeVideoPlayerPage(
            detail = detail,
            player = exoPlayer,
            onBackClick = onBackClick,
            modifier = modifier
        )
        return
    }

    Column(modifier = modifier.fillMaxSize()) {
        AnimatedVisibility(
            visible = !playerCollapsed,
            enter = expandVertically(expandFrom = Alignment.Top, animationSpec = tween(240)),
            exit = shrinkVertically(shrinkTowards = Alignment.Top, animationSpec = tween(220))
        ) {
            CustomVideoPlayer(
                player = exoPlayer,
                sources = detail.videoSources,
                coverUrl = detail.coverUrl,
                title = detail.title,
                showBackButton = true,
                isFullscreen = false,
                onBackClick = onBackClick,
                onFullscreenClick = {
                    forceShowPlayer = false
                    activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                },
                onProgressTick = { posMs, durMs -> onUpdateProgress(posMs, durMs) },
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 10f)
            )
        }

        AnimatedVisibility(
            visible = playerCollapsed,
            enter = expandVertically(expandFrom = Alignment.Top, animationSpec = tween(220)),
            exit = shrinkVertically(shrinkTowards = Alignment.Top, animationSpec = tween(180))
        ) {
            MiniPlayerBar(
                title = detail.title,
                onExpandClick = { forceShowPlayer = true },
                onBackClick = onBackClick,
                modifier = Modifier.fillMaxWidth()
            )
        }

        PrimaryTabRow(selectedTabIndex = selectedTab) {
            tabs.forEachIndexed { index, title ->
                Tab(
                    selected = selectedTab == index,
                    onClick = {
                        selectedTab = index
                        if (index == 1 && commentState is CommentUiState.Idle) {
                            onLoadComments(1)
                        }
                    },
                    text = { Text(title) }
                )
            }
        }

        AnimatedContent(
            targetState = selectedTab,
            transitionSpec = {
                fadeIn(animationSpec = tween(220, easing = FastOutSlowInEasing)) togetherWith
                    fadeOut(animationSpec = tween(180, easing = FastOutSlowInEasing)) using
                    SizeTransform(clip = false)
            },
            label = "video_tabs",
            modifier = Modifier.weight(1f)
        ) { tab ->
            when (tab) {
                0 -> VideoIntroTab(
                    detail = detail,
                    isLocal = isLocal,
                    baseUrl = baseUrl,
                    isSubscribed = followingStore.subscribedArtists.any { it.name == detail.artistName },
                    listState = listState,
                    onVideoClick = onVideoClick,
                    onDownloadClick = onDownloadClick,
                    onFollowClick = onFollowClick,
                    onSubscribeClick = onSubscribeClick,
                    modifier = Modifier.fillMaxSize()
                )
                else -> CommentTab(
                    commentState = commentState,
                    onLoadComments = onLoadComments,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }

    LaunchedEffect(shouldCollapsePlayer) {
        if (shouldCollapsePlayer) forceShowPlayer = false
    }
}

private fun selectBestSource(sources: List<VideoSource>, preferred: VideoResolution): VideoSource? {
    if (sources.isEmpty()) return null
    val exactMatch = sources.find { it.quality.filter { c -> c.isDigit() }.toIntOrNull() == preferred.p }
    return exactMatch ?: sources.maxByOrNull { it.quality.filter { c -> c.isDigit() }.toIntOrNull() ?: 0 }
}

@Composable
private fun CommentTab(
    commentState: CommentUiState,
    onLoadComments: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    when (val state = commentState) {
        CommentUiState.Idle -> {
            Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Button(onClick = { onLoadComments(1) }) { Text("加载评论") }
            }
        }
        CommentUiState.Loading -> {
            Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularWavyProgressIndicator()
            }
        }
        is CommentUiState.Error -> {
            Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("评论加载失败", fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(8.dp))
                    Text(state.message, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(12.dp))
                    Button(onClick = { onLoadComments(1) }) { Text("重试") }
                }
            }
        }
        is CommentUiState.Success -> {
            if (state.page.comments.isEmpty()) {
                Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("暂无评论", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            } else {
                LazyColumn(
                    modifier = modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(items = state.page.comments, key = { it.id }, contentType = { "comment" }) { comment ->
                        CommentItem(comment = comment)
                    }
                }
            }
        }
    }
}

@Composable
private fun CommentItem(comment: Comment, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        AsyncImage(
            model = comment.avatarUrl,
            contentDescription = comment.username,
            modifier = Modifier
                .size(38.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surfaceContainerHighest),
            contentScale = ContentScale.Crop
        )
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = comment.username,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (!comment.timeAgo.isNullOrBlank()) {
                    Text(
                        text = comment.timeAgo,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Spacer(Modifier.height(3.dp))
            Text(text = comment.content, style = MaterialTheme.typography.bodyMedium)
            if (!comment.likeCount.isNullOrBlank()) {
                Spacer(Modifier.height(3.dp))
                Text(
                    text = "👍 ${comment.likeCount}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun LandscapeVideoPlayerPage(
    detail: VideoDetail,
    player: ExoPlayer?,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val activity = LocalActivity.current

    BackHandler {
        activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    }

    DisposableEffect(activity) {
        val window = activity?.window
        val controller = window?.let { WindowCompat.getInsetsController(it, it.decorView) }
        if (window != null && controller != null) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
            controller.hide(WindowInsetsCompat.Type.systemBars())
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        onDispose {
            if (window != null && controller != null) {
                controller.show(WindowInsetsCompat.Type.systemBars())
                WindowCompat.setDecorFitsSystemWindows(window, false)
            }
            activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        CustomVideoPlayer(
            player = player,
            sources = detail.videoSources,
            coverUrl = detail.coverUrl,
            title = detail.title,
            showBackButton = true,
            isFullscreen = true,
            onBackClick = { activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED },
            onFullscreenClick = { activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED },
            onProgressTick = { _, _ -> },
            modifier = Modifier.fillMaxSize()
        )
    }
}

@OptIn(UnstableApi::class)
@Composable
private fun CustomVideoPlayer(
    player: ExoPlayer?,
    sources: List<VideoSource>,
    coverUrl: String?,
    title: String?,
    showBackButton: Boolean,
    isFullscreen: Boolean,
    onBackClick: () -> Unit,
    onFullscreenClick: () -> Unit,
    onProgressTick: (positionMs: Long, durationMs: Long) -> Unit,
    modifier: Modifier = Modifier,
    resizeMode: Int = AspectRatioFrameLayout.RESIZE_MODE_FIT
) {
    if (sources.isEmpty() || player == null) {
        EmptyVideoPlayer(
            coverUrl = coverUrl,
            title = title,
            showBackButton = showBackButton,
            onBackClick = onBackClick,
            modifier = modifier
        )
        return
    }

    var controlsVisible by remember { mutableStateOf(true) }
    var isPlaying by remember { mutableStateOf(false) }
    var isBuffering by remember { mutableStateOf(false) }
    var durationMs by remember { mutableStateOf(0L) }
    var positionMs by remember { mutableStateOf(0L) }
    var bufferedMs by remember { mutableStateOf(0L) }
    var isSeeking by remember { mutableStateOf(false) }
    var seekPreviewMs by remember { mutableStateOf(0L) }
    var isHoldingSpeed by remember { mutableStateOf(false) }

    DisposableEffect(player) {
        val listener = object : Player.Listener {
            override fun onIsPlayingChanged(playing: Boolean) {
                isPlaying = playing
                isBuffering = player.playbackState == Player.STATE_BUFFERING
            }
            override fun onPlaybackStateChanged(state: Int) {
                isBuffering = state == Player.STATE_BUFFERING
                durationMs = player.duration.takeIf { it > 0 } ?: 0L
                positionMs = player.currentPosition.coerceAtLeast(0L)
                bufferedMs = player.bufferedPosition.coerceAtLeast(0L)
            }
        }
        player.addListener(listener)
        onDispose {
            player.removeListener(listener)
            player.playbackParameters = PlaybackParameters(1f)
        }
    }

    LaunchedEffect(player) {
        while (true) {
            if (!isSeeking) {
                val dur = player.duration.takeIf { it > 0 } ?: 0L
                val pos = player.currentPosition.coerceAtLeast(0L)
                durationMs = dur
                positionMs = pos
                bufferedMs = player.bufferedPosition.coerceAtLeast(0L)
                isPlaying = player.isPlaying
                isBuffering = player.playbackState == Player.STATE_BUFFERING
                if (dur > 0L) onProgressTick(pos, dur)
            }
            delay(450)
        }
    }

    LaunchedEffect(controlsVisible, isPlaying, isSeeking, isHoldingSpeed) {
        if (controlsVisible && isPlaying && !isSeeking && !isHoldingSpeed) {
            delay(2800)
            controlsVisible = false
        }
    }

    Box(
        modifier = modifier
            .background(Color.Black)
            .pointerInput(player) {
                while (true) {
                    awaitPointerEventScope {
                        var pressed = false
                        while (!pressed) {
                            val event = awaitPointerEvent(PointerEventPass.Main)
                            pressed = event.changes.any { it.pressed }
                        }
                        val releasedBeforeLongPress = withTimeoutOrNull(380L) {
                            while (true) {
                                val event = awaitPointerEvent(PointerEventPass.Main)
                                val stillPressed = event.changes.any { it.pressed }
                                if (!stillPressed) return@withTimeoutOrNull true
                            }
                            false
                        } ?: false

                        if (releasedBeforeLongPress) {
                            controlsVisible = !controlsVisible
                        } else {
                            isHoldingSpeed = true
                            controlsVisible = true
                            player.playbackParameters = PlaybackParameters(2f)
                            while (true) {
                                val event = awaitPointerEvent(PointerEventPass.Main)
                                if (!event.changes.any { it.pressed }) break
                            }
                            isHoldingSpeed = false
                            player.playbackParameters = PlaybackParameters(1f)
                        }
                    }
                }
            }
    ) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { ctx ->
                PlayerView(ctx).apply {
                    this.player = player
                    useController = false
                    this.resizeMode = resizeMode
                    keepScreenOn = true
                    setShutterBackgroundColor(android.graphics.Color.BLACK)
                }
            },
            update = { view ->
                if (view.player !== player) view.player = player
                view.useController = false
                view.resizeMode = resizeMode
            }
        )

        if (isBuffering) {
            Box(
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(58.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.45f)),
                contentAlignment = Alignment.Center
            ) {
                CircularWavyProgressIndicator(modifier = Modifier.size(30.dp), color = Color.White)
            }
        }

        if (isHoldingSpeed) {
            SpeedHoldBadge(modifier = Modifier.align(Alignment.Center))
        }

        AnimatedVisibility(visible = controlsVisible, modifier = Modifier.matchParentSize()) {
            PlayerControlsOverlay(
                title = title,
                isPlaying = isPlaying,
                isFullscreen = isFullscreen,
                showBackButton = showBackButton,
                durationMs = durationMs,
                positionMs = if (isSeeking) seekPreviewMs else positionMs,
                bufferedMs = bufferedMs,
                onBackClick = onBackClick,
                onPlayPauseClick = {
                    if (player.isPlaying) player.pause() else player.play()
                    controlsVisible = true
                },
                onFullscreenClick = onFullscreenClick,
                onSeekStart = {
                    isSeeking = true
                    seekPreviewMs = positionMs
                    controlsVisible = true
                },
                onSeekChange = { seekPreviewMs = it },
                onSeekEnd = {
                    player.seekTo(seekPreviewMs)
                    positionMs = seekPreviewMs
                    isSeeking = false
                    controlsVisible = true
                }
            )
        }
    }
}

@Composable
private fun PlayerControlsOverlay(
    title: String?,
    isPlaying: Boolean,
    isFullscreen: Boolean,
    showBackButton: Boolean,
    durationMs: Long,
    positionMs: Long,
    bufferedMs: Long,
    onBackClick: () -> Unit,
    onPlayPauseClick: () -> Unit,
    onFullscreenClick: () -> Unit,
    onSeekStart: () -> Unit,
    onSeekChange: (Long) -> Unit,
    onSeekEnd: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.12f))
    ) {
        PlayerTopBar(
            title = title,
            showBackButton = showBackButton,
            onBackClick = onBackClick,
            modifier = Modifier.align(Alignment.TopCenter)
        )
        PlayerBottomBar(
            isPlaying = isPlaying,
            isFullscreen = isFullscreen,
            durationMs = durationMs,
            positionMs = positionMs,
            bufferedMs = bufferedMs,
            onPlayPauseClick = onPlayPauseClick,
            onFullscreenClick = onFullscreenClick,
            onSeekStart = onSeekStart,
            onSeekChange = onSeekChange,
            onSeekEnd = onSeekEnd,
            modifier = Modifier.align(Alignment.BottomCenter)
        )
    }
}

@Composable
private fun PlayerTopBar(
    title: String?,
    showBackButton: Boolean,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color.Black.copy(alpha = 0.75f),
                        Color.Black.copy(alpha = 0.35f),
                        Color.Transparent
                    )
                )
            )
            .statusBarsPadding()
            .padding(horizontal = 10.dp, vertical = 8.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            if (showBackButton) {
                FilledIconButton(
                    onClick = onBackClick,
                    modifier = Modifier.size(42.dp),
                    colors = IconButtonDefaults.filledIconButtonColors(
                        containerColor = Color.Black.copy(alpha = 0.35f),
                        contentColor = Color.White
                    )
                ) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                }
                Spacer(Modifier.width(10.dp))
            }
            Text(
                text = title.orEmpty(),
                modifier = Modifier.weight(1f),
                color = Color.White,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun PlayerBottomBar(
    isPlaying: Boolean,
    isFullscreen: Boolean,
    durationMs: Long,
    positionMs: Long,
    bufferedMs: Long,
    onPlayPauseClick: () -> Unit,
    onFullscreenClick: () -> Unit,
    onSeekStart: () -> Unit,
    onSeekChange: (Long) -> Unit,
    onSeekEnd: () -> Unit,
    modifier: Modifier = Modifier
) {
    val safeDuration = durationMs.coerceAtLeast(1L)
    val safePosition = positionMs.coerceIn(0L, safeDuration)
    val safeBuffered = bufferedMs.coerceIn(0L, safeDuration)
    var sliderDragging by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color.Black.copy(alpha = 0.42f),
                        Color.Black.copy(alpha = 0.86f)
                    )
                )
            )
            .padding(horizontal = 12.dp)
            .navigationBarsPadding()
            .padding(bottom = 8.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(28.dp),
            contentAlignment = Alignment.Center
        ) {
            LinearWavyProgressIndicator(
                progress = { safeBuffered.toFloat() / safeDuration.toFloat() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(3.dp)
                    .clip(RoundedCornerShape(999.dp)),
                color = Color.White.copy(alpha = 0.34f),
                trackColor = Color.White.copy(alpha = 0.16f)
            )
            Slider(
                value = safePosition.toFloat(),
                onValueChange = { value ->
                    if (!sliderDragging) {
                        sliderDragging = true
                        onSeekStart()
                    }
                    onSeekChange(value.toLong())
                },
                onValueChangeFinished = {
                    sliderDragging = false
                    onSeekEnd()
                },
                valueRange = 0f..safeDuration.toFloat(),
                modifier = Modifier.fillMaxWidth()
            )
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(42.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilledIconButton(
                onClick = onPlayPauseClick,
                modifier = Modifier.size(38.dp),
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color.White,
                    contentColor = Color.Black
                )
            ) {
                Icon(
                    imageVector = if (isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                    contentDescription = if (isPlaying) "暂停" else "播放",
                    modifier = Modifier.size(22.dp)
                )
            }
            Spacer(Modifier.width(10.dp))
            Text(
                text = "${formatPlayerTime(safePosition)} / ${formatPlayerTime(durationMs)}",
                color = Color.White,
                style = MaterialTheme.typography.labelMedium,
                maxLines = 1
            )
            Spacer(Modifier.weight(1f))
            FilledIconButton(
                onClick = onFullscreenClick,
                modifier = Modifier.size(38.dp),
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color.White.copy(alpha = 0.14f),
                    contentColor = Color.White
                )
            ) {
                Icon(
                    imageVector = if (isFullscreen) Icons.Filled.FullscreenExit else Icons.Filled.Fullscreen,
                    contentDescription = if (isFullscreen) "退出全屏" else "全屏"
                )
            }
        }
    }
}

@Composable
private fun SpeedHoldBadge(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(999.dp))
            .background(Color.Black.copy(alpha = 0.58f))
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = Icons.Filled.FastForward,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.size(20.dp)
        )
        Text(
            text = "2.0x",
            color = Color.White,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun EmptyVideoPlayer(
    coverUrl: String?,
    title: String?,
    showBackButton: Boolean,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.background(Color.Black), contentAlignment = Alignment.Center) {
        AsyncImage(
            model = coverUrl,
            contentDescription = title,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )
        Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.58f)))
        PlayerTopBar(
            title = title,
            showBackButton = showBackButton,
            onBackClick = onBackClick,
            modifier = Modifier.align(Alignment.TopCenter)
        )
        Text(
            text = "暂无播放源",
            color = Color.White,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier
                .clip(RoundedCornerShape(999.dp))
                .background(Color.Black.copy(alpha = 0.45f))
                .padding(horizontal = 18.dp, vertical = 10.dp)
        )
    }
}

@Composable
private fun MiniPlayerBar(
    title: String,
    onExpandClick: () -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .background(MaterialTheme.colorScheme.surface)
            .statusBarsPadding()
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        FilledIconButton(
            onClick = onBackClick,
            modifier = Modifier.size(40.dp),
            colors = IconButtonDefaults.filledIconButtonColors(
                containerColor = MaterialTheme.colorScheme.surfaceContainerHighest,
                contentColor = MaterialTheme.colorScheme.onSurface
            )
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
        }
        Spacer(Modifier.width(10.dp))
        Text(
            text = title,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        FilledIconButton(onClick = onExpandClick, modifier = Modifier.size(40.dp)) {
            Icon(Icons.Filled.PlayArrow, contentDescription = "展开播放器")
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun VideoIntroTab(
    detail: VideoDetail,
    isLocal: Boolean,
    baseUrl: String,
    isSubscribed: Boolean,
    listState: LazyListState,
    onVideoClick: (String) -> Unit,
    onDownloadClick: () -> Unit,
    onFollowClick: () -> Unit,
    onSubscribeClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var introExpanded by remember { mutableStateOf(false) }

    LazyColumn(
        state = listState,
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item(key = "artist", contentType = "artist") {
            ArtistRow(detail = detail, isSubscribed = isSubscribed, onSubscribeClick = onSubscribeClick)
        }

        item(key = "title_intro", contentType = "title_intro") {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(MaterialTheme.colorScheme.surfaceContainerLow)
                    .clickable { introExpanded = !introExpanded }
                    .padding(14.dp)
                    .animateContentSize(animationSpec = tween(220))
            ) {
                Row(verticalAlignment = Alignment.Top) {
                    Text(
                        text = detail.title,
                        modifier = Modifier.weight(1f),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Icon(
                        imageVector = if (introExpanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                        contentDescription = null
                    )
                }
                Spacer(Modifier.height(6.dp))
                Text(
                    text = buildString {
                        if (!detail.viewsText.isNullOrBlank()) append(detail.viewsText)
                        if (!detail.uploadDate.isNullOrBlank()) {
                            if (isNotEmpty()) append("  ")
                            append(detail.uploadDate)
                        }
                    }.ifBlank { "暂无信息" },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                if (introExpanded) {
                    if (!detail.introduction.isNullOrBlank()) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            text = detail.introduction,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    if (detail.tags.isNotEmpty()) {
                        Spacer(Modifier.height(12.dp))
                        FlowRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            detail.tags.forEach { tag ->
                                AssistChip(
                                    onClick = {},
                                    label = { Text(text = tag, maxLines = 1, overflow = TextOverflow.Ellipsis) }
                                )
                            }
                        }
                    }
                }
            }
        }

        item(key = "actions", contentType = "actions") {
            ActionRow(
                detail = detail,
                isLocal = isLocal,
                baseUrl = baseUrl,
                onDownloadClick = onDownloadClick,
                onFollowClick = onFollowClick
            )
        }

        if (detail.playlist.isNotEmpty()) {
            item(key = "playlist_title", contentType = "section_title") {
                SectionTitle("系列影片")
            }
            item(key = "playlist_row", contentType = "playlist_row") {
                LazyRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    contentPadding = PaddingValues(end = 8.dp)
                ) {
                    items(
                        items = detail.playlist,
                        key = { "pl_${it.videoCode}" },
                        contentType = { "playlist_video" }
                    ) { item ->
                        PlaylistVideoCard(item = item, onClick = { onVideoClick(item.videoCode) })
                    }
                }
            }
        }

        if (detail.relatedVideos.isNotEmpty()) {
            item(key = "related_title", contentType = "section_title") {
                SectionTitle("相关影片")
            }
            items(
                items = detail.relatedVideos,
                key = { "rel_${it.videoCode}" },
                contentType = { "related_video" }
            ) { item ->
                VideoListItem(item = item, onClick = { onVideoClick(item.videoCode) })
            }
        }
    }
}

@Composable
private fun ArtistRow(
    detail: VideoDetail,
    isSubscribed: Boolean,
    onSubscribeClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        AsyncImage(
            model = detail.artistAvatarUrl,
            contentDescription = detail.artistName,
            modifier = Modifier
                .size(46.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surfaceContainerHighest),
            contentScale = ContentScale.Crop
        )
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = detail.artistName ?: "未知作者",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            if (!detail.genre.isNullOrBlank()) {
                Text(
                    text = detail.genre,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        TextButton(onClick = onSubscribeClick, enabled = !detail.artistName.isNullOrBlank()) {
            Text(if (isSubscribed) "已订阅" else "订阅")
        }
    }
}

@Composable
private fun ActionRow(
    detail: VideoDetail,
    isLocal: Boolean,
    baseUrl: String,
    onDownloadClick: () -> Unit,
    onFollowClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val shareUrl = remember(baseUrl, detail.videoCode) {
        "${baseUrl.trimEnd('/')}/watch?v=${detail.videoCode}"
    }

    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Button(onClick = {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, shareUrl)
                putExtra(Intent.EXTRA_TITLE, detail.title)
            }
            context.startActivity(Intent.createChooser(intent, "分享影片"))
        }) {
            Icon(Icons.Filled.Share, contentDescription = null)
            Spacer(Modifier.width(6.dp))
            Text("分享")
        }

        Button(onClick = onFollowClick) {
            Icon(Icons.Filled.VideoLibrary, contentDescription = null)
            Spacer(Modifier.width(6.dp))
            Text("追番")
        }

        if (!isLocal) {
            Button(onClick = onDownloadClick, enabled = detail.videoSources.isNotEmpty()) {
                Icon(Icons.Filled.Download, contentDescription = null)
                Spacer(Modifier.width(6.dp))
                Text("下载")
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        modifier = modifier.padding(top = 4.dp),
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold
    )
}

@Composable
private fun PlaylistVideoCard(
    item: VideoSimpleItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .width(190.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(
                if (item.isPlaying) MaterialTheme.colorScheme.primaryContainer
                else MaterialTheme.colorScheme.surfaceContainerLow
            )
            .clickable(onClick = onClick)
            .padding(8.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .clip(RoundedCornerShape(10.dp))
                .background(Color.Black)
        ) {
            AsyncImage(
                model = item.coverUrl,
                contentDescription = item.title,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            if (!item.duration.isNullOrBlank()) {
                Text(
                    text = item.duration,
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(5.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(Color.Black.copy(alpha = 0.75f))
                        .padding(horizontal = 5.dp, vertical = 2.dp),
                    color = Color.White,
                    style = MaterialTheme.typography.labelSmall
                )
            }
            if (item.isPlaying) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.52f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Filled.VideoLibrary, contentDescription = null, tint = Color.White)
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        Text(
            text = item.title,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.SemiBold,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
        if (!item.artist.isNullOrBlank()) {
            Spacer(Modifier.height(3.dp))
            Text(
                text = item.artist,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun VideoListItem(
    item: VideoSimpleItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(
                if (item.isPlaying) MaterialTheme.colorScheme.primaryContainer
                else MaterialTheme.colorScheme.surfaceContainerLow
            )
            .clickable(onClick = onClick)
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(136.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(Color.Black)
        ) {
            AsyncImage(
                model = item.coverUrl,
                contentDescription = item.title,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f),
                contentScale = ContentScale.Crop
            )
            if (!item.duration.isNullOrBlank()) {
                Text(
                    text = item.duration,
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(4.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(Color.Black.copy(alpha = 0.75f))
                        .padding(horizontal = 5.dp, vertical = 2.dp),
                    color = Color.White,
                    style = MaterialTheme.typography.labelSmall
                )
            }
            if (item.isPlaying) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.5f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Filled.VideoLibrary, contentDescription = null, tint = Color.White)
                }
            }
        }
        Spacer(Modifier.width(10.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            if (!item.artist.isNullOrBlank()) {
                Spacer(Modifier.height(3.dp))
                Text(
                    text = item.artist,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            val meta = remember(item.views, item.rating) {
                buildString {
                    if (!item.views.isNullOrBlank()) append(item.views)
                    if (!item.rating.isNullOrBlank()) {
                        if (isNotEmpty()) append(" · ")
                        append(item.rating)
                    }
                }
            }
            if (meta.isNotBlank()) {
                Spacer(Modifier.height(2.dp))
                Text(
                    text = meta,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun LoadingContent(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .safeDrawingPadding(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularWavyProgressIndicator()
            Spacer(Modifier.height(12.dp))
            Text("正在解析影片…", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun ErrorContent(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .safeDrawingPadding()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("加载失败", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text(message, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(12.dp))
        Button(onClick = onRetry) { Text("重试") }
    }
}

private fun formatPlayerTime(timeMs: Long): String {
    if (timeMs <= 0L) return "00:00"
    val totalSeconds = timeMs / 1000
    val seconds = totalSeconds % 60
    val minutes = totalSeconds / 60 % 60
    val hours = totalSeconds / 3600
    return if (hours > 0) "%d:%02d:%02d".format(hours, minutes, seconds)
    else "%02d:%02d".format(minutes, seconds)
}
