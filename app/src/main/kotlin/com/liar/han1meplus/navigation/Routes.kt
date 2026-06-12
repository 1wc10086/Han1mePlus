package com.liar.han1meplus.navigation

import kotlinx.serialization.Serializable

sealed interface Route {

    @Serializable
    data object Explore : Route

    @Serializable
    data object Following : Route

    @Serializable
    data object Cache : Route

    @Serializable
    data class Video(
        val videoCode: String,
        val local: Boolean = false,
        val startPositionMs: Long = -1L
    ) : Route

    @Serializable
    data object Settings : Route

    @Serializable
    data object About : Route

    @Serializable
    data class Search(
        val initialQuery: String = "",
        val initialGenre: String = ""
    ) : Route

    @Serializable
    data object WatchStats : Route

    @Serializable
    data object WatchStatsDetail : Route
}
