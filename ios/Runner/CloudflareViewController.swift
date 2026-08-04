import UIKit
import WebKit

final class CloudflareViewController: UIViewController {
    static let requestUrlKey = "request_url"
    static var onFinished: (() -> Void)?

    private let userAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36"
    private var webView: WKWebView!
    private var pollTimer: Timer?
    private var initialClearance: String?
    private var completed = false
    private let requestUrl: String

    init(requestUrl: String) {
        self.requestUrl = requestUrl
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.customUserAgent = userAgent
        view.addSubview(webView)

        let cookieStore = config.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { [weak self] cookies in
            guard let self else { return }
            self.initialClearance = Self.clearanceCookie(from: cookies, url: self.requestUrl)
            DispatchQueue.main.async {
                if let url = URL(string: self.requestUrl) {
                    self.webView.load(URLRequest(url: url))
                }
                self.startPolling()
            }
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClearance()
        }
    }

    private func checkClearance() {
        guard !completed else { return }
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self, !self.completed else { return }
            let current = Self.clearanceCookie(from: cookies, url: self.requestUrl)
            guard let current, current != self.initialClearance else { return }
            self.completed = true
            let header = cookies
                .filter { cookie in
                    guard let host = URL(string: self.requestUrl)?.host else { return false }
                    return Self.cookieMatches(cookie, host: host)
                }
                .map { "\($0.name)=\($0.value)" }
                .joined(separator: "; ")
            Han1meHttpStore.saveCookies(header, url: self.requestUrl)
            DispatchQueue.main.async {
                self.finish()
            }
        }
    }

    private func finish() {
        pollTimer?.invalidate()
        pollTimer = nil
        dismiss(animated: true) {
            CloudflareViewController.onFinished?()
            CloudflareViewController.onFinished = nil
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pollTimer?.invalidate()
        if !completed {
            CloudflareViewController.onFinished?()
            CloudflareViewController.onFinished = nil
        }
    }

    static func present(for url: String) {
        DispatchQueue.main.async {
            guard let presenter = topViewController() else {
                onFinished?()
                onFinished = nil
                return
            }
            presenter.present(CloudflareViewController(requestUrl: url), animated: true)
        }
    }

    static func waitForChallenge(url: String) {
        let semaphore = DispatchSemaphore(value: 0)
        onFinished = { semaphore.signal() }
        present(for: url)
        semaphore.wait()
    }

    private static func clearanceCookie(from cookies: [HTTPCookie], url: String) -> String? {
        guard let host = URL(string: url)?.host else { return nil }
        for cookie in cookies where cookieMatches(cookie, host: host) {
            if cookie.name.caseInsensitiveCompare("cf_clearance") == .orderedSame {
                return "\(cookie.name)=\(cookie.value)"
            }
        }
        return nil
    }

    private static func cookieMatches(_ cookie: HTTPCookie, host: String) -> Bool {
        let domain = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
        return host == domain || host.hasSuffix(".\(domain)")
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let root = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}
