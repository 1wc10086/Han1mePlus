package com.liar.han1meplus

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient

class CloudflareActivity : Activity() {
    companion object {
        const val requestUrlKey = "request_url"
        var onFinished: (() -> Unit)? = null
    }

    private val userAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36"

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val url = intent.getStringExtra(requestUrlKey) ?: return finish()
        val webView = WebView(this)
        setContentView(webView)
        val cookies = CookieManager.getInstance().apply {
            setAcceptCookie(true)
            setAcceptThirdPartyCookies(webView, true)
        }
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            javaScriptCanOpenWindowsAutomatically = true
            userAgentString = userAgent
        }
        webView.webViewClient = object : WebViewClient() {}
        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, progress: Int) {
                if (progress < 90) return
                view?.postDelayed({
                    view.evaluateJavascript("document.head.innerHTML") { head ->
                        if (head.contains("#challenge-form") || head.contains("#challenge-success-text") || head.contains("#challenge-error-text")) return@evaluateJavascript
                        val cookie = cookies.getCookie(url).orEmpty()
                        if (!cookie.contains("cf_clearance=")) return@evaluateJavascript
                        cookies.flush()
                        MainActivity.saveCookies(this@CloudflareActivity, cookie, url)
                        onFinished?.invoke()
                        onFinished = null
                        finish()
                    }
                }, 1000)
            }
        }
        webView.loadUrl(url)
    }

    override fun onDestroy() {
        onFinished?.invoke()
        onFinished = null
        super.onDestroy()
    }
}
