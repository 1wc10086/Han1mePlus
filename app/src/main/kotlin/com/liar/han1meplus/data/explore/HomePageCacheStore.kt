package com.liar.han1meplus.data.explore

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

private val Context.homePageDataStore by preferencesDataStore(name = "home_page_cache")

@Singleton
class HomePageCacheStore @Inject constructor(
    @ApplicationContext private val context: Context,
    private val json: Json
) {
    private val KEY = stringPreferencesKey("home_page_v1")

    suspend fun read(): HomePageCache? = runCatching {
        context.homePageDataStore.data
            .map { it[KEY] }
            .firstOrNull()
            ?.let { json.decodeFromString<HomePageCache>(it) }
    }.getOrNull()

    suspend fun write(cache: HomePageCache) {
        runCatching {
            context.homePageDataStore.edit { prefs ->
                prefs[KEY] = json.encodeToString(cache)
            }
        }
    }
}
