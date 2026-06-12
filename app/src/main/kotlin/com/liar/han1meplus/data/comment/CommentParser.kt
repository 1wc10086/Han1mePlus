package com.liar.han1meplus.data.comment

import org.json.JSONObject
import org.jsoup.Jsoup
import org.jsoup.nodes.Element

object CommentParser {

    fun parse(body: String, baseUrl: String): CommentPage {
        val html = runCatching {
            JSONObject(body).optString("comments")
        }.getOrNull()?.ifBlank { body } ?: body

        val parseBody = Jsoup.parse(html, baseUrl).body()
        val allCommentsClass = parseBody.getElementById("comment-start")

        val comments = buildList {
            allCommentsClass?.children()?.chunked(4)?.forEach { elements ->
                add(Element("div").apply { appendChildren(elements) })
            }
        }.mapNotNull { child ->
            parseComment(child)
        }

        return CommentPage(
            comments = comments,
            totalCount = null
        )
    }

    private fun parseComment(child: Element): Comment? {
        val avatarUrl = child.selectFirst("img")
            ?.absUrl("src")
            ?.ifBlank { null }

        val textClass = child.getElementsByClass("comment-index-text")
        val nameAndDateClass = textClass.firstOrNull()

        val username = nameAndDateClass
            ?.selectFirst("a")
            ?.ownText()
            ?.trim()
            ?.ifBlank { null }
            ?: return null

        val date = nameAndDateClass
            .selectFirst("span")
            ?.ownText()
            ?.trim()
            ?.ifBlank { null }

        val content = textClass.getOrNull(1)
            ?.text()
            ?.trim()
            ?.ifBlank { null }
            ?: return null

        val hasMoreReplies = child.selectFirst("div[class^=load-replies-btn]") != null

        val likeCount = child.getElementById("comment-like-form-wrapper")
            ?.select("span[style]")
            ?.getOrNull(1)
            ?.text()
            ?.trim()
            ?.ifBlank { null }

        val id = child.selectFirst("div[id^=reply-section-wrapper]")
            ?.id()
            ?.substringAfterLast("-")
            ?.ifBlank { null }
            ?: "${username}_${content.hashCode()}"

        val replyCount = Regex("""\d+""")
            .find(child.select("div.load-replies-btn").text())
            ?.value
            ?.toIntOrNull()

        return Comment(
            id = id,
            username = username,
            avatarUrl = avatarUrl,
            content = content,
            timeAgo = date,
            likeCount = likeCount,
            replyCount = replyCount,
            hasMoreReplies = hasMoreReplies
        )
    }
}
