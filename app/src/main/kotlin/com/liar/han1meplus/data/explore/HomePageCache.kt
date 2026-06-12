package com.liar.han1meplus.data.explore

import kotlinx.serialization.Serializable

@Serializable
data class HomePageCache(
    val sections: List<HomeSectionCache>,
    val cachedAtMs: Long
)

@Serializable
data class HomeSectionCache(
    val title: String,
    val moreUrl: String?,
    val items: List<HomeAnimeItemCache>,
    val isRibun: Boolean
)

@Serializable
data class HomeAnimeItemCache(
    val videoCode: String,
    val title: String,
    val coverUrl: String,
    val detailUrl: String,
    val duration: String?,
    val views: String?,
    val rating: String?,
    val artist: String?,
    val uploadTime: String?
)
