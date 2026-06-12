package com.liar.han1meplus.data.search

import org.jsoup.Jsoup
import org.jsoup.nodes.Element

object SearchParser {

    fun parse(html: String, baseUrl: String): SearchResult {
        val document = Jsoup.parse(html, baseUrl)

        val items = document
            .select("div.horizontal-card")
            .mapNotNull { parseCard(it) }

        val lastPageHref = document
            .select("ul.pagination li.page-item:not(.disabled) a.page-link")
            .mapNotNull { it.attr("href").let { href -> Regex("""page=(\d+)""").find(href)?.groupValues?.getOrNull(1)?.toIntOrNull() } }
            .maxOrNull() ?: 1

        val currentPage = document
            .selectFirst("ul.pagination li.page-item.active span.page-link")
            ?.text()?.toIntOrNull() ?: 1

        return SearchResult(items = items, currentPage = currentPage, totalPages = lastPageHref)
    }

    private fun parseCard(card: Element): SearchItem? {
        val link = card.selectFirst("a.video-link") ?: return null
        val detailUrl = link.absUrl("href")
        val videoCode = Regex("""[?&]v=(\d+)""").find(detailUrl)?.groupValues?.getOrNull(1) ?: return null
        val title = card.selectFirst("div.title")?.text()?.trim()?.ifBlank { null } ?: return null
        val coverUrl = card.selectFirst("img.main-thumb")?.absUrl("src")?.ifBlank { null } ?: return null

        val duration = card.selectFirst("div.duration")?.text()?.trim()?.ifBlank { null }
        val statItems = card.select("div.stats-container div.stat-item")
        val rating = statItems.getOrNull(0)?.text()?.replace("thumb_up", "")?.trim()?.ifBlank { null }
        val views = statItems.getOrNull(1)?.text()?.trim()?.ifBlank { null }
        val subtitle = card.selectFirst("div.subtitle a")?.text()?.trim().orEmpty()
        val parts = subtitle.split("•").map { it.trim() }
        val artist = parts.getOrNull(0)?.ifBlank { null }
        val uploadTime = parts.getOrNull(1)?.ifBlank { null }

        return SearchItem(videoCode, title, coverUrl, duration, views, rating, artist, uploadTime)
    }
}
