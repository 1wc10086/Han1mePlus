package com.liar.han1meplus

import androidx.annotation.Keep;
import android.content.Context
import android.os.Build
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.ArrayDeque
import java.util.Locale

@Keep
internal object EchHttpClient {
    private const val maxLogEntries = 100
    private val logEntries = ArrayDeque<String>()

    @Volatile var isLoaded = false
        private set

    fun init(context: Context) {
        if (isLoaded) return
        for (abi in Build.SUPPORTED_ABIS) {
            runCatching {
                val soFile = File(context.filesDir, "han1me_ech_$abi.so")
                context.assets.open("lib/$abi/libhan1me_ech.so").use { input ->
                    soFile.outputStream().use { output -> input.copyTo(output) }
                }
                System.load(soFile.absolutePath)
            }.onSuccess {
                isLoaded = true
                addLog("Loaded native library for $abi")
                return
            }
        }
        addLog("Native library was not found in assets")
    }

    external fun request(method: String, url: String, headers: Array<String>, body: ByteArray?, dohUrl: String, dohResolve: String): String

    fun execute(method: String, url: String, headers: Map<String, String>, body: ByteArray?, dohUrl: String, dohResolve: String): EchResponse {
        addLog("$method $url")
        val response = JSONObject(request(method, url, headers.map { "${it.key}: ${it.value}" }.toTypedArray(), body, dohUrl, dohResolve))
        val responseHeaders = buildMap<String, List<String>> {
            response.getJSONArray("headers").forEachString { line ->
                val separator = line.indexOf('\t')
                if (separator > 0) {
                    val name = line.substring(0, separator)
                    put(name, get(name).orEmpty() + line.substring(separator + 1))
                }
            }
        }
        response.optJSONArray("echLogs")?.forEachString(::addLog)
        return EchResponse(
            statusCode = response.getInt("statusCode"),
            body = Base64.decode(response.getString("body"), Base64.DEFAULT),
            url = response.getString("url"),
            headers = responseHeaders,
            echStatus = response.optString("echStatus", "unavailable"),
        ).also { addLog("${it.statusCode} ${it.echStatus} ${it.url}") }
    }

    fun logs(): List<String> = synchronized(logEntries) { logEntries.toList().asReversed() }

    fun clearLogs() = synchronized(logEntries) { logEntries.clear() }

    fun addLog(message: String) {
        val entry = "${SimpleDateFormat("HH:mm:ss", Locale.US).format(Date())}  $message"
        synchronized(logEntries) {
            while (logEntries.size >= maxLogEntries) logEntries.removeFirst()
            logEntries.addLast(entry)
        }
    }
}

internal data class EchResponse(val statusCode: Int, val body: ByteArray, val url: String, val headers: Map<String, List<String>>, val echStatus: String)

private inline fun JSONArray.forEachString(action: (String) -> Unit) {
    for (index in 0 until length()) action(getString(index))
}
