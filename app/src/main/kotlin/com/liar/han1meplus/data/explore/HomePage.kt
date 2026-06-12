package com.liar.han1meplus.data.explore

import androidx.compose.runtime.Immutable

@Immutable
data class HomePage(
    val sections: List<HomeSection>
)

@Immutable
data class HomeSection(
    val title: String,
    val moreUrl: String?,
    val items: List<HomeAnimeItem>,
    val isRibun: Boolean = false
)

@Immutable
data class HomeAnimeItem(
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
