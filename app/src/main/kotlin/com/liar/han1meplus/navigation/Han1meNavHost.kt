package com.liar.han1meplus.navigation

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.liar.han1meplus.ui.cache.CacheScreen
import com.liar.han1meplus.ui.explore.ExploreScreen
import com.liar.han1meplus.ui.following.FollowingScreen
import com.liar.han1meplus.ui.search.SearchScreen
import com.liar.han1meplus.ui.settings.AboutScreen
import com.liar.han1meplus.ui.settings.SettingsScreen
import com.liar.han1meplus.ui.stats.WatchStatsDetailScreen
import com.liar.han1meplus.ui.stats.WatchStatsScreen
import com.liar.han1meplus.ui.video.VideoScreen

private const val FADE_DURATION_MS = 300
private const val SLIDE_DURATION_MS = 320

private val fadeEnter = fadeIn(tween(FADE_DURATION_MS, easing = FastOutSlowInEasing))
private val fadeExit = fadeOut(tween(FADE_DURATION_MS, easing = FastOutSlowInEasing))

private val slideInFromRight = slideInHorizontally(
    initialOffsetX = { it },
    animationSpec = tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing)
) + fadeIn(tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing))

private val slideOutToRight = slideOutHorizontally(
    targetOffsetX = { it },
    animationSpec = tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing)
) + fadeOut(tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing))

private val slideOutToLeft = slideOutHorizontally(
    targetOffsetX = { -it / 4 },
    animationSpec = tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing)
) + fadeOut(tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing))

private val slideInFromLeft = slideInHorizontally(
    initialOffsetX = { -it / 4 },
    animationSpec = tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing)
) + fadeIn(tween(SLIDE_DURATION_MS, easing = FastOutSlowInEasing))

@Composable
fun Han1meNavHost(
    navController: NavHostController,
    scaffoldPadding: PaddingValues,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController = navController,
        startDestination = Route.Explore,
        modifier = modifier,
        enterTransition = { fadeEnter },
        exitTransition = { fadeExit },
        popEnterTransition = { fadeEnter },
        popExitTransition = { fadeExit }
    ) {
        composable<Route.Explore> {
            ExploreScreen(
                scaffoldPadding = scaffoldPadding,
                onVideoClick = { navController.navigate(Route.Video(it)) },
                onSearchClick = { navController.navigate(Route.Search()) },
                onSettingsClick = { navController.navigate(Route.Settings) }
            )
        }

        composable<Route.Following> {
    FollowingScreen(
        scaffoldPadding = scaffoldPadding,
        onStatsClick = { navController.navigate(Route.WatchStats) },
        onVideoClick = { navController.navigate(Route.Video(it)) }
    )
}

        composable<Route.Cache> {
            CacheScreen(
                scaffoldPadding = scaffoldPadding,
                onVideoClick = { videoCode, positionMs ->
                    navController.navigate(
                        Route.Video(
                            videoCode = videoCode,
                            local = true,
                            startPositionMs = positionMs
                        )
                    )
                }
            )
        }

        composable<Route.Video>(
            enterTransition = { slideInFromRight },
            exitTransition = { fadeExit },
            popEnterTransition = { fadeEnter },
            popExitTransition = { slideOutToRight }
        ) {
            VideoScreen(
                onBackClick = navController::popBackStack,
                onVideoClick = { navController.navigate(Route.Video(it)) { launchSingleTop = true } }
            )
        }

        composable<Route.Settings>(
            enterTransition = { slideInFromRight },
            exitTransition = { slideOutToLeft },
            popEnterTransition = { slideInFromLeft },
            popExitTransition = { slideOutToRight }
        ) {
            SettingsScreen(
                onBackClick = navController::popBackStack,
                onAboutClick = { navController.navigate(Route.About) }
            )
        }

        composable<Route.About>(
            enterTransition = { slideInFromRight },
            exitTransition = { slideOutToLeft },
            popEnterTransition = { slideInFromLeft },
            popExitTransition = { slideOutToRight }
        ) {
            AboutScreen(onBackClick = navController::popBackStack)
        }

        composable<Route.Search>(
            enterTransition = { slideInFromRight },
            exitTransition = { slideOutToLeft },
            popEnterTransition = { slideInFromLeft },
            popExitTransition = { slideOutToRight }
        ) {
            SearchScreen(
                onBackClick = navController::popBackStack,
                onVideoClick = { navController.navigate(Route.Video(it)) }
            )
        }

        composable<Route.WatchStats>(
            enterTransition = { slideInFromRight },
            exitTransition = { slideOutToLeft },
            popEnterTransition = { slideInFromLeft },
            popExitTransition = { slideOutToRight }
        ) {
            WatchStatsScreen(
                onBackClick = navController::popBackStack,
                onDetailClick = { navController.navigate(Route.WatchStatsDetail) }
            )
        }

        composable<Route.WatchStatsDetail>(
            enterTransition = { slideInFromRight },
            exitTransition = { slideOutToLeft },
            popEnterTransition = { slideInFromLeft },
            popExitTransition = { slideOutToRight }
        ) {
            WatchStatsDetailScreen(onBackClick = navController::popBackStack)
        }
    }
}
