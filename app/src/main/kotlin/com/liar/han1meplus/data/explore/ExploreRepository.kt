package com.liar.han1meplus.data.explore

import kotlinx.coroutines.flow.Flow

interface ExploreRepository {
    fun getHomePage(baseUrl: String): Flow<HomePage>
}
