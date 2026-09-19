import Foundation

struct Han1meHttpResponse {
    let statusCode: Int
    let body: String
    let url: String
    let headers: [String: [String]]
}

final class Han1meSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    var trustAllCertificates = false

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard trustAllCertificates,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

final class Han1meHttpClient {
    static let shared = Han1meHttpClient()

    let userAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36"

    private let delegate = Han1meSessionDelegate()
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }()

    private var responseCookies: [String: [String: String]] = [:]
    private var networkSettings = Han1meHttpStore.loadNetworkSettings()
    private let queue = DispatchQueue(label: "com.liar.han1meplus.http", qos: .userInitiated)

    func setNetworkSettings(_ settings: Han1meNetworkSettings) {
        queue.sync {
            networkSettings = settings
            Han1meHttpStore.saveNetworkSettings(settings)
        }
    }

    func saveCookies(_ cookies: String, url: String) {
        queue.sync { Han1meHttpStore.saveCookies(cookies, url: url) }
    }

    func clearCookies(url: String) {
        queue.sync {
            Han1meHttpStore.clearCookies(url: url)
            if let host = URL(string: url)?.host {
                responseCookies.removeValue(forKey: host)
            }
        }
    }

    func hasCookie(url: String, name: String) -> Bool {
        queue.sync { Han1meHttpStore.hasCookie(url: url, name: name) }
    }

    func request(
        url: String,
        method: String = "GET",
        data: [String: String]? = nil,
        headers: [String: String]? = nil,
        responseCharset: String? = nil,
        json: Bool = false,
        completion: @escaping (Result<Han1meHttpResponse, Error>) -> Void
    ) {
        queue.async {
            do {
                let response = try self.performRequest(
                    urlString: url,
                    method: method,
                    data: data,
                    headers: headers,
                    responseCharset: responseCharset,
                    json: json,
                    allowCloudflareRetry: true
                )
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func download(url: String, path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async {
            do {
                let bytes = try self.rawBody(
                    urlString: url,
                    headers: [
                        "Referer": "https://hanimeone.me/",
                        "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
                    ]
                )
                guard !bytes.isEmpty else { throw HttpError.downloadFailed("Image response was empty") }
                let fileURL = URL(fileURLWithPath: path)
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try bytes.write(to: fileURL, options: .atomic)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func rawBody(urlString: String, headers: [String: String], allowCloudflareRetry: Bool = true) throws -> Data {
        let settings = networkSettings
        guard let originalURL = URL(string: urlString), let host = originalURL.host else {
            throw HttpError.invalidUrl
        }
        let resolved = try Han1meDnsResolver.resolve(hostname: host, settings: settings)
        let targets = resolved ?? [host]
        var lastError: Error = HttpError.requestFailed("Download failed")
        for target in targets {
            do {
                let requestURL = rewrite(url: originalURL, host: host, target: target)
                delegate.trustAllCertificates = resolved != nil
                var request = URLRequest(url: requestURL)
                request.httpMethod = "GET"
                request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
                if resolved != nil { request.setValue(host, forHTTPHeaderField: "Host") }
                for (name, value) in headers { request.setValue(value, forHTTPHeaderField: name) }
                attachCookies(to: &request, host: host)
                let (data, response) = try session.syncData(for: request)
                guard let http = response as? HTTPURLResponse else { throw HttpError.requestFailed("Invalid response") }
                storeResponseCookies(from: http, host: host, url: requestURL.absoluteString)
                if http.statusCode == 403,
                   http.value(forHTTPHeaderField: "cf-mitigated")?.caseInsensitiveCompare("challenge") == .orderedSame,
                   allowCloudflareRetry {
                    CloudflareViewController.waitForChallenge(url: originalURL.absoluteString)
                    return try rawBody(urlString: urlString, headers: headers, allowCloudflareRetry: false)
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw HttpError.downloadFailed("Image request failed: HTTP \(http.statusCode)")
                }
                return data
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func performRequest(
        urlString: String,
        method: String,
        data: [String: String]?,
        headers: [String: String]?,
        responseCharset: String? = nil,
        json: Bool,
        allowCloudflareRetry: Bool
    ) throws -> Han1meHttpResponse {
        let settings = networkSettings
        guard let originalURL = URL(string: urlString), let host = originalURL.host else {
            throw HttpError.invalidUrl
        }
        let resolved = try Han1meDnsResolver.resolve(hostname: host, settings: settings)
        let targets = resolved ?? [host]
        var lastError: Error = HttpError.requestFailed("Request failed")

        for target in targets {
            do {
                let requestURL = rewrite(url: originalURL, host: host, target: target)
                delegate.trustAllCertificates = resolved != nil
                var request = URLRequest(url: requestURL)
                request.httpMethod = method
                request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
                if resolved != nil { request.setValue(host, forHTTPHeaderField: "Host") }
                headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
                attachCookies(to: &request, host: host)

                if method == "POST" || method == "DELETE" {
                    if json, let data {
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.httpBody = try JSONSerialization.data(withJSONObject: data)
                    } else if let data {
                        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        request.httpBody = formBody(data)
                    }
                }

                let (bodyData, response) = try session.syncData(for: request)
                guard let http = response as? HTTPURLResponse else { throw HttpError.requestFailed("Invalid response") }
                storeResponseCookies(from: http, host: host, url: http.url?.absoluteString ?? requestURL.absoluteString)

                if http.statusCode == 403,
                   http.value(forHTTPHeaderField: "cf-mitigated")?.caseInsensitiveCompare("challenge") == .orderedSame,
                   allowCloudflareRetry {
                    CloudflareViewController.waitForChallenge(url: originalURL.absoluteString)
                    return try performRequest(
                        urlString: urlString,
                        method: method,
                        data: data,
                        headers: headers,
                        responseCharset: responseCharset,
                        json: json,
                        allowCloudflareRetry: false
                    )
                }

                let body = decodeBody(bodyData, charsetName: responseCharset)
                return Han1meHttpResponse(
                    statusCode: http.statusCode,
                    body: body,
                    url: http.url?.absoluteString ?? requestURL.absoluteString,
                    headers: multimapHeaders(http)
                )
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func rewrite(url: URL, host: String, target: String) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if target.contains(":") && !target.hasPrefix("[") {
            components?.host = "[\(target)]"
        } else {
            components?.host = target
        }
        return components?.url ?? url
    }

    private func attachCookies(to request: inout URLRequest, host: String) {
        var map: [String: String] = [:]
        for part in Han1meHttpStore.readCookies(host: host).split(separator: ";") {
            let pair = part.trimmingCharacters(in: .whitespaces)
            guard let index = pair.firstIndex(of: "=") else { continue }
            let name = String(pair[..<index]).trimmingCharacters(in: .whitespaces)
            let value = String(pair[pair.index(after: index)...]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { map[name] = value }
        }
        responseCookies[host, default: [:]].forEach { map[$0.key] = $0.value }
        let header = map.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
        if !header.isEmpty { request.setValue(header, forHTTPHeaderField: "Cookie") }
    }

    private func storeResponseCookies(from response: HTTPURLResponse, host: String, url: String) {
        guard let fields = response.allHeaderFields as? [String: Any] else { return }
        var setCookies: [String] = []
        for (key, value) in fields where key.lowercased() == "set-cookie" {
            if let line = value as? String {
                setCookies.append(line.components(separatedBy: ";").first ?? line)
            }
        }
        guard !setCookies.isEmpty else { return }
        let merged = setCookies.joined(separator: "; ")
        var map = responseCookies[host, default: [:]]
        for part in merged.split(separator: ";") {
            let pair = part.trimmingCharacters(in: .whitespaces)
            guard let index = pair.firstIndex(of: "=") else { continue }
            let name = String(pair[..<index]).trimmingCharacters(in: .whitespaces)
            let value = String(pair[pair.index(after: index)...]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { map[name] = value }
        }
        responseCookies[host] = map
        Han1meHttpStore.saveCookies(merged, url: url)
    }

    private func formBody(_ data: [String: String]) -> Data? {
        var components = URLComponents()
        components.queryItems = data.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    private func decodeBody(_ data: Data, charsetName: String?) -> String {
        if let charsetName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(charsetName as CFString)
            if encoding != kCFStringEncodingInvalidId {
                let nsEncoding = CFStringConvertEncodingToNSStringEncoding(encoding)
                if let string = String(data: data, encoding: String.Encoding(rawValue: nsEncoding)) {
                    return string
                }
            }
        }
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        return String(decoding: data, as: UTF8.self)
    }

    private func multimapHeaders(_ response: HTTPURLResponse) -> [String: [String]] {
        var map: [String: [String]] = [:]
        for (key, value) in response.allHeaderFields {
            let name = String(describing: key)
            let text = String(describing: value)
            map[name, default: []].append(text)
        }
        return map
    }

    enum HttpError: LocalizedError {
        case invalidUrl
        case requestFailed(String)
        case downloadFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidUrl: return "Missing URL"
            case .requestFailed(let message): return message
            case .downloadFailed(let message): return message
            }
        }
    }
}

private extension URLSession {
    func syncData(for request: URLRequest) throws -> (Data, URLResponse) {
        var result: Result<(Data, URLResponse), Error>?
        let semaphore = DispatchSemaphore(value: 0)
        let task = dataTask(with: request) { data, response, error in
            if let error {
                result = .failure(error)
            } else if let data, let response {
                result = .success((data, response))
            } else {
                result = .failure(Han1meHttpClient.HttpError.requestFailed("Empty response"))
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        case .none: throw Han1meHttpClient.HttpError.requestFailed("Empty response")
        }
    }
}
