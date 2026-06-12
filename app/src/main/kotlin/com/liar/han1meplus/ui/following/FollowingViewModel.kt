package com.liar.han1meplus.ui.following

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liar.han1meplus.data.following.FollowingRepository
import com.liar.han1meplus.data.following.FollowingStore
import com.liar.han1meplus.data.following.FollowingVideoItem
import com.liar.han1meplus.data.following.SubscribedArtist
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

enum class FollowingTab {
    WatchLater,
    Favorite,
    Subscription
}

data class FollowingUiState(
    val store: FollowingStore = FollowingStore(),
    val selectedTab: FollowingTab = FollowingTab.WatchLater,
    val selectedArtistId: String? = null
) {
    val tabs: List<FollowingTab> = listOf(
        FollowingTab.WatchLater,
        FollowingTab.Favorite,
        FollowingTab.Subscription
    )

    val selectedArtist: SubscribedArtist?
        get() = store.subscribedArtists.firstOrNull { it.id == selectedArtistId }
            ?: store.subscribedArtists.firstOrNull()

    val visibleVideos: List<FollowingVideoItem>
        get() = when (selectedTab) {
            FollowingTab.WatchLater -> store.watchLater
            FollowingTab.Favorite -> store.favorites
            FollowingTab.Subscription -> {
                val id = selectedArtist?.id
                if (id == null) emptyList()
                else store.subscriptionVideos[id].orEmpty()
            }
        }
}

@HiltViewModel
class FollowingViewModel @Inject constructor(
    repository: FollowingRepository
) : ViewModel() {

    private val selectedTab = MutableStateFlow(FollowingTab.WatchLater)
    private val selectedArtistId = MutableStateFlow<String?>(null)

    val uiState: StateFlow<FollowingUiState> = combine(
        repository.store,
        selectedTab,
        selectedArtistId
    ) { store, tab, artistId ->
        val safeArtistId = artistId?.takeIf { id -> store.subscribedArtists.any { it.id == id } }
            ?: store.subscribedArtists.firstOrNull()?.id
        FollowingUiState(
            store = store,
            selectedTab = tab,
            selectedArtistId = safeArtistId
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = FollowingUiState()
    )

    fun selectTab(tab: FollowingTab) {
        selectedTab.value = tab
    }

    fun selectArtist(id: String) {
        selectedArtistId.value = id
    }
}
