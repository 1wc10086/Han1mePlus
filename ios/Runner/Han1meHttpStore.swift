import Foundation

enum Han1meHttpStore {
    static let preferencesName = "han1meplus_http"
    static let cookieKey = "cookies"
    static let useBuiltInHostsKey = "use_built_in_hosts"
    static let useDohKey = "use_doh"
    static let dohPresetKey = "doh_preset"
    static let dohCustomUrlKey = "doh_custom_url"
    static let dohBootstrapIpsKey = "doh_bootstrap_ips"
    static let dohTimeoutSecondsKey = "doh_timeout_seconds"

    static let hanimeHosts: Set<String> = [
        "hanime1.me", "hanime1.com", "hanimeone.me", "javchu.com",
    ]

    static let builtInAddresses: [String] = [
        "172.64.229.154", "162.159.0.1", "108.162.192.1", "172.64.33.1", "104.19.0.1",
        "2606:4700:3035::ac43:bb8d", "2606:4700:3030::6815:746", "2606:4700:3030::6815:714",
    ]

    private static var defaults: UserDefaults { .standard }

    static func cookieHosts(for host: String) -> Set<String> {
        hanimeHosts.contains(host) ? hanimeHosts : [host]
    }

    static func mergeCookies(_ current: String, _ next: String) -> String {
        var map: [String: String] = [:]
        for raw in (current + ";" + next).split(separator: ";") {
            let pair = raw.trimmingCharacters(in: .whitespaces)
            guard let index = pair.firstIndex(of: "=") else { continue }
            let name = String(pair[..<index]).trimmingCharacters(in: .whitespaces)
            let value = String(pair[pair.index(after: index)...]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { map[name] = value }
        }
        return map.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    }

    static func saveCookies(_ cookies: String, url: String) {
        guard let host = URL(string: url)?.host else { return }
        for target in cookieHosts(for: host) {
            let key = "\(cookieKey):\(target)"
            let current = defaults.string(forKey: key) ?? ""
            defaults.set(mergeCookies(current, cookies), forKey: key)
        }
    }

    static func readCookies(host: String) -> String {
        defaults.string(forKey: "\(cookieKey):\(host)") ?? ""
    }

    static func clearCookies(url: String) {
        guard let host = URL(string: url)?.host else { return }
        for target in cookieHosts(for: host) {
            defaults.removeObject(forKey: "\(cookieKey):\(target)")
        }
    }

    static func hasCookie(url: String, name: String) -> Bool {
        guard let host = URL(string: url)?.host else { return false }
        let cookies = readCookies(host: host)
        return cookies.split(separator: ";").contains { part in
            part.trimmingCharacters(in: .whitespaces)
                .split(separator: "=", maxSplits: 1)
                .first?
                .trimmingCharacters(in: .whitespaces)
                .caseInsensitiveCompare(name) == .orderedSame
        }
    }

    static func loadNetworkSettings() -> Han1meNetworkSettings {
        Han1meNetworkSettings(
            useBuiltInHosts: defaults.bool(forKey: useBuiltInHostsKey),
            useDoh: defaults.bool(forKey: useDohKey),
            dohPreset: defaults.string(forKey: dohPresetKey) ?? "alidns",
            dohCustomUrl: defaults.string(forKey: dohCustomUrlKey) ?? "",
            dohBootstrapIps: defaults.string(forKey: dohBootstrapIpsKey) ?? "",
            dohTimeoutSeconds: min(max(defaults.integer(forKey: dohTimeoutSecondsKey), 1), 60)
        )
    }

    static func saveNetworkSettings(_ settings: Han1meNetworkSettings) {
        defaults.set(settings.useBuiltInHosts, forKey: useBuiltInHostsKey)
        defaults.set(settings.useDoh, forKey: useDohKey)
        defaults.set(settings.dohPreset, forKey: dohPresetKey)
        defaults.set(settings.dohCustomUrl, forKey: dohCustomUrlKey)
        defaults.set(settings.dohBootstrapIps, forKey: dohBootstrapIpsKey)
        defaults.set(settings.dohTimeoutSeconds, forKey: dohTimeoutSecondsKey)
    }
}

struct Han1meNetworkSettings: Equatable {
    var useBuiltInHosts = false
    var useDoh = false
    var dohPreset = "alidns"
    var dohCustomUrl = ""
    var dohBootstrapIps = ""
    var dohTimeoutSeconds = 10

    var dohUrl: String? {
        guard useDoh else { return nil }
        switch dohPreset {
        case "alidns": return "https://dns.alidns.com/dns-query"
        case "dnspod": return "https://doh.pub/dns-query"
        case "cloudflare": return "https://cloudflare-dns.com/dns-query"
        case "custom":
            let trimmed = dohCustomUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        default: return "https://dns.alidns.com/dns-query"
        }
    }

    var bootstrapIps: [String] {
        let manual = dohBootstrapIps
            .split { $0 == "," || $0 == "\n" || $0 == ";" || $0 == " " }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !manual.isEmpty { return Array(Set(manual)) }
        switch dohPreset {
        case "alidns": return ["223.5.5.5", "223.6.6.6"]
        case "dnspod": return ["1.12.12.12", "120.53.53.53"]
        case "cloudflare": return ["1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001"]
        default: return []
        }
    }
}
