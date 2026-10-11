import Foundation
import Security

enum TranslationEngine: String, CaseIterable, Identifiable {
    case claude, apple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .claude: return "Claude（品質較好，需要 API 金鑰）"
        case .apple: return "Apple（免費、離線）"
        }
    }
}

enum ClaudeModel: String, CaseIterable, Identifiable {
    case opus = "claude-opus-5-5"
    case sonnet = "claude-sonnet-5-5"
    case haiku = "claude-haiku-5-5"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .opus: return "Opus 5.5（品質最好）"
        case .sonnet: return "Sonnet 5.5（平衡）"
        case .haiku: return "Haiku 5.5（最快、最便宜）"
        }
    }

    /// Haiku 沒有伺服器端的備援模型
    var supportsServerFallback: Bool { self != .haiku }
}

/// 透過 Anthropic Messages API 用 Claude 翻譯網頁文字（Swift 沒有官方 SDK，直接用 HTTP）。
struct ClaudeTranslator {
    let apiKey: String
    let model: ClaudeModel

    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// 回傳 (原文, 譯文)
    func translate(_ texts: [String], pageTitle: String, pageURL: String, sourceHint: String?) async throws -> [(String, String)] {
        let numbered = texts.enumerated().map { ["id": $0.offset, "text": $0.element] as [String: Any] }
        let input = String(data: try JSONSerialization.data(withJSONObject: ["items": numbered]), encoding: .utf8) ?? "{}"

        let system = """
        你是專業的網頁翻譯。把使用者提供的網頁文字片段翻譯成台灣慣用的繁體中文。
        - 這些片段來自同一個網頁，依序排列；請參考上下文，讓人名、專有名詞與用語前後一致，語氣自然通順。
        - 每個片段各自翻譯，不要合併、拆開或省略，id 必須與輸入相同。
        - 已經是中文、或是網址、程式碼、數字、品牌名稱等不需翻譯的片段，原樣保留。
        - 只輸出翻譯，不要加任何解釋。
        網頁標題：\(pageTitle)
        網址：\(pageURL)
        \(sourceHint.map { "原文語言：\($0)" } ?? "原文可能混合日文、英文、韓文。")
        """

        var body: [String: Any] = [
            "model": model.rawValue,
            "max_tokens": 16000,
            "system": system,
            "messages": [["role": "user", "content": input]],
            "output_config": [
                "effort": "low",
                "format": [
                    "type": "json_schema",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "translations": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "properties": [
                                        "id": ["type": "integer"],
                                        "text": ["type": "string"],
                                    ],
                                    "required": ["id", "text"],
                                    "additionalProperties": false,
                                ],
                            ],
                        ],
                        "required": ["translations"],
                        "additionalProperties": false,
                    ],
                ],
            ],
        ]
        if model.supportsServerFallback {
            body["fallbacks"] = "default"
        }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        if model.supportsServerFallback {
            request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        guard status == 200 else {
            let detail = ((json["error"] as? [String: Any])?["message"] as? String) ?? "HTTP \(status)"
            switch status {
            case 401: throw Failure(message: "API 金鑰無效，請到設定重新貼上。")
            case 429: throw Failure(message: "請求太頻繁或額度不足，請稍後再試。（\(detail)）")
            case 529, 500...599: throw Failure(message: "Claude 伺服器忙碌中，請稍後再試。")
            default: throw Failure(message: detail)
            }
        }

        if json["stop_reason"] as? String == "refusal" {
            throw Failure(message: "Claude 拒絕翻譯這段內容。")
        }
        let content = json["content"] as? [[String: Any]] ?? []
        guard let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String,
              let parsed = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
              let translations = parsed["translations"] as? [[String: Any]]
        else {
            throw Failure(message: "無法解析 Claude 的回應。")
        }

        return translations.compactMap { item in
            guard let id = (item["id"] as? NSNumber)?.intValue, texts.indices.contains(id),
                  let translated = item["text"] as? String, !translated.isEmpty else { return nil }
            return (texts[id], translated)
        }
    }
}

/// 把 API 金鑰存在 iPhone 的鑰匙圈，而不是一般設定檔。
enum KeychainStore {
    private static let service = "WebTranslator"

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ value: String, for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return }
        var attributes = query
        attributes[kSecValueData as String] = Data(value.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }
}
