package com.liar.han1meplus.data.explore

import org.jsoup.Jsoup
import org.jsoup.nodes.Element

object HomePageParser {

    private val RIBUN_KEYWORDS = setOf("裏番", "里番", "裏番OVA")

    fun parse(html: String, baseUrl: String): HomePage {
        val document = Jsoup.parse(html, baseUrl)
        val body = document.body()

        val rowsWrapper = body.getElementById("home-rows-wrapper")
            ?: return HomePage(sections = emptyList())

        val sections = mutableListOf<HomeSection>()
        val titleElements = rowsWrapper.select("a.horizontal-row-title")

        titleElements.forEach { titleElement ->
            val sectionTitle = titleElement.selectFirst("h3")
                ?.ownText()?.trim().orEmpty()

            if (sectionTitle.isBlank()) return@forEach

            val moreUrl = titleElement.absUrl("href").ifBlank { null }
            val isRibun = RIBUN_KEYWORDS.any { sectionTitle.contains(it) }

            val contentElement = titleElement.findNextVideoContainer() ?: return@forEach

            val items = contentElement
                .select("div.horizontal-card")
                .mapNotNull { parseCard(it) }

            if (items.isNotEmpty()) {
                sections += HomeSection(
                    title = sectionTitle,
                    moreUrl = moreUrl,
                    items = items,
                    isRibun = isRibun
                )
            }
        }

        return HomePage(sections = sections)
    }

    private fun parseCard(card: Element): HomeAnimeItem? {
        val link = card.selectFirst("a.video-link")
            ?: card.selectFirst("a[href*=/watch?v=]")
            ?: return null

        val detailUrl = link.absUrl("href")
        val videoCode = detailUrl.toVideoCode() ?: return null

        val title = card.selectFirst("div.title, h4.video-title")
            ?.text()?.trim()?.ifBlank { null }
            ?: card.parent()?.attr("title")?.trim()?.ifBlank { null }
            ?: return null

        val coverUrl = card.selectFirst("img.main-thumb, img")
            ?.absUrl("src")?.ifBlank { null }
            ?: return null

        val duration = card.selectFirst("div.duration")?.text()?.trim()?.ifBlank { null }
        val statItems = card.select("div.stats-container div.stat-item")
        val rating = statItems.getOrNull(0)?.text()?.replace("thumb_up", "")?.trim()?.ifBlank { null }
        val views = statItems.getOrNull(1)?.text()?.trim()?.ifBlank { null }
        val subtitle = card.selectFirst("div.subtitle a")?.text()?.trim().orEmpty()
        val artistAndUploadTime = parseArtistAndUploadTime(subtitle)

        return HomeAnimeItem(
            videoCode = videoCode,
            title = title,
            coverUrl = coverUrl,
            detailUrl = detailUrl,
            duration = duration,
            views = views,
            rating = rating,
            artist = artistAndUploadTime.first,
            uploadTime = artistAndUploadTime.second
        )
    }

    private fun parseArtistAndUploadTime(text: String): Pair<String?, String?> {
        if (text.isBlank()) return null to null
        val parts = text.split("•").map { it.trim() }
        return when {
            parts.size >= 2 -> parts[0].ifBlank { null } to parts[1].ifBlank { null }
            else -> text.ifBlank { null } to null
        }
    }

    private fun Element.findNextVideoContainer(): Element? {
        var next = nextElementSibling()
        while (next != null) {
            if (next.selectFirst("div.horizontal-card") != null) return next
            next = next.nextElementSibling()
        }
        return null
    }

    private fun String.toVideoCode(): String? =
        Regex("""[?&]v=(\d+)""").find(this)?.groupValues?.getOrNull(1)
}
