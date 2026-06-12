package com.liar.han1meplus.data.update

import com.liar.han1meplus.AppVersion
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.OkHttpClient
import okhttp3.Request
import javax.inject.Inject
import javax.inject.Singleton

data class UpdateInfo(
    val tagName: String,
    val htmlUrl: String,
    val body: String,
    val createdAt: String,
    val downloadUrl: String,
    val prerelease: Boolean
)

@Singleton
class UpdateChecker @Inject constructor(
    private val okHttpClient: OkHttpClient
) {
    private companion object {
        const val API_URL = "https://api.github.com/repos/1wc10086/Han1mePlus/releases/latest"
    }

    suspend fun checkForUpdate(): UpdateInfo? = withContext(Dispatchers.IO) {
        runCatching {
            val request = Request.Builder()
                .url(API_URL)
                .header("Accept", "application/vnd.github+json")
                .build()

            okHttpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    return@withContext null
                }

                val responseBody = response.body.string()
                if (responseBody.isBlank()) {
                    return@withContext null
                }

                val json = Json.parseToJsonElement(responseBody).jsonObject

                val tagName = json["tag_name"]
                    ?.jsonPrimitive
                    ?.content
                    ?.trim()
                    ?: return@withContext null

                val htmlUrl = json["html_url"]
                    ?.jsonPrimitive
                    ?.content
                    .orEmpty()

                val releaseBody = json["body"]
                    ?.jsonPrimitive
                    ?.content
                    .orEmpty()

                val createdAt = json["created_at"]
                    ?.jsonPrimitive
                    ?.content
                    .orEmpty()

                val prerelease = json["prerelease"]
                    ?.jsonPrimitive
                    ?.booleanOrNull
                    ?: false

                val assets = json["assets"]
                    ?.jsonArray
                    ?: return@withContext null

                val downloadUrl = assets.firstNotNullOfOrNull { asset ->
                    val assetObject = asset.jsonObject

                    val name = assetObject["name"]
                        ?.jsonPrimitive
                        ?.content
                        .orEmpty()

                    if (name.endsWith(".apk", ignoreCase = true)) {
                        assetObject["browser_download_url"]
                            ?.jsonPrimitive
                            ?.content
                    } else {
                        null
                    }
                } ?: return@withContext null

                val remoteVersion = tagName
                    .removePrefix("v")
                    .removePrefix("V")

                if (!isNewer(remoteVersion, AppVersion.NAME)) {
                    return@withContext null
                }

                if (downloadUrl.isBlank()) {
                    return@withContext null
                }

                UpdateInfo(
                    tagName = tagName,
                    htmlUrl = htmlUrl,
                    body = releaseBody,
                    createdAt = createdAt,
                    downloadUrl = downloadUrl,
                    prerelease = prerelease
                )
            }
        }.getOrNull()
    }

    private fun isNewer(
        remote: String,
        current: String
    ): Boolean {
        fun parse(version: String): List<Int> {
            return version
                .substringBefore("-")
                .substringBefore("+")
                .split(".")
                .map {
                    it.toIntOrNull() ?: 0
                }
        }

        val remoteParts = parse(remote)
        val currentParts = parse(current)

        for (index in 0 until 3) {
            val remoteValue = remoteParts.getOrElse(index) { 0 }
            val currentValue = currentParts.getOrElse(index) { 0 }

            if (remoteValue > currentValue) return true
            if (remoteValue < currentValue) return false
        }

        return false
    }
}
