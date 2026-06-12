package com.liar.han1meplus

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarDefaults
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavDestination
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.liar.han1meplus.data.update.UpdateInfo
import com.liar.han1meplus.navigation.Han1meNavHost
import com.liar.han1meplus.navigation.Route
import com.liar.han1meplus.navigation.TopLevelDestination
import com.liar.han1meplus.ui.theme.Han1mePlusTheme
import com.liar.han1meplus.ui.update.UpdateDialog

@Composable
fun Han1meApp(
    updateInfo: UpdateInfo? = null,
    onUpdateDialogDismiss: () -> Unit = {},
    viewModel: Han1meAppViewModel = hiltViewModel()
) {
    val settings by viewModel.settings.collectAsStateWithLifecycle()

    Han1mePlusTheme(
        darkThemeConfig = settings.darkTheme,
        colorSchemeConfig = settings.colorScheme
    ) {
        Han1meAppContent()

        if (updateInfo != null) {
            UpdateDialog(
                info = updateInfo,
                onDismiss = onUpdateDialogDismiss
            )
        }
    }
}

@Composable
private fun Han1meAppContent() {
    val appState = rememberHan1meAppState()
    val currentBackStackEntry by appState.navController.currentBackStackEntryAsState()
    val currentDestination = currentBackStackEntry?.destination
    val showBottomBar = appState.shouldShowBottomBar(currentDestination)
    val bottomPadding = if (showBottomBar) PaddingValues(bottom = 88.dp) else PaddingValues(0.dp)

    Box(modifier = Modifier.fillMaxSize()) {
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            contentWindowInsets = WindowInsets(0),
            bottomBar = {}
        ) {
            Han1meNavHost(
                navController = appState.navController,
                scaffoldPadding = bottomPadding,
                modifier = Modifier.fillMaxSize()
            )
        }

        AnimatedVisibility(
            modifier = Modifier.align(Alignment.BottomCenter),
            visible = showBottomBar,
            enter = slideInVertically(
                initialOffsetY = { it },
                animationSpec = tween(420, easing = FastOutSlowInEasing)
            ),
            exit = slideOutVertically(
                targetOffsetY = { it },
                animationSpec = tween(380, easing = FastOutSlowInEasing)
            )
        ) {
            Han1meBottomBar(
                currentDestination = currentDestination,
                onDestinationClick = appState::navigateToTopLevelDestination
            )
        }
    }
}

@Composable
private fun rememberHan1meAppState(
    navController: NavHostController = rememberNavController()
): Han1meAppState {
    return remember(navController) {
        Han1meAppState(navController)
    }
}

@Stable
private class Han1meAppState(
    val navController: NavHostController
) {
    fun navigateToTopLevelDestination(destination: TopLevelDestination) {
        navController.navigate(destination.route) {
            popUpTo(navController.graph.findStartDestination().id) {
                saveState = true
            }

            launchSingleTop = true
            restoreState = true
        }
    }

    fun shouldShowBottomBar(destination: NavDestination?): Boolean {
        return destination.isTopLevelDestination()
    }
}

@Composable
private fun Han1meBottomBar(
    currentDestination: NavDestination?,
    onDestinationClick: (TopLevelDestination) -> Unit
) {
    NavigationBar(
        windowInsets = NavigationBarDefaults.windowInsets
    ) {
        TopLevelDestination.entries.forEach { destination ->
            val selected = destination.isActive(currentDestination)

            NavigationBarItem(
                selected = selected,
                onClick = {
                    onDestinationClick(destination)
                },
                icon = {
                    Icon(
                        imageVector = if (selected) {
                            destination.selectedIcon
                        } else {
                            destination.unselectedIcon
                        },
                        contentDescription = destination.label
                    )
                },
                label = {
                    Text(destination.label)
                }
            )
        }
    }
}

private fun NavDestination?.isTopLevelDestination(): Boolean {
    if (this == null) return false

    return hasRoute<Route.Explore>() ||
        hasRoute<Route.Following>() ||
        hasRoute<Route.Cache>()
}
