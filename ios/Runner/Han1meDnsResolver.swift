import Foundation

enum Han1meDnsResolver {
    private static var cachedSettings: Han1meNetworkSettings?
    private static var cachedResolverKey: String?

    static func resolve(hostname: String, settings: Han1meNetworkSettings) throws -> [String]? {
        if settings.useBuiltInHosts && !settings.useDoh && Han1meHttpStore.hanimeHosts.contains(hostname) {
            return Han1meHttpStore.builtInAddresses
        }
        guard let dohUrl = settings.dohUrl else { return nil }
        let cacheKey = "\(dohUrl)|\(settings.dohBootstrapIps)|\(settings.dohTimeoutSeconds)"
        if cachedSettings == settings, cachedResolverKey == cacheKey {
            return try queryDoh(hostname: hostname, dohUrl: dohUrl, settings: settings)
        }
        cachedSettings = settings
        cachedResolverKey = cacheKey
        return try queryDoh(hostname: hostname, dohUrl: dohUrl, settings: settings)
    }

    private static func queryDoh(hostname: String, dohUrl: String, settings: Han1meNetworkSettings) throws -> [String] {
        guard let template = URL(string: dohUrl) else { throw DnsError.invalidUrl }
        let hostHeader = template.host ?? ""
        let pathBase = template.path.hasSuffix("/") ? String(template.path.dropLast()) : template.path
        let queryPath = pathBase.isEmpty ? "/dns-query" : pathBase
        let query = "name=\(hostname.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hostname)&type=A"

        let bootstrapTargets: [URL] = {
            if settings.bootstrapIps.isEmpty, let direct = URL(string: "\(template.scheme ?? "https")://\(hostHeader)\(queryPath)?\(query)") {
                return [direct]
            }
            return settings.bootstrapIps.compactMap { ip in
                let formatted = ip.contains(":") ? "[\(ip)]" : ip
                return URL(string: "\(template.scheme ?? "https")://\(formatted)\(queryPath)?\(query)")
            }
        }()

        var lastError: Error = DnsError.emptyAnswer
        for target in bootstrapTargets {
            do {
                var request = URLRequest(url: target)
                request.httpMethod = "GET"
                request.timeoutInterval = TimeInterval(settings.dohTimeoutSeconds)
                request.setValue("application/dns-json", forHTTPHeaderField: "Accept")
                if !hostHeader.isEmpty { request.setValue(hostHeader, forHTTPHeaderField: "Host") }

                let (data, response) = try URLSession.shared.syncData(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { continue }
                let ips = parseDnsJson(data)
                if !ips.isEmpty { return ips }
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private static func parseDnsJson(_ data: Data) -> [String] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let answers = json["Answer"] as? [[String: Any]]
        else { return [] }
        return answers.compactMap { answer in
            guard let type = answer["type"] as? Int, type == 1, let value = answer["data"] as? String else { return nil }
            return value
        }
    }

    enum DnsError: LocalizedError {
        case invalidUrl
        case emptyAnswer

        var errorDescription: String? {
            switch self {
            case .invalidUrl: return "Invalid DoH URL"
            case .emptyAnswer: return "DoH returned no addresses"
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
                result = .failure(Han1meDnsResolver.DnsError.emptyAnswer)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        case .none: throw Han1meDnsResolver.DnsError.emptyAnswer
        }
    }
}
