import SwiftUI
import WebKit
import Translation
import NaturalLanguage

enum SourceLanguage: String, CaseIterable, Identifiable {
    case auto, japanese, english, korean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "自動偵測"
        case .japanese: return "日文"
        case .english: return "英文"
        case .korean: return "韓文"
        }
    }

    var language: Locale.Language? {
        switch self {
        case .auto: return nil
        case .japanese: return Locale.Language(identifier: "ja")
        case .english: return Locale.Language(identifier: "en")
        case .korean: return Locale.Language(identifier: "ko")
        }
    }
}

enum TranslationState: Equatable {
    case idle
    case translating(done: Int, total: Int)
    case translated
    case showingOriginal
}

@MainActor
final class BrowserModel: NSObject, ObservableObject {
    let webView: WKWebView

    @Published var addressText = ""
    @Published var pageTitle = ""
    @Published var hasPage = false
    @Published var isLoading = false
    @Published var progress: Double = 0
    @Published var canGoBack = false
    @Published var canGoForward = false

    @Published var state: TranslationState = .idle
    @Published var detectedLanguage: String?
    @Published var errorMessage: String?
    @Published var configuration: TranslationSession.Configuration?
    @Published var sourceLanguage: SourceLanguage = .auto {
        didSet {
            guard oldValue != sourceLanguage, state != .idle else { return }
            Task { await retranslate() }
        }
    }
    @Published var autoTranslate = UserDefaults.standard.bool(forKey: "autoTranslate") {
        didSet { UserDefaults.standard.set(autoTranslate, forKey: "autoTranslate") }
    }
    /// 按過「翻譯」之後，點連結、下一頁、上一頁都會自動續翻，直到按「看原文」為止
    @Published private(set) var keepTranslating = UserDefaults.standard.bool(forKey: "keepTranslating") {
        didSet { UserDefaults.standard.set(keepTranslating, forKey: "keepTranslating") }
    }

    /// 翻譯目標：繁體中文
    let targetLanguage = Locale.Language(identifier: "zh-Hant")

    private let world = WKContentWorld.world(name: "WebTranslator")
    private var observations: [NSKeyValueObservation] = []
    private var isRunning = false
    private var needsIncremental = false
    private var runID = 0
    /// 每次換頁就加一，用來丟棄舊頁面還在跑的翻譯結果
    private var pageGeneration = 0

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()

        let controller = webView.configuration.userContentController
        controller.addUserScript(WKUserScript(source: Scripts.core,
                                              injectionTime: .atDocumentEnd,
                                              forMainFrameOnly: true,
                                              in: world))
        controller.add(WeakMessageHandler(self), contentWorld: world, name: "wt")

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isInspectable = true

        observations = [
            webView.observe(\.estimatedProgress) { [weak self] webView, _ in
                MainActor.assumeIsolated { self?.progress = webView.estimatedProgress }
            },
            webView.observe(\.isLoading) { [weak self] webView, _ in
                MainActor.assumeIsolated { self?.isLoading = webView.isLoading }
            },
            webView.observe(\.title) { [weak self] webView, _ in
                MainActor.assumeIsolated { self?.pageTitle = webView.title ?? "" }
            },
            webView.observe(\.url) { [weak self] webView, _ in
                MainActor.assumeIsolated {
                    guard let self, let url = webView.url else { return }
                    // 網頁程序被系統回收時 url 會暫時變成 nil，這時保留畫面狀態，等待自動重新載入
                    self.hasPage = true
                    self.addressText = url.absoluteString
                    if url.scheme == "http" || url.scheme == "https" {
                        UserDefaults.standard.set(url.absoluteString, forKey: "lastURL")
                    }
                }
            },
            webView.observe(\.canGoBack) { [weak self] webView, _ in
                MainActor.assumeIsolated { self?.canGoBack = webView.canGoBack }
            },
            webView.observe(\.canGoForward) { [weak self] webView, _ in
                MainActor.assumeIsolated { self?.canGoForward = webView.canGoForward }
            },
        ]

        restoreLastPage()
    }

    /// 重新開啟 App 或網頁被系統清掉時，回到最後看的頁面
    func restoreLastPage() {
        guard webView.url == nil || !hasPage,
              let saved = UserDefaults.standard.string(forKey: "lastURL"),
              let url = URL(string: saved) else { return }
        hasPage = true
        addressText = saved
        webView.load(URLRequest(url: url))
    }

    /// App 回到前景時呼叫：網頁內容若已被系統回收就重新載入
    func reloadIfNeeded() {
        if webView.url == nil {
            restoreLastPage()
        }
    }

    // MARK: - 瀏覽

    func load(_ input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let url = Self.url(from: text) else { return }
        webView.load(URLRequest(url: url))
    }

    static func url(from text: String) -> URL? {
        let lower = text.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return URL(string: text)
        }
        // 看起來像網址就補上 https://，否則當成搜尋關鍵字
        if !text.contains(" "), text.contains("."), let url = URL(string: "https://" + text), url.host != nil {
            return url
        }
        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: text)]
        return components.url
    }

    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }

    func reloadOrStop() {
        if webView.isLoading { webView.stopLoading() } else { webView.reload() }
    }

    // MARK: - 翻譯

    func translateButtonTapped() {
        switch state {
        case .idle:
            keepTranslating = true
            Task { await startTranslation() }
        case .translating:
            break
        case .translated:
            keepTranslating = false
            Task {
                _ = try? await js("return window.__wt.showOriginal();")
                state = .showingOriginal
            }
        case .showingOriginal:
            keepTranslating = true
            Task {
                _ = try? await js("return window.__wt.showTranslated();")
                state = .translated
                requestIncrementalTranslation()   // 補翻看原文期間新出現的內容
            }
        }
    }

    /// silent: 自動翻譯時不跳出「無法辨識語言」之類的提示
    func startTranslation(silent: Bool = false) async {
        guard state == .idle else { return }
        let source: Locale.Language
        if let chosen = sourceLanguage.language {
            source = chosen
            detectedLanguage = nil
        } else {
            let sample = (try? await js("return window.__wt.sample();")) as? String ?? ""
            let detected = Self.detectLanguage(in: sample)
            if detected == .japanese {
                source = Locale.Language(identifier: "ja"); detectedLanguage = "日文"
            } else if detected == .english {
                source = Locale.Language(identifier: "en"); detectedLanguage = "英文"
            } else if detected == .korean {
                source = Locale.Language(identifier: "ko"); detectedLanguage = "韓文"
            } else if detected == .simplifiedChinese || detected == .traditionalChinese {
                if !silent { errorMessage = "這個頁面看起來已經是中文了。如果判斷錯誤，請在「來源語言」手動選擇。" }
                return
            } else {
                if !silent { errorMessage = "無法辨識這個頁面的語言，請在「來源語言」手動選擇日文、英文或韓文。" }
                return
            }
        }

        state = .translating(done: 0, total: 0)
        if configuration?.source == source {
            configuration?.invalidate()   // 同樣的語言組合：重新觸發 translationTask
        } else {
            configuration = TranslationSession.Configuration(source: source, target: targetLanguage)
        }
    }

    private func retranslate() async {
        _ = try? await js("return window.__wt.reset();")
        state = .idle
        await startTranslation()
    }

    private func requestIncrementalTranslation() {
        guard state == .translated, configuration != nil else { return }
        if isRunning {
            needsIncremental = true
        } else {
            configuration?.invalidate()
        }
    }

    static func detectLanguage(in text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.japanese, .english, .korean, .simplifiedChinese, .traditionalChinese]
        recognizer.processString(text)
        return recognizer.dominantLanguage
    }

    /// 由 ContentView 的 .translationTask 呼叫；session 只在這個函式執行期間有效。
    func runTranslation(using session: TranslationSession) async {
        runID += 1
        let myRun = runID
        isRunning = true
        defer {
            if myRun == runID {
                isRunning = false
                if needsIncremental {
                    needsIncremental = false
                    requestIncrementalTranslation()
                }
            }
        }

        let generation = pageGeneration
        let incremental = (state == .translated)
        var translatedCount = 0

        do {
            try await session.prepareTranslation()   // 第一次使用會請使用者下載語言套件

            guard let result = try await js("return window.__wt.collect();") as? [String: Any],
                  let token = result["token"] as? String,
                  let rawItems = result["items"] as? [[String: Any]]
            else {
                if !incremental { state = .idle }
                return
            }

            // 相同的句子只翻一次
            var idsByText: [String: [Int]] = [:]
            var uniqueTexts: [String] = []
            for item in rawItems {
                guard let id = (item["id"] as? NSNumber)?.intValue,
                      let text = item["text"] as? String, !text.isEmpty else { continue }
                if idsByText[text] == nil { uniqueTexts.append(text) }
                idsByText[text, default: []].append(id)
            }

            if uniqueTexts.isEmpty {
                if !incremental {
                    state = .idle
                    errorMessage = "這個頁面沒有可以翻譯的文字。"
                }
                return
            }

            if !incremental { state = .translating(done: 0, total: uniqueTexts.count) }

            var done = 0
            for start in stride(from: 0, to: uniqueTexts.count, by: 40) {
                let chunk = Array(uniqueTexts[start..<min(start + 40, uniqueTexts.count)])
                let pairs = try await translate(chunk, with: session)
                guard generation == pageGeneration, myRun == runID else { return }   // 已經換頁或有新的翻譯工作

                let payload: [[String: Any]] = pairs.flatMap { source, target in
                    (idsByText[source] ?? []).map { id -> [String: Any] in ["id": id, "text": target] }
                }
                if !payload.isEmpty {
                    _ = try await js("return window.__wt.apply(token, items);",
                                     arguments: ["token": token, "items": payload])
                }
                translatedCount += pairs.count
                done += chunk.count
                if !incremental { state = .translating(done: done, total: uniqueTexts.count) }
            }

            if translatedCount == 0 && !incremental {
                _ = try? await js("return window.__wt.reset();")
                state = .idle
                errorMessage = "翻譯失敗，請確認來源語言是否正確。"
                return
            }
            state = .translated
        } catch {
            guard generation == pageGeneration, myRun == runID, !Task.isCancelled, !incremental else { return }
            if translatedCount > 0 {
                state = .translated
            } else {
                _ = try? await js("return window.__wt.reset();")
                state = .idle
            }
            errorMessage = "翻譯失敗：\(error.localizedDescription)"
        }
    }

    /// 回傳 (原文, 譯文)。整批失敗時改成逐句翻譯，跳過無法翻譯的句子。
    private func translate(_ texts: [String], with session: TranslationSession) async throws -> [(String, String)] {
        let requests = texts.enumerated().map { index, text in
            TranslationSession.Request(sourceText: text, clientIdentifier: String(index))
        }
        do {
            let responses = try await session.translations(from: requests)
            return responses.compactMap { response in
                guard let id = response.clientIdentifier, let index = Int(id), texts.indices.contains(index) else { return nil }
                return (texts[index], response.targetText)
            }
        } catch {
            try Task.checkCancellation()
            var pairs: [(String, String)] = []
            for text in texts {
                try Task.checkCancellation()
                if let response = try? await session.translate(text) {
                    pairs.append((text, response.targetText))
                }
            }
            return pairs
        }
    }

    // MARK: - JavaScript

    @discardableResult
    private func js(_ body: String, arguments: [String: Any] = [:]) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            webView.callAsyncJavaScript(body, arguments: arguments, in: nil, in: world) { result in
                switch result {
                case .success(let value): continuation.resume(returning: value)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension BrowserModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        pageGeneration += 1
        state = .idle
        detectedLanguage = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (autoTranslate || keepTranslating) && state == .idle {
            Task { await startTranslation(silent: true) }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showLoadError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showLoadError(error)
    }

    /// 在背景太久時 iOS 會結束網頁程序，畫面會變白；自動重新載入最後的頁面
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if webView.url != nil {
            webView.reload()
        } else {
            restoreLastPage()
        }
    }

    private func showLoadError(_ error: Error) {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return }
        errorMessage = "無法載入網頁：\(error.localizedDescription)"
    }
}

// MARK: - WKScriptMessageHandler

extension BrowserModel: WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.body as? String == "changed" {
            requestIncrementalTranslation()
        }
    }
}

// MARK: - WKUIDelegate

extension BrowserModel: WKUIDelegate {
    /// 原本會開新分頁的連結（target="_blank"、window.open）改在同一頁開啟，否則點了會沒反應
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
