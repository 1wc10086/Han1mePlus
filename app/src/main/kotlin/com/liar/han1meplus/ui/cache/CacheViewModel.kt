package com.liar.han1meplus.ui.cache

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.liar.han1meplus.data.download.DownloadGroup
import com.liar.han1meplus.data.download.DownloadRepository
import com.liar.han1meplus.data.download.DownloadTask
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CacheUiState(
    val groups: List<DownloadGroup> = emptyList(),
    val tasks: List<DownloadTask> = emptyList(),
    val selectedGroupId: String = "default",
    val selectionMode: Boolean = false,
    val selectedTaskIds: Set<String> = emptySet(),
    val showAddGroupDialog: Boolean = false
) {
    val visibleTasks: List<DownloadTask>
        get() = tasks.filter { it.groupId == selectedGroupId }
}

@HiltViewModel
class CacheViewModel @Inject constructor(
    private val downloadRepository: DownloadRepository
) : ViewModel() {

    private val localState = kotlinx.coroutines.flow.MutableStateFlow(CacheUiState())

    val uiState: StateFlow<CacheUiState> = kotlinx.coroutines.flow.combine(
        downloadRepository.store,
        localState
    ) { store, local ->
        local.copy(
            groups = store.groups,
            tasks = store.tasks,
            selectedGroupId = local.selectedGroupId.takeIf { id -> store.groups.any { it.id == id } } ?: "default"
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = CacheUiState()
    )

    fun selectGroup(id: String) {
        localState.value = localState.value.copy(selectedGroupId = id, selectedTaskIds = emptySet())
    }

    fun toggleSelectionMode() {
        localState.value = localState.value.copy(
            selectionMode = !localState.value.selectionMode,
            selectedTaskIds = emptySet()
        )
    }

    fun toggleTaskSelection(id: String) {
        val current = localState.value
        val nextIds = if (id in current.selectedTaskIds) {
            current.selectedTaskIds - id
        } else {
            current.selectedTaskIds + id
        }
        localState.value = current.copy(selectedTaskIds = nextIds)
    }

    fun showAddGroupDialog() {
        localState.value = localState.value.copy(showAddGroupDialog = true)
    }

    fun dismissAddGroupDialog() {
        localState.value = localState.value.copy(showAddGroupDialog = false)
    }

    fun addGroup(name: String) {
        viewModelScope.launch {
            downloadRepository.addGroup(name)
            dismissAddGroupDialog()
        }
    }

    fun deleteSelected() {
        val ids = localState.value.selectedTaskIds
        viewModelScope.launch {
            downloadRepository.deleteTasks(ids)
            localState.value = localState.value.copy(
                selectionMode = false,
                selectedTaskIds = emptySet()
            )
        }
    }
}
