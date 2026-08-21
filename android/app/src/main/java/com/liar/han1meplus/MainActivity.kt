package com.liar.han1meplus

import androidx.annotation.Keep;
import android.content.Context
import android.content.Intent
import android.app.KeyguardManager
import android.app.Activity
import android.app.PictureInPictureParams
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.view.KeyEvent
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.Dns
import okhttp3.FormBody
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.dnsoverhttps.DnsOverHttps
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.net.InetAddress
import java.nio.charset.Charset
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@Keep
class MainActivity : FlutterActivity() {
    companion object {
        const val preferencesName = "han1meplus_http"
        const val cookieKey = "cookies"
        const val useBuiltInHostsKey = "use_built_in_hosts"
        const val useDohKey = "use_doh"
        const val dohPresetKey = "doh_preset"
        const val dohCustomUrlKey = "doh_custom_url"
        const val dohBootstrapIpsKey = "doh_bootstrap_ips"
        const val dohTimeoutSecondsKey = "doh_timeout_seconds"
        const val useEchKey = "use_ech"

        fun saveCookies(context: Context, cookies: String, url: String) {
            val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            val host = requireNotNull(android.net.Uri.parse(url).host)
            val editor = preferences.edit()
            for (target in cookieHosts(host)) {
                val key = "$cookieKey:$target"
                editor.putString(key, mergeCookies(preferences.getString(key, "").orEmpty(), cookies))
            }
            editor.commit()
        }

        private fun mergeCookies(current: String, next: String): String = (current.split(';') + next.split(';'))
            .mapNotNull { value ->
                val pair = value.trim()
                val index = pair.indexOf('=')
                if (index <= 0) null else pair.substring(0, index).trim() to pair.substring(index + 1).trim()
            }
            .toMap()
            .entries
            .joinToString("; ") { "${it.key}=${it.value}" }

        private fun cookieHosts(host: String) = if (host in hanimeHosts) hanimeHosts else setOf(host)

        private val hanimeHosts = setOf("hanime1.me", "hanime1.com", "hanimeone.me", "javchu.com")
    }

    private val channelName = "com.liar.han1meplus/http"
    private val platformChannelName = "com.liar.han1meplus/platform"
    private val userAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36"
    private val responseCookies = mutableMapOf<String, List<Cookie>>()
    @Volatile private var networkSettings = NetworkSettings()
    private var emergencyExitEnabled = false
    private var volumeUpPresses = 0
    private var lastVolumeUpPress = 0L
    private var authenticationResult: MethodChannel.Result? = null
    private var directoryResult: MethodChannel.Result? = null
    private var documentResult: MethodChannel.Result? = null
    private var documentBytes: ByteArray? = null
    @Volatile private lateinit var client: OkHttpClient

    private val cookieJar = object : CookieJar {
        override fun loadForRequest(url: okhttp3.HttpUrl): List<Cookie> =
            (persistedCookies(url) + responseCookies[url.host].orEmpty())
                .associateBy { it.name }
                .values
                .toList()

        override fun saveFromResponse(url: okhttp3.HttpUrl, cookies: List<Cookie>) {
            responseCookies[url.host] = (responseCookies[url.host].orEmpty() + cookies)
                .associateBy { it.name }
                .values
                .toList()
            saveCookies(applicationContext, cookies.joinToString("; ") { "${it.name}=${it.value}" }, url.toString())
        }
    }

    private fun createClient() = OkHttpClient.Builder()
        .dns(ConfigurableDns { networkSettings })
        .addInterceptor(CloudflareInterceptor(applicationContext))
        .cookieJar(cookieJar)
        .build()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EchHttpClient.init(applicationContext)
        networkSettings = loadNetworkSettings()
        client = createClient()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveCookies" -> {
                    val url = call.argument<String>("url")
                    if (url == null) result.error("invalid_url", "Missing URL", null)
                    else {
                        saveCookies(this, call.argument<String>("cookies").orEmpty(), url)
                        result.success(null)
                    }
                }
                "clearCookies" -> {
                    val url = call.argument<String>("url")
                    if (url == null) result.error("invalid_url", "Missing URL", null)
                    else {
                        val host = requireNotNull(android.net.Uri.parse(url).host)
                        val editor = getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit()
                        for (target in cookieHosts(host)) {
                            responseCookies.remove(target)
                            editor.remove("$cookieKey:$target")
                        }
                        editor.apply()
                        result.success(null)
                    }
                }
                "webViewCookies" -> {
                    val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("invalid_url", "Missing URL", null)
                    val cookieManager = CookieManager.getInstance()
                    cookieManager.flush()
                    result.success(cookieManager.getCookie(url).orEmpty())
                }
                "clearWebViewCookies" -> {
                    CookieManager.getInstance().removeAllCookies { result.success(null) }
                }
                "setNetworkSettings" -> {
                    networkSettings = NetworkSettings(
                        useBuiltInHosts = call.argument<Boolean>("useBuiltInHosts") ?: false,
                        useDoh = call.argument<Boolean>("useDoh") ?: false,
                        dohPreset = call.argument<String>("dohPreset") ?: "alidns",
                        dohCustomUrl = call.argument<String>("dohCustomUrl").orEmpty(),
                        dohBootstrapIps = call.argument<String>("dohBootstrapIps").orEmpty(),
                        dohTimeoutSeconds = (call.argument<Int>("dohTimeoutSeconds") ?: 10).coerceIn(1, 60),
                        useEch = call.argument<Boolean>("useEch") ?: false,
                    )
                    saveNetworkSettings(networkSettings)
                    client.connectionPool.evictAll()
                    client = createClient()
                    result.success(null)
                }
                "echLogs" -> result.success(EchHttpClient.logs())
                "clearEchLogs" -> {
                    EchHttpClient.clearLogs()
                    result.success(null)
                }
                "hasCookie" -> {
                    val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("invalid_url", "Missing URL", null)
                    val name = call.argument<String>("name") ?: return@setMethodCallHandler result.error("invalid_name", "Missing cookie name", null)
                    val host = requireNotNull(android.net.Uri.parse(url).host)
                    val cookies = getSharedPreferences(preferencesName, Context.MODE_PRIVATE).getString("$cookieKey:$host", "").orEmpty()
                    result.success(cookies.split(';').any { it.trim().substringBefore('=').equals(name, true) })
                }
                "request" -> request(call, result, client)
                "download" -> download(call, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, platformChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenBrightness" -> {
                    window.attributes = window.attributes.apply { screenBrightness = (call.argument<Double>("value") ?: 1.0).toFloat().coerceIn(0.01f, 1f) }
                    result.success(null)
                }
                "screenBrightness" -> result.success(if (window.attributes.screenBrightness < 0) 1.0 else window.attributes.screenBrightness.toDouble())
                "volume" -> {
                    val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audio.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC))
                }
                "setVolume" -> {
                    val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val value = (call.argument<Double>("value") ?: 1.0).coerceIn(0.0, 1.0)
                    audio.setStreamVolume(AudioManager.STREAM_MUSIC, (audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC) * value).toInt(), 0)
                    result.success(null)
                }
                "setHideFromRecents" -> {
                    val value = call.argument<Boolean>("value") ?: false
                    getSystemService(android.app.ActivityManager::class.java).appTasks.firstOrNull()?.setExcludeFromRecents(value)
                    result.success(null)
                }
                "setEmergencyExit" -> {
                    emergencyExitEnabled = call.argument<Boolean>("value") ?: false
                    result.success(null)
                }
                "minimizeApp" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                "enterPictureInPicture" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !isInPictureInPictureMode) {
                        enterPictureInPictureMode(PictureInPictureParams.Builder().build())
                        result.success(true)
                    } else result.success(false)
                }
                "isHarmonyOs" -> result.success(isHarmonyOs())
                "androidUpdateAbi" -> result.success(androidUpdateAbi())
                "openAppLinksSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) startActivity(Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS, android.net.Uri.parse("package:$packageName")))
                    else startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, android.net.Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "authenticate" -> {
                    val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP || !keyguard.isDeviceSecure) result.success(true)
                    else {
                        authenticationResult = result
                        startActivityForResult(keyguard.createConfirmDeviceCredentialIntent(null, null), 812)
                    }
                }
                "selectDirectory" -> {
                    if (directoryResult != null) result.error("directory_picker_busy", "Directory picker is already open", null)
                    else {
                        directoryResult = result
                        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION), 813)
                    }
                }
                "exportDirectory" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val destination = call.argument<String>("destination")
                    if (sourcePath == null || destination == null) result.error("invalid_export", "Missing export path", null)
                    else Thread {
                        runCatching { copyDirectoryToTree(File(sourcePath), android.net.Uri.parse(destination)) }
                            .onSuccess { runOnUiThread { result.success(null) } }
                            .onFailure { error -> runOnUiThread { result.error("export_failed", error.message, null) } }
                    }.start()
                }
                "saveDocument" -> {
                    if (documentResult != null) result.error("document_picker_busy", "Document picker is already open", null)
                    else {
                        documentResult = result
                        documentBytes = call.argument<ByteArray>("bytes")
                        val name = call.argument<String>("name") ?: "han1me-plus-backup.zip"
                        startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).setType("application/zip").putExtra(Intent.EXTRA_TITLE, name).addCategory(Intent.CATEGORY_OPENABLE), 814)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (emergencyExitEnabled && event.keyCode == KeyEvent.KEYCODE_VOLUME_UP && event.action == KeyEvent.ACTION_DOWN) {
            val now = System.currentTimeMillis()
            volumeUpPresses = if (now - lastVolumeUpPress < 1000) volumeUpPresses + 1 else 1
            lastVolumeUpPress = now
            if (volumeUpPresses >= 3) {
                finishAndRemoveTask()
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 812) {
            authenticationResult?.success(resultCode == Activity.RESULT_OK)
            authenticationResult = null
        }
        if (requestCode == 813) {
            val uri = data?.data
            if (resultCode == Activity.RESULT_OK && uri != null) {
                val flags = (data?.flags ?: 0) and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                runCatching { contentResolver.takePersistableUriPermission(uri, flags) }
                directoryResult?.success(uri.toString())
            } else directoryResult?.success(null)
            directoryResult = null
        }
        if (requestCode == 814) {
            val uri = data?.data
            val bytes = documentBytes
            if (resultCode == Activity.RESULT_OK && uri != null && bytes != null) {
                runCatching { contentResolver.openOutputStream(uri, "w")!!.use { it.write(bytes) } }
                    .onSuccess { documentResult?.success(true) }
                    .onFailure { documentResult?.error("save_failed", it.message, null) }
            } else documentResult?.success(false)
            documentResult = null
            documentBytes = null
        }
    }

    private fun copyDirectoryToTree(source: File, treeUri: android.net.Uri) {
        require(source.isDirectory) { "Source directory does not exist" }
        val root = androidx.documentfile.provider.DocumentFile.fromTreeUri(this, treeUri) ?: error("Invalid destination directory")
        source.listFiles().orEmpty().forEach { copyToDocument(it, root) }
    }

    private fun copyToDocument(source: File, parent: androidx.documentfile.provider.DocumentFile) {
        if (source.isDirectory) {
            val target = parent.findFile(source.name)?.takeIf { it.isDirectory } ?: parent.createDirectory(source.name) ?: error("Unable to create ${source.name}")
            source.listFiles().orEmpty().forEach { copyToDocument(it, target) }
            return
        }
        parent.findFile(source.name)?.delete()
        val target = parent.createFile("application/octet-stream", source.name) ?: error("Unable to create ${source.name}")
        contentResolver.openOutputStream(target.uri, "w")!!.use { output -> FileInputStream(source).use { input -> input.copyTo(output) } }
    }

    private fun isHarmonyOs(): Boolean = listOf(
        Build.MANUFACTURER,
        Build.BRAND,
        Build.DISPLAY,
        Build.VERSION.INCREMENTAL,
    ).any { it.contains("harmony", ignoreCase = true) || it.contains("hongmeng", ignoreCase = true) }

    private fun androidUpdateAbi(): String? {
        val releaseAbis = setOf("arm64-v8a", "x86_64", "armeabi-v7a")
        return Build.SUPPORTED_64_BIT_ABIS.firstOrNull(releaseAbis::contains)
            ?: Build.SUPPORTED_ABIS.firstOrNull(releaseAbis::contains)
    }

    private fun request(call: MethodCall, result: MethodChannel.Result, httpClient: OkHttpClient) {
        val url = call.argument<String>("url") ?: return result.error("invalid_url", "Missing URL", null)
        Thread {
            try {
                val request = Request.Builder().url(url).header("User-Agent", userAgent)
                (call.argument<Map<*, *>>("headers") ?: emptyMap<Any?, Any?>()).forEach { (name, value) ->
                    request.header(name.toString(), value.toString())
                }
                if (call.argument<String>("method") in setOf("POST", "DELETE")) {
                    val form = FormBody.Builder()
                    (call.argument<Map<*, *>>("data") ?: emptyMap<Any?, Any?>()).forEach { (name, value) -> form.add(name.toString(), value.toString()) }
                    val body = if (call.argument<Boolean>("json") == true) {
                        request.header("Content-Type", "application/json")
                        JSONObject((call.argument<Map<*, *>>("data") ?: emptyMap<Any?, Any?>()).mapKeys { it.key.toString() }).toString().toRequestBody("application/json".toMediaType())
                    } else form.build()
                    if (call.argument<String>("method") == "DELETE") request.delete(body) else request.post(body)
                }
                val builtRequest = request.build()
                val echResponse = nativeEchRequest(builtRequest)
                if (echResponse != null) {
                    val payload = mapOf(
                        "statusCode" to echResponse.statusCode,
                        "body" to decodeResponse(echResponse.body, call.argument<String>("responseCharset")),
                        "url" to echResponse.url,
                        "headers" to echResponse.headers,
                    )
                    runOnUiThread { result.success(payload) }
                    return@Thread
                }
                httpClient.newCall(builtRequest).execute().use {
                    val payload = mapOf(
                        "statusCode" to it.code,
                        "body" to decodeResponse(it.body?.bytes() ?: byteArrayOf(), call.argument<String>("responseCharset")),
                        "url" to it.request.url.toString(),
                        "headers" to it.headers.toMultimap(),
                    )
                    runOnUiThread { result.success(payload) }
                }
            } catch (error: Exception) {
                runOnUiThread { result.error("request_failed", error.message, null) }
            }
        }.start()
    }

    private fun nativeEchRequest(request: Request): EchResponse? {
        val settings = networkSettings
        if (!settings.useEch || !EchHttpClient.isLoaded || request.url.host !in hanimeHosts || request.method !in setOf("GET", "POST", "DELETE")) return null
        return runCatching {
            val headers = request.headers.toMultimap().mapValues { it.value.joinToString(", ") }.toMutableMap()
            cookieJar.loadForRequest(request.url).takeIf { it.isNotEmpty() }?.let { cookies ->
                headers["Cookie"] = cookies.joinToString("; ") { "${it.name}=${it.value}" }
            }
            val response = EchHttpClient.execute(request.method, request.url.toString(), headers, request.body?.let { body -> okio.Buffer().use { buffer -> body.writeTo(buffer); buffer.readByteArray() } }, settings.echDohUrl, settings.echDohResolve)
            EchHttpClient.addLog("${request.url.host}: ${response.echStatus}")
            response.headers.entries
                .filter { it.key.equals("Set-Cookie", true) }
                .flatMap { it.value }
                .mapNotNull { Cookie.parse(request.url, it) }
                .takeIf { it.isNotEmpty() }
                ?.let { cookieJar.saveFromResponse(request.url, it) }
            response.takeUnless { it.statusCode == 403 && it.headers.any { header -> header.key.equals("cf-mitigated", true) } }
        }.onFailure { EchHttpClient.addLog("${request.url.host}: ${it.message ?: "native request failed"}") }.getOrNull()
    }

    private fun decodeResponse(bytes: ByteArray, responseCharset: String?): String = bytes.toString(responseCharset?.let(Charset::forName) ?: Charsets.UTF_8)

    private fun download(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url") ?: return result.error("invalid_url", "Missing URL", null)
        val path = call.argument<String>("path") ?: return result.error("invalid_path", "Missing destination path", null)
        Thread {
            try {
                val request = Request.Builder()
                    .url(url)
                    .header("User-Agent", userAgent)
                    .header("Referer", "https://hanimeone.me/")
                    .header("Accept", "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8")
                    .build()
                nativeEchRequest(request)?.let { response ->
                    if (response.statusCode !in 200..299) throw IllegalStateException("Image request failed: HTTP ${response.statusCode}")
                    val target = File(path)
                    target.parentFile?.mkdirs()
                    target.writeBytes(response.body)
                    if (!target.exists() || target.length() == 0L) throw IllegalStateException("Image response was empty")
                    runOnUiThread { result.success(null) }
                    return@Thread
                }
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) throw IllegalStateException("Image request failed: HTTP ${response.code}")
                    val target = File(path)
                    target.parentFile?.mkdirs()
                    response.body?.byteStream()?.use { input -> target.outputStream().use { output -> input.copyTo(output) } }
                    if (!target.exists() || target.length() == 0L) throw IllegalStateException("Image response was empty")
                }
                runOnUiThread { result.success(null) }
            } catch (error: Exception) {
                runOnUiThread { result.error("download_failed", error.message, null) }
            }
        }.start()
    }

    private fun persistedCookies(url: okhttp3.HttpUrl): List<Cookie> = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        .getString("$cookieKey:${url.host}", "")
        .orEmpty()
        .split(';')
        .mapNotNull { value ->
            val pair = value.trim()
            val index = pair.indexOf('=')
            if (index <= 0) null else Cookie.parse(url, pair)
        }

    private fun loadNetworkSettings(): NetworkSettings {
        val preferences = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        return NetworkSettings(
            useBuiltInHosts = preferences.getBoolean(useBuiltInHostsKey, false),
            useDoh = preferences.getBoolean(useDohKey, false),
            dohPreset = preferences.getString(dohPresetKey, "alidns").orEmpty(),
            dohCustomUrl = preferences.getString(dohCustomUrlKey, "").orEmpty(),
            dohBootstrapIps = preferences.getString(dohBootstrapIpsKey, "").orEmpty(),
            dohTimeoutSeconds = preferences.getInt(dohTimeoutSecondsKey, 10).coerceIn(1, 60),
            useEch = preferences.getBoolean(useEchKey, false),
        )
    }

    private fun saveNetworkSettings(settings: NetworkSettings) {
        getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit()
            .putBoolean(useBuiltInHostsKey, settings.useBuiltInHosts)
            .putBoolean(useDohKey, settings.useDoh)
            .putString(dohPresetKey, settings.dohPreset)
            .putString(dohCustomUrlKey, settings.dohCustomUrl)
            .putString(dohBootstrapIpsKey, settings.dohBootstrapIps)
            .putInt(dohTimeoutSecondsKey, settings.dohTimeoutSeconds)
            .putBoolean(useEchKey, settings.useEch)
            .apply()
    }

}

private data class NetworkSettings(
    val useBuiltInHosts: Boolean = false,
    val useDoh: Boolean = false,
    val dohPreset: String = "alidns",
    val dohCustomUrl: String = "",
    val dohBootstrapIps: String = "",
    val dohTimeoutSeconds: Int = 10,
    val useEch: Boolean = false,
)

private class ConfigurableDns(private val settings: () -> NetworkSettings) : Dns {
    override fun lookup(hostname: String): List<java.net.InetAddress> {
        val current = settings()
        if (current.useBuiltInHosts && !current.useDoh && hostname in hosts) {
            return addresses.map { address(hostname, it) }
        }
        val dohUrl = current.dohUrl ?: return Dns.SYSTEM.lookup(hostname)
        return doh(current, dohUrl).lookup(hostname)
    }

    @Volatile private var cachedSettings: NetworkSettings? = null
    @Volatile private var cachedDns: Dns? = null

    private fun doh(settings: NetworkSettings, url: String): Dns {
        cachedDns?.takeIf { cachedSettings == settings }?.let { return it }
        synchronized(this) {
            cachedDns?.takeIf { cachedSettings == settings }?.let { return it }
            val bootstrapIps = settings.bootstrapIps.mapNotNull { runCatching { InetAddress.getByName(it) }.getOrNull() }
            val client = OkHttpClient.Builder()
                .connectTimeout(settings.dohTimeoutSeconds.toLong(), TimeUnit.SECONDS)
                .readTimeout(settings.dohTimeoutSeconds.toLong(), TimeUnit.SECONDS)
                .build()
            val builder = DnsOverHttps.Builder()
                .client(client)
                .url(url.toHttpUrl())
                .includeIPv6(true)
                .post(false)
                .resolvePrivateAddresses(true)
                .resolvePublicAddresses(true)
            if (bootstrapIps.isNotEmpty()) builder.bootstrapDnsHosts(bootstrapIps)
            return builder.build().also {
                cachedSettings = settings
                cachedDns = it
            }
        }
    }

    private val NetworkSettings.dohUrl: String?
        get() = if (!useDoh) null else when (dohPreset) {
            "alidns" -> "https://dns.alidns.com/dns-query"
            "dnspod" -> "https://doh.pub/dns-query"
            "cloudflare" -> "https://cloudflare-dns.com/dns-query"
            "custom" -> dohCustomUrl.trim().takeIf { it.isNotEmpty() }
            else -> "https://dns.alidns.com/dns-query"
        }

    private val NetworkSettings.bootstrapIps: List<String>
        get() = dohBootstrapIps.split(',', '\n', ';', ' ')
            .map(String::trim)
            .filter(String::isNotEmpty)
            .distinct()
            .ifEmpty {
                when (dohPreset) {
                    "alidns" -> listOf("223.5.5.5", "223.6.6.6")
                    "dnspod" -> listOf("1.12.12.12", "120.53.53.53")
                    "cloudflare" -> listOf("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001")
                    else -> emptyList()
                }
            }

    private companion object {
        val hosts = setOf("hanime1.me", "hanime1.com", "hanimeone.me", "javchu.com")
        val addresses = listOf(
            "172.64.229.154", "162.159.0.1", "108.162.192.1", "172.64.33.1", "104.19.0.1",
            "2606:4700:3035::ac43:bb8d", "2606:4700:3030::6815:746", "2606:4700:3030::6815:714",
        )

        fun address(hostname: String, value: String) = InetAddress.getByAddress(hostname, InetAddress.getByName(value).address)
    }
}

private val NetworkSettings.echDohUrl: String
    get() = "https://0kbpekmcr1.cloudflare-gateway.com/dns-query"

private val NetworkSettings.echDohResolve: String
    get() = ""

private class CloudflareInterceptor(private val context: Context) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val response = chain.proceed(request)
        if (response.code != 403 || response.header("cf-mitigated")?.equals("challenge", true) != true) return response
        response.close()
        val latch = CountDownLatch(1)
        CloudflareActivity.onFinished = { latch.countDown() }
        try {
            context.startActivity(
                android.content.Intent(context, CloudflareActivity::class.java)
                    .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    .putExtra(CloudflareActivity.requestUrlKey, request.url.toString()),
            )
            latch.await()
        } catch (_: Exception) {
            CloudflareActivity.onFinished?.invoke()
        }
        return chain.proceed(request)
    }
}
