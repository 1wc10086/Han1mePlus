package com.liar.han1meplus.data.explore

internal fun HomePage.toCache(nowMs: Long = System.currentTimeMillis()) = HomePageCache(
    sections = sections.map { section ->
        HomeSectionCache(
            title = section.title,
            moreUrl = section.moreUrl,
            isRibun = section.isRibun,
            items = section.items.map { item ->
                HomeAnimeItemCache(
                    videoCode = item.videoCode,
                    title = item.title,
                    coverUrl = item.coverUrl,
                    detailUrl = item.detailUrl,
                    duration = item.duration,
                    views = item.views,
                    rating = item.rating,
                    artist = item.artist,
                    uploadTime = item.uploadTime
                )
            }
        )
    },
    cachedAtMs = nowMs
)

internal fun HomePageCache.toHomePage() = HomePage(
    sections = sections.map { section ->
        HomeSection(
            title = section.title,
            moreUrl = section.moreUrl,
            isRibun = section.isRibun,
            items = section.items.map { item ->
                HomeAnimeItem(
                    videoCode = item.videoCode,
                    title = item.title,
                    coverUrl = item.coverUrl,
                    detailUrl = item.detailUrl,
                    duration = item.duration,
                    views = item.views,
                    rating = item.rating,
                    artist = item.artist,
                    uploadTime = item.uploadTime
                )
            }
        )
    }
)
