import Flutter
import WebKit

final class HttpMethodChannelHandler {
    static let channelName = "com.liar.han1meplus/http"
    private let client = Han1meHttpClient.shared

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "saveCookies":
            guard
                let args = call.arguments as? [String: Any],
                let url = args["url"] as? String
            else {
                result(FlutterError(code: "invalid_url", message: "Missing URL", details: nil))
                return
            }
            client.saveCookies(args["cookies"] as? String ?? "", url: url)
            result(nil)

        case "clearCookies":
            guard
                let args = call.arguments as? [String: Any],
                let url = args["url"] as? String
            else {
                result(FlutterError(code: "invalid_url", message: "Missing URL", details: nil))
                return
            }
            client.clearCookies(url: url)
            result(nil)

        case "webViewCookies":
            guard
                let args = call.arguments as? [String: Any],
                let url = args["url"] as? String
            else {
                result(FlutterError(code: "invalid_url", message: "Missing URL", details: nil))
                return
            }
            webViewCookies(url: url, result: result)

        case "clearWebViewCookies":
            clearWebViewCookies(result: result)

        case "setNetworkSettings":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "invalid_args", message: "Missing settings", details: nil))
                return
            }
            let settings = Han1meNetworkSettings(
                useBuiltInHosts: args["useBuiltInHosts"] as? Bool ?? false,
                useDoh: args["useDoh"] as? Bool ?? false,
                dohPreset: args["dohPreset"] as? String ?? "alidns",
                dohCustomUrl: args["dohCustomUrl"] as? String ?? "",
                dohBootstrapIps: args["dohBootstrapIps"] as? String ?? "",
                dohTimeoutSeconds: min(max(args["dohTimeoutSeconds"] as? Int ?? 10, 1), 60)
            )
            client.setNetworkSettings(settings)
            result(nil)

        case "hasCookie":
            guard
                let args = call.arguments as? [String: Any],
                let url = args["url"] as? String,
                let name = args["name"] as? String
            else {
                result(FlutterError(code: "invalid_args", message: "Missing cookie args", details: nil))
                return
            }
            result(client.hasCookie(url: url, name: name))

        case "request":
            guard
                let args = call.arguments as? [String: Any],
                let url = args["url"] as? String
            else {
                result(FlutterError(code: "invalid_url", message: "Missing URL", details: nil))
                return
            }
            client.request(
                url: url,
                method: args["method"] as? String ?? "GET",
                data: args["data"] as? [String: String],
                headers: args["headers"] as? [String: String],
                responseCharset: args["responseCharset"] as? String,
                json: args["json"] as? Bool ?? false
            ) { response in
                DispatchQueue.main.async {
                    switch response {
                    case .success(let payload):
                        result([
                            "statusCode": payload.statusCode,
                            "body": payload.body,
                            "url": payload.url,
                            "headers": payload.headers,
                        ])
                    case .failure(let error):
                        result(FlutterError(code: "request_failed", message: error.localizedDescription, details: nil))
                    }
                }
            }

        case "download":
            guard
                let args = call.arguments as? [String: Any],
                let url = args["url"] as? String,
                let path = args["path"] as? String
            else {
                result(FlutterError(code: "invalid_args", message: "Missing download args", details: nil))
                return
            }
            client.download(url: url, path: path) { response in
                DispatchQueue.main.async {
                    switch response {
                    case .success:
                        result(nil)
                    case .failure(let error):
                        result(FlutterError(code: "download_failed", message: error.localizedDescription, details: nil))
                    }
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func webViewCookies(url: String, result: @escaping FlutterResult) {
        guard let host = URL(string: url)?.host else {
            result(FlutterError(code: "invalid_url", message: "Missing URL", details: nil))
            return
        }
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            let header = cookies
                .filter { cookie in
                    let domain = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
                    return host == domain || host.hasSuffix(".\(domain)")
                }
                .map { "\($0.name)=\($0.value)" }
                .joined(separator: "; ")
            DispatchQueue.main.async { result(header) }
        }
    }

    private func clearWebViewCookies(result: @escaping FlutterResult) {
        let store = WKWebsiteDataStore.default().httpCookieStore
        store.getAllCookies { cookies in
            let group = DispatchGroup()
            for cookie in cookies {
                group.enter()
                store.delete(cookie) { group.leave() }
            }
            group.notify(queue: .main) {
                if let sharedCookies = HTTPCookieStorage.shared.cookies {
                    for cookie in sharedCookies {
                        HTTPCookieStorage.shared.deleteCookie(cookie)
                    }
                }
                result(nil)
            }
        }
    }
}
