package com.liar.han1meplus.data.video

import org.jsoup.Jsoup
import org.jsoup.nodes.Element

object VideoDetailParser {

    fun parse(
        html: String,
        baseUrl: String,
        videoCode: String
    ): VideoDetail {
        val document = Jsoup.parse(html, baseUrl)
        val body = document.body()

        val title = body.getElementById("shareBtn-title")
            ?.text()
            ?.trim()
            ?.ifBlank { null }
            ?: document.selectFirst("meta[property=og:title]")
                ?.attr("content")
                ?.substringBefore(" - Hanime1.me")
                ?.trim()
            ?: "未知标题"

        val videoElement = body.selectFirst("video#player")

        val coverUrl = videoElement
            ?.absUrl("poster")
            ?.ifBlank { null }
            ?: document.selectFirst("meta[property=og:image]")
                ?.attr("content")
                ?.ifBlank { null }

        val videoSources = videoElement
            ?.select("source")
            ?.mapNotNull { source ->
                val url = source.absUrl("src").ifBlank { return@mapNotNull null }
                val size = source.attr("size").ifBlank { null }
                VideoSource(
                    quality = size?.let { "${it}P" } ?: "默认",
                    url = url,
                    type = source.attr("type").ifBlank { null }
                )
            }
            .orEmpty()
            .sortedByDescending { source ->
                source.quality.filter { it.isDigit() }.toIntOrNull() ?: 0
            }

        val artistName = body.getElementById("video-artist-name")
            ?.text()
            ?.trim()
            ?.ifBlank { null }

        val genre = body.getElementById("video-artist-name")
            ?.nextElementSibling()
            ?.text()
            ?.trim()
            ?.ifBlank { null }

        val artistAvatarUrl = body
            .select("div.video-details-wrapper img[style*=border-radius]")
            .lastOrNull()
            ?.absUrl("src")
            ?.ifBlank { null }

        val detailWrapper = body.selectFirst("div.video-details-wrapper")

        val viewAndDateText = detailWrapper
            ?.selectFirst("div.hidden-xs")
            ?.text()
            ?.trim()
            ?.ifBlank { null }
            ?: body.selectFirst("div.video-details-wrapper.hidden-sm")
                ?.text()
                ?.trim()
                ?.ifBlank { null }

        val viewsText = viewAndDateText
            ?.substringBefore(" ")
            ?.trim()
            ?.ifBlank { null }

        val uploadDate = Regex("""\d{4}-\d{2}-\d{2}""")
            .find(viewAndDateText.orEmpty())
            ?.value

        val introduction = body.selectFirst("div.video-caption-text")
            ?.text()
            ?.trim()
            ?.ifBlank { null }

        val tags = body.select("div.single-video-tag a")
            .mapNotNull { tag ->
                tag.text()
                    .replace("#", "")
                    .substringBefore("(")
                    .trim()
                    .ifBlank { null }
            }
            .distinct()

        val downloadUrl = body.getElementById("downloadBtn")
            ?.absUrl("href")
            ?.ifBlank { null }
            ?: "$baseUrl/download?v=$videoCode"

        val playlist = parsePlaylist(body)

        val relatedVideos = body.getElementById("related-tabcontent")
            ?.select("div.horizontal-card")
            ?.mapNotNull { card -> parseHorizontalCard(card) }
            ?.distinctBy { it.videoCode }
            .orEmpty()

        return VideoDetail(
            videoCode = videoCode,
            title = title,
            coverUrl = coverUrl,
            artistName = artistName,
            artistAvatarUrl = artistAvatarUrl,
            genre = genre,
            viewsText = viewsText,
            uploadDate = uploadDate,
            introduction = introduction,
            tags = tags,
            downloadUrl = downloadUrl,
            videoSources = videoSources,
            playlist = playlist,
            relatedVideos = relatedVideos
        )
    }

    private fun parsePlaylist(body: Element): List<VideoSimpleItem> {
        val playlistScroll = body.selectFirst("div#playlist-scroll")
            ?: return emptyList()

        return playlistScroll
            .select("div.related-watch-wrap")
            .mapNotNull { wrapper ->
                val link = wrapper.selectFirst("a.overlay")
                    ?: return@mapNotNull null

                val detailUrl = link.absUrl("href")
                val videoCode = detailUrl.toVideoCode() ?: return@mapNotNull null

                val image = wrapper.select("img")
                    .lastOrNull { it.hasAttr("alt") }

                val coverUrl = image
                    ?.absUrl("src")
                    ?.ifBlank { null }
                    ?: return@mapNotNull null

                val title = wrapper.selectFirst("div.card-mobile-title")
                    ?.text()
                    ?.trim()
                    ?.ifBlank { null }
                    ?: image.attr("alt").trim().ifBlank { null }
                    ?: return@mapNotNull null

                val duration = wrapper.selectFirst("div.card-playlist-small")
                    ?.text()
                    ?.trim()
                    ?.ifBlank { null }

                val artist = wrapper.selectFirst("a.card-mobile-user")
                    ?.text()
                    ?.trim()
                    ?.ifBlank { null }

                val statItems = wrapper.select("div.card-playlist-large")
                    .map { it.text().trim() }

                val rating = statItems.getOrNull(0)
                    ?.replace("thumb_up", "")
                    ?.trim()
                    ?.ifBlank { null }

                val views = statItems.getOrNull(1)
                    ?.trim()
                    ?.ifBlank { null }

                val isPlaying = wrapper.text().contains("現正播放") ||
                    wrapper.text().contains("现正播放")

                VideoSimpleItem(
                    videoCode = videoCode,
                    title = title,
                    coverUrl = coverUrl,
                    duration = duration,
                    views = views,
                    rating = rating,
                    artist = artist,
                    isPlaying = isPlaying
                )
            }
            .distinctBy { it.videoCode }
    }

    private fun parseHorizontalCard(card: Element): VideoSimpleItem? {
        val link = card.selectFirst("a.video-link")
            ?: return null

        val detailUrl = link.absUrl("href")
        val videoCode = detailUrl.toVideoCode() ?: return null

        val title = card.selectFirst("div.title")
            ?.text()
            ?.trim()
            ?.ifBlank { null }
            ?: return null

        val coverUrl = card.selectFirst("img.main-thumb")
            ?.absUrl("src")
            ?.ifBlank { null }
            ?: return null

        val duration = card.selectFirst("div.duration")
            ?.text()
            ?.trim()
            ?.ifBlank { null }

        val statItems = card.select("div.stats-container div.stat-item")

        val rating = statItems.getOrNull(0)
            ?.text()
            ?.replace("thumb_up", "")
            ?.trim()
            ?.ifBlank { null }

        val views = statItems.getOrNull(1)
            ?.text()
            ?.trim()
            ?.ifBlank { null }

        val subtitle = card.selectFirst("div.subtitle a")
            ?.text()
            ?.trim()
            .orEmpty()

        val artist = subtitle
            .substringBefore("•")
            .trim()
            .ifBlank { null }

        return VideoSimpleItem(
            videoCode = videoCode,
            title = title,
            coverUrl = coverUrl,
            duration = duration,
            views = views,
            rating = rating,
            artist = artist
        )
    }

    private fun String.toVideoCode(): String? {
        return Regex("""[?&]v=(\d+)""")
            .find(this)
            ?.groupValues
            ?.getOrNull(1)
    }
}
