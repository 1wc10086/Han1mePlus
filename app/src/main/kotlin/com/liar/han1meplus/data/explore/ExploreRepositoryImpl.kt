package com.liar.han1meplus.data.explore

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import okhttp3.OkHttpClient
import okhttp3.Request
import javax.inject.Inject

private const val STALE_THRESHOLD_MS = 5 * 60 * 1000L

class ExploreRepositoryImpl @Inject constructor(
    private val okHttpClient: OkHttpClient,
    private val cacheStore: HomePageCacheStore
) : ExploreRepository {

    override fun getHomePage(baseUrl: String): Flow<HomePage> = flow {
        val cached = cacheStore.read()

        if (cached != null) {
            emit(cached.toHomePage())
            val age = System.currentTimeMillis() - cached.cachedAtMs
            if (age < STALE_THRESHOLD_MS) return@flow
        }

        val fresh = fetchFromNetwork(baseUrl)
        cacheStore.write(fresh.toCache())
        emit(fresh)
    }.flowOn(Dispatchers.IO)

    private fun fetchFromNetwork(baseUrl: String): HomePage {
        val request = Request.Builder()
            .url("$baseUrl/")
            .get()
            .header(
                "User-Agent",
                "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 " +
                    "(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36"
            )
            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
            .header("Accept-Language", "zh-CN,zh;q=0.9,zh-TW;q=0.8,en;q=0.7")
            .build()

        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IllegalStateException("请求失败：HTTP ${response.code}")
            }
            return HomePageParser.parse(html = response.body.string(), baseUrl = baseUrl)
        }
    }
}
