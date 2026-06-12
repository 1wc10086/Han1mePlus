package com.liar.han1meplus.data.settings

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "app_settings")

enum class DarkThemeConfig(val label: String) {
    FOLLOW_SYSTEM("跟随系统"), LIGHT("浅色"), DARK("深色")
}

enum class ColorSchemeConfig(val label: String) {
    MONET("莫奈配色"), PURPLE("MD3 紫色")
}

enum class VideoResolution(val label: String, val p: Int) {
    P480("480P", 480), P720("720P", 720), P1080("1080P", 1080)
}

enum class PlayerKernel(val label: String) {
    EXOPLAYER("ExoPlayer"), MEDIA_PLAYER("系统播放器")
}

data class AppSettingsData(
    val darkTheme: DarkThemeConfig = DarkThemeConfig.FOLLOW_SYSTEM,
    val colorScheme: ColorSchemeConfig = ColorSchemeConfig.PURPLE,
    val baseUrl: String = "https://hanimeone.me",
    val videoResolution: VideoResolution = VideoResolution.P720,
    val playerKernel: PlayerKernel = PlayerKernel.EXOPLAYER,
    val autoUpdate: Boolean = true
)

val BASE_URL_OPTIONS = listOf(
    "https://hanimeone.me",
    "https://hanime1.com",
    "https://hanime1.me",
    "https://javchu.com"
)

@Singleton
class AppSettings @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val darkTheme = stringPreferencesKey("dark_theme")
        val colorScheme = stringPreferencesKey("color_scheme")
        val baseUrl = stringPreferencesKey("base_url")
        val videoResolution = intPreferencesKey("video_resolution")
        val playerKernel = stringPreferencesKey("player_kernel")
        val autoUpdate = booleanPreferencesKey("auto_update")
    }

    val settings: Flow<AppSettingsData> = context.dataStore.data.map { prefs ->
        AppSettingsData(
            darkTheme = prefs[Keys.darkTheme]
                ?.let { runCatching { DarkThemeConfig.valueOf(it) }.getOrNull() }
                ?: DarkThemeConfig.FOLLOW_SYSTEM,
            colorScheme = prefs[Keys.colorScheme]
                ?.let { runCatching { ColorSchemeConfig.valueOf(it) }.getOrNull() }
                ?: ColorSchemeConfig.PURPLE,
            baseUrl = prefs[Keys.baseUrl] ?: "https://hanimeone.me",
            videoResolution = prefs[Keys.videoResolution]
                ?.let { p -> VideoResolution.entries.find { it.p == p } }
                ?: VideoResolution.P720,
            playerKernel = prefs[Keys.playerKernel]
                ?.let { runCatching { PlayerKernel.valueOf(it) }.getOrNull() }
                ?: PlayerKernel.EXOPLAYER,
            autoUpdate = prefs[Keys.autoUpdate] ?: true
        )
    }

    suspend fun setDarkTheme(v: DarkThemeConfig) =
        context.dataStore.edit { it[Keys.darkTheme] = v.name }

    suspend fun setColorScheme(v: ColorSchemeConfig) =
        context.dataStore.edit { it[Keys.colorScheme] = v.name }

    suspend fun setBaseUrl(v: String) =
        context.dataStore.edit { it[Keys.baseUrl] = v }

    suspend fun setVideoResolution(v: VideoResolution) =
        context.dataStore.edit { it[Keys.videoResolution] = v.p }

    suspend fun setPlayerKernel(v: PlayerKernel) =
        context.dataStore.edit { it[Keys.playerKernel] = v.name }

    suspend fun setAutoUpdate(v: Boolean) =
        context.dataStore.edit { it[Keys.autoUpdate] = v }
}
