import SwiftUI
import Translation

struct ContentView: View {
    @EnvironmentObject private var browser: BrowserModel
    @FocusState private var addressFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            addressBar
            ZStack(alignment: .bottom) {
                WebView(webView: browser.webView)
                    .opacity(browser.hasPage ? 1 : 0)
                if !browser.hasPage {
                    StartPageView()
                }
                if case let .translating(done, total) = browser.state {
                    translatingBadge(done: done, total: total)
                        .padding(.bottom, 12)
                }
            }
            bottomBar
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { browser.reloadIfNeeded() }
        }
        .translationTask(browser.configuration) { session in
            await browser.runTranslation(using: session)
        }
        .alert("提示", isPresented: Binding(
            get: { browser.errorMessage != nil },
            set: { if !$0 { browser.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(browser.errorMessage ?? "")
        }
    }

    // MARK: - 網址列

    private var addressBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: browser.addressText.hasPrefix("https://") ? "lock.fill" : "globe")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                TextField("輸入網址或搜尋", text: $browser.addressText)
                    .textFieldStyle(.plain)
                    .keyboardType(.webSearch)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($addressFocused)
                    .onSubmit {
                        browser.load(browser.addressText)
                        addressFocused = false
                    }
                if addressFocused && !browser.addressText.isEmpty {
                    Button {
                        browser.addressText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            ProgressView(value: browser.progress)
                .progressViewStyle(.linear)
                .opacity(browser.isLoading ? 1 : 0)
        }
        .background(.bar)
    }

    // MARK: - 底部工具列

    private var bottomBar: some View {
        HStack {
            Button(action: browser.goBack) {
                Image(systemName: "chevron.backward")
            }
            .disabled(!browser.canGoBack)

            Spacer()

            Button(action: browser.goForward) {
                Image(systemName: "chevron.forward")
            }
            .disabled(!browser.canGoForward)

            Spacer()

            translateButton

            Spacer()

            Button(action: browser.reloadOrStop) {
                Image(systemName: browser.isLoading ? "xmark" : "arrow.clockwise")
            }
            .disabled(!browser.hasPage)

            Spacer()

            settingsMenu
        }
        .font(.title3)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var translateButton: some View {
        Button(action: browser.translateButtonTapped) {
            HStack(spacing: 6) {
                switch browser.state {
                case .idle:
                    Image(systemName: "translate")
                    Text("翻譯")
                case .translating:
                    ProgressView().controlSize(.small)
                    Text("翻譯中")
                case .translated:
                    Image(systemName: "character.book.closed")
                    Text("看原文")
                case .showingOriginal:
                    Image(systemName: "translate")
                    Text("看譯文")
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.white)
        }
        .disabled(!browser.hasPage)
    }

    private var settingsMenu: some View {
        Menu {
            Picker("來源語言", selection: $browser.sourceLanguage) {
                ForEach(SourceLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.inline)

            Section {
                Toggle("開啟網頁時自動翻譯", isOn: $browser.autoTranslate)
            }

            if let detected = browser.detectedLanguage {
                Section {
                    Text("偵測到：\(detected) → 繁體中文")
                }
            }
        } label: {
            Image(systemName: "gearshape")
        }
    }

    private func translatingBadge(done: Int, total: Int) -> some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text(total > 0 ? "翻譯中… \(done)/\(total)" : "準備翻譯…")
                .font(.footnote.monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
    }
}
