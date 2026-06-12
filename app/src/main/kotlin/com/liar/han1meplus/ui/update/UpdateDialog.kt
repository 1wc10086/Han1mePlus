package com.liar.han1meplus.ui.update

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.liar.han1meplus.data.update.UpdateInfo

@Composable
fun UpdateDialog(
    info: UpdateInfo,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "发现新版本 ${info.tagName}${if (info.prerelease) "（预览版）" else ""}"
            )
        },
        text = {
            Column(
                modifier = Modifier.verticalScroll(rememberScrollState())
            ) {
                if (info.body.isNotBlank()) {
                    Text(
                        text = info.body,
                        style = MaterialTheme.typography.bodyMedium
                    )

                    Spacer(modifier = Modifier.height(10.dp))
                }

                Text(
                    text = "发布时间：${formatDate(info.createdAt)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onDismiss()

                    val intent = Intent(
                        Intent.ACTION_VIEW,
                        Uri.parse(info.downloadUrl)
                    ).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    runCatching {
                        context.startActivity(intent)
                    }
                }
            ) {
                Text("立即更新")
            }
        },
        dismissButton = {
            TextButton(
                onClick = {
                    onDismiss()

                    val intent = Intent(
                        Intent.ACTION_VIEW,
                        Uri.parse(info.htmlUrl)
                    ).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    runCatching {
                        context.startActivity(intent)
                    }
                }
            ) {
                Text("查看详情")
            }

            TextButton(
                onClick = onDismiss
            ) {
                Text("稍后提醒")
            }
        }
    )
}

private fun formatDate(iso: String): String {
    return runCatching {
        val text = iso.removeSuffix("Z")
        val dt = java.time.LocalDateTime.parse(text)
        "%04d-%02d-%02d".format(dt.year, dt.monthValue, dt.dayOfMonth)
    }.getOrElse {
        iso.take(10)
    }
}
