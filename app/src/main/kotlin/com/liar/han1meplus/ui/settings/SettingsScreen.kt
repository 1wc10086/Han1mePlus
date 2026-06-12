package com.liar.han1meplus.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.liar.han1meplus.data.settings.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBackClick: () -> Unit,
    onAboutClick: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val settings by viewModel.settings.collectAsStateWithLifecycle()

    var showDarkThemeDialog by remember { mutableStateOf(false) }
    var showColorSchemeDialog by remember { mutableStateOf(false) }
    var showBaseUrlDialog by remember { mutableStateOf(false) }
    var showResolutionDialog by remember { mutableStateOf(false) }
    var showPlayerKernelDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("设置", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            item { SettingsSectionHeader("主题") }

            item {
                SettingsListTile(
                    title = "深色主题",
                    subtitle = settings.darkTheme.label,
                    onClick = { showDarkThemeDialog = true }
                )
            }

            item {
                SettingsListTile(
                    title = "主题配色",
                    subtitle = settings.colorScheme.label,
                    onClick = { showColorSchemeDialog = true }
                )
            }

            item { SettingsSectionHeader("网络") }

            item {
                SettingsListTile(
                    title = "域名设置",
                    subtitle = settings.baseUrl,
                    onClick = { showBaseUrlDialog = true }
                )
            }

            item { SettingsSectionHeader("影片") }

            item {
                SettingsListTile(
                    title = "默认分辨率",
                    subtitle = settings.videoResolution.label,
                    onClick = { showResolutionDialog = true }
                )
            }

            item {
                SettingsListTile(
                    title = "播放器内核",
                    subtitle = settings.playerKernel.label,
                    onClick = { showPlayerKernelDialog = true }
                )
            }

            item { SettingsSectionHeader("更新") }

            item {
                SettingsSwitchTile(
                    title = "自动检查更新",
                    subtitle = if (settings.autoUpdate) "启用" else "关闭",
                    checked = settings.autoUpdate,
                    onCheckedChange = viewModel::setAutoUpdate
                )
            }

            item { SettingsSectionHeader("关于") }

            item {
                SettingsListTile(
                    title = "关于应用",
                    subtitle = null,
                    showArrow = true,
                    onClick = onAboutClick
                )
            }
        }
    }

    if (showDarkThemeDialog) {
        SingleChoiceDialog(
            title = "深色主题",
            options = DarkThemeConfig.entries,
            selected = settings.darkTheme,
            labelOf = { it.label },
            onDismiss = { showDarkThemeDialog = false },
            onSelect = { viewModel.setDarkTheme(it); showDarkThemeDialog = false }
        )
    }

    if (showColorSchemeDialog) {
        SingleChoiceDialog(
            title = "主题配色",
            options = ColorSchemeConfig.entries,
            selected = settings.colorScheme,
            labelOf = { it.label },
            onDismiss = { showColorSchemeDialog = false },
            onSelect = { viewModel.setColorScheme(it); showColorSchemeDialog = false }
        )
    }

    if (showBaseUrlDialog) {
        SingleChoiceDialog(
            title = "域名设置",
            options = BASE_URL_OPTIONS,
            selected = settings.baseUrl,
            labelOf = { it },
            onDismiss = { showBaseUrlDialog = false },
            onSelect = { viewModel.setBaseUrl(it); showBaseUrlDialog = false }
        )
    }

    if (showResolutionDialog) {
        SingleChoiceDialog(
            title = "默认分辨率",
            options = VideoResolution.entries,
            selected = settings.videoResolution,
            labelOf = { it.label },
            onDismiss = { showResolutionDialog = false },
            onSelect = { viewModel.setVideoResolution(it); showResolutionDialog = false }
        )
    }

    if (showPlayerKernelDialog) {
        SingleChoiceDialog(
            title = "播放器内核",
            options = PlayerKernel.entries,
            selected = settings.playerKernel,
            labelOf = { it.label },
            onDismiss = { showPlayerKernelDialog = false },
            onSelect = { viewModel.setPlayerKernel(it); showPlayerKernelDialog = false }
        )
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 16.dp, end = 16.dp, top = 20.dp, bottom = 6.dp),
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = FontWeight.SemiBold
    )
}

@Composable
private fun SettingsListTile(
    title: String,
    subtitle: String?,
    showArrow: Boolean = false,
    onClick: () -> Unit
) {
    ListItem(
        headlineContent = { Text(title) },
        supportingContent = subtitle?.let { { Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant) } },
        trailingContent = if (showArrow) {
            { Icon(Icons.AutoMirrored.Filled.ArrowForwardIos, contentDescription = null, modifier = Modifier.size(16.dp)) }
        } else null,
        modifier = Modifier.clickable(onClick = onClick)
    )
}

@Composable
private fun SettingsSwitchTile(
    title: String,
    subtitle: String?,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    ListItem(
        headlineContent = { Text(title) },
        supportingContent = subtitle?.let { { Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant) } },
        trailingContent = { Switch(checked = checked, onCheckedChange = onCheckedChange) },
        modifier = Modifier.clickable { onCheckedChange(!checked) }
    )
}

@Composable
private fun <T> SingleChoiceDialog(
    title: String,
    options: List<T>,
    selected: T,
    labelOf: (T) -> String,
    onDismiss: () -> Unit,
    onSelect: (T) -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                options.forEach { option ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(option) }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(selected = option == selected, onClick = { onSelect(option) })
                        Spacer(Modifier.width(8.dp))
                        Text(labelOf(option))
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("取消") } }
    )
}
