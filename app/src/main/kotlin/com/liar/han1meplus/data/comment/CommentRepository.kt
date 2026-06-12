package com.liar.han1meplus.data.comment

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import okhttp3.Headers
import okhttp3.OkHttpClient
import okhttp3.Request
import javax.inject.Inject

interface CommentRepository {
    fun getComments(baseUrl: String, videoCode: String, page: Int): Flow<CommentPage>
}

class CommentRepositoryImpl @Inject constructor(
    private val okHttpClient: OkHttpClient
) : CommentRepository {

    override fun getComments(
        baseUrl: String,
        videoCode: String,
        page: Int
    ): Flow<CommentPage> = flow {
        val normalizedBaseUrl = baseUrl.trimEnd('/')
        val watchUrl = "$normalizedBaseUrl/watch?v=$videoCode"
        val commentUrl = "$normalizedBaseUrl/loadComment?type=video&id=$videoCode"

        val request = Request.Builder()
            .url(commentUrl)
            .get()
            .headers(defaultHeaders(referer = watchUrl))
            .build()

        okHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IllegalStateException("请求评论失败：HTTP ${response.code}")
            }

            val body = response.body.string()
            emit(CommentParser.parse(body = body, baseUrl = normalizedBaseUrl))
        }
    }.flowOn(Dispatchers.IO)

    private fun defaultHeaders(referer: String): Headers {
        return Headers.Builder()
            .add("User-Agent", USER_AGENT)
            .add("Accept", "application/json, text/javascript, */*; q=0.01")
            .add("Accept-Language", "zh-CN,zh;q=0.9,zh-TW;q=0.8,en;q=0.7")
            .add("Referer", referer)
            .add("X-Requested-With", "XMLHttpRequest")
            .build()
    }

    private companion object {
        const val USER_AGENT =
            "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36"
    }
}
