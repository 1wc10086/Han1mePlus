package com.liar.han1meplus.data.search

import androidx.compose.runtime.Immutable

@Immutable
data class SearchResult(
    val items: List<SearchItem>,
    val currentPage: Int,
    val totalPages: Int
)

@Immutable
data class SearchItem(
    val videoCode: String,
    val title: String,
    val coverUrl: String,
    val duration: String?,
    val views: String?,
    val rating: String?,
    val artist: String?,
    val uploadTime: String?
)
