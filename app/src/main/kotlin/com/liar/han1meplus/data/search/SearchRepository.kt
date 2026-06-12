package com.liar.han1meplus.data.search

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import okhttp3.OkHttpClient
import okhttp3.Request
import javax.inject.Inject

interface SearchRepository {
    fun search(baseUrl: String, query: String, genre: String, sort: String, page: Int): Flow<SearchResult>
}

class SearchRepositoryImpl @Inject constructor(
    private val okHttpClient: OkHttpClient
) : SearchRepository {

    override fun search(baseUrl: String, query: String, genre: String, sort: String, page: Int): Flow<SearchResult> = flow {
        val urlBuilder = StringBuilder("$baseUrl/search?page=$page")
        if (query.isNotBlank()) urlBuilder.append("&query=${query.trim()}")
        if (genre.isNotBlank() && genre != "全部") urlBuilder.append("&genre=$genre")
        if (sort.isNotBlank()) urlBuilder.append("&sort=$sort")

        val request = Request.Builder()
            .url(urlBuilder.toString())
            .header("User-Agent", "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36")
            .header("Accept", "text/html")
            .header("Accept-Language", "zh-CN,zh;q=0.9")
            .build()

        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throw IllegalStateException("请求失败：HTTP ${response.code}")
            val html = response.body.string()
            emit(SearchParser.parse(html, baseUrl))
        }
    }.flowOn(Dispatchers.IO)
}
