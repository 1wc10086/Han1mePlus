package com.liar.han1meplus.ui.search

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.navigation.toRoute
import com.liar.han1meplus.data.search.SearchRepository
import com.liar.han1meplus.data.search.SearchResult
import com.liar.han1meplus.data.settings.AppSettings
import com.liar.han1meplus.navigation.Route
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface SearchUiState {
    data object Idle : SearchUiState
    data object Loading : SearchUiState
    data class Success(val result: SearchResult, val query: String, val genre: String, val sort: String) : SearchUiState
    data class Error(val message: String) : SearchUiState
}

@HiltViewModel
class SearchViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: SearchRepository,
    private val appSettings: AppSettings
) : ViewModel() {

    private val route = savedStateHandle.toRoute<Route.Search>()

    private val _uiState = MutableStateFlow<SearchUiState>(SearchUiState.Idle)
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    var query = MutableStateFlow(route.initialQuery)
    var genre = MutableStateFlow(route.initialGenre)
    var sort = MutableStateFlow("")
    var currentPage = MutableStateFlow(1)

    private var searchJob: Job? = null

    init {
        if (route.initialQuery.isNotBlank() || route.initialGenre.isNotBlank()) {
            search()
        }
    }

    fun search(page: Int = 1) {
        searchJob?.cancel()
        currentPage.value = page
        searchJob = viewModelScope.launch {
            _uiState.value = SearchUiState.Loading
            val baseUrl = appSettings.settings.first().baseUrl
            repository.search(baseUrl, query.value, genre.value, sort.value, page)
                .catch { _uiState.value = SearchUiState.Error(it.message ?: "未知错误") }
                .collect {
                    _uiState.value = SearchUiState.Success(it, query.value, genre.value, sort.value)
                }
        }
    }

    fun setQuery(v: String) { query.value = v }
    fun setGenre(v: String) { genre.value = v; search() }
    fun setSort(v: String) { sort.value = v; search() }
}
