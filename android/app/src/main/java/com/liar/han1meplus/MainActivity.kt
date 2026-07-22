package com.liar.han1meplus

import android.content.Context
import android.content.Intent
import android.app.KeyguardManager
import android.app.Activity
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
import okhttp3.FormBody
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import java.util.concurrent.CountDownLatch

class MainActivity : FlutterActivity() {
    companion object {
        const val preferencesName = "han1meplus_http"
        const val cookieKey = "cookies"

        fun saveCookies(context: Context, cookies: String, url: String) {
            val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            val key = "$cookieKey:${requireNotNull(android.net.Uri.parse(url).host)}"
            val current = preferences.getString(key, "").orEmpty()
            preferences.edit().putString(key, mergeCookies(current, cookies)).commit()
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
    }

    private val channelName = "com.liar.han1meplus/http"
    private val platformChannelName = "com.liar.han1meplus/platform"
    private val userAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36"
    private val responseCookies = mutableMapOf<String, List<Cookie>>()
    private var emergencyExitEnabled = false
    private var volumeUpPresses = 0
    private var lastVolumeUpPress = 0L
    private var authenticationResult: MethodChannel.Result? = null
    private val client by lazy {
        OkHttpClient.Builder().addInterceptor(CloudflareInterceptor(applicationContext)).cookieJar(object : CookieJar {
            override fun loadForRequest(url: okhttp3.HttpUrl): List<Cookie> =
                (responseCookies[url.host].orEmpty() + persistedCookies(url.host))
                    .associateBy { it.name }
                    .values
                    .toList()

            override fun saveFromResponse(url: okhttp3.HttpUrl, cookies: List<Cookie>) {
                responseCookies[url.host] = cookies
            }
        }).build()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                        responseCookies.remove(host)
                        getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit().remove("$cookieKey:$host").apply()
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
                "hasCookie" -> {
                    val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("invalid_url", "Missing URL", null)
                    val name = call.argument<String>("name") ?: return@setMethodCallHandler result.error("invalid_name", "Missing cookie name", null)
                    val host = requireNotNull(android.net.Uri.parse(url).host)
                    val cookies = getSharedPreferences(preferencesName, Context.MODE_PRIVATE).getString("$cookieKey:$host", "").orEmpty()
                    result.success(cookies.split(';').any { it.trim().substringBefore('=').equals(name, true) })
                }
                "request" -> request(call, result)
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
                "openAppLinksSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) startActivity(Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS, android.net.Uri.parse("package:$packageName")))
                    else startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, android.net.Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "authenticate" -> {
                    val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP || !keyguard.isDeviceSecure) result.success(false)
                    else {
                        authenticationResult = result
                        startActivityForResult(keyguard.createConfirmDeviceCredentialIntent(null, null), 812)
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
    }

    private fun request(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url") ?: return result.error("invalid_url", "Missing URL", null)
        Thread {
            try {
                val request = Request.Builder().url(url).header("User-Agent", userAgent)
                if (call.argument<String>("method") == "POST") {
                    val form = FormBody.Builder()
                    (call.argument<Map<*, *>>("data") ?: emptyMap<Any?, Any?>()).forEach { (name, value) -> form.add(name.toString(), value.toString()) }
                    request.post(form.build())
                }
                client.newCall(request.build()).execute().use {
                    val payload = mapOf(
                        "statusCode" to it.code,
                        "body" to (it.body?.string() ?: ""),
                        "headers" to it.headers.toMultimap(),
                    )
                    runOnUiThread { result.success(payload) }
                }
            } catch (error: Exception) {
                runOnUiThread { result.error("request_failed", error.message, null) }
            }
        }.start()
    }

    private fun persistedCookies(host: String): List<Cookie> = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        .getString("$cookieKey:$host", "")
        .orEmpty()
        .split(';')
        .mapNotNull { value ->
            val pair = value.trim()
            val index = pair.indexOf('=')
            if (index <= 0) null else runCatching {
                Cookie.Builder()
                    .domain(host)
                    .name(pair.substring(0, index).trim())
                    .value(pair.substring(index + 1).trim())
                    .build()
            }.getOrNull()
        }

}

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
