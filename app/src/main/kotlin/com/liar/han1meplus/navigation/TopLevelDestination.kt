package com.liar.han1meplus.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavDestination.Companion.hierarchy
import kotlin.reflect.KClass

enum class TopLevelDestination(
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    /** 用于 navController.navigate(destination.route)，运行时类型正确 */
    val route: Any,
    /** 用于 NavDestination.hasRoute() 匹配当前页面 */
    val routeClass: KClass<out Route>
) {
    EXPLORE(
        label        = "探索",
        selectedIcon = Icons.Filled.Explore,
        unselectedIcon = Icons.Outlined.Explore,
        route        = Route.Explore,
        routeClass   = Route.Explore::class
    ),
    FOLLOWING(
        label        = "追番",
        selectedIcon = Icons.Filled.PlayCircle,
        unselectedIcon = Icons.Outlined.PlayCircle,
        route        = Route.Following,
        routeClass   = Route.Following::class
    ),
    CACHE(
        label        = "缓存",
        selectedIcon = Icons.Filled.Download,
        unselectedIcon = Icons.Outlined.Download,
        route        = Route.Cache,
        routeClass   = Route.Cache::class
    );

    /**
     * 判断给定 NavDestination 是否属于本条目的层级。
     * 使用 @Suppress 是因为 KClass<out Route> → KClass<Any> 在运行时安全：
     * Navigation 内部通过 route::class 取运行时类型，类型参数仅影响编译期检查。
     */
    @Suppress("UNCHECKED_CAST")
    fun isActive(destination: NavDestination?): Boolean =
        destination?.hierarchy?.any { it.hasRoute(routeClass as KClass<Any>) } == true
}