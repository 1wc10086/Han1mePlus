package com.liar.han1meplus.data.comment

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable

@Serializable
@Immutable
data class Comment(
    val id: String,
    val username: String,
    val avatarUrl: String?,
    val content: String,
    val timeAgo: String?,
    val likeCount: String?,
    val replyCount: Int?,
    val hasMoreReplies: Boolean
)

@Serializable
@Immutable
data class CommentPage(
    val comments: List<Comment>,
    val totalCount: String?
)
