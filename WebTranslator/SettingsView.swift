import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var browser: BrowserModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("翻譯引擎", selection: $browser.engine) {
                        ForEach(TranslationEngine.allCases) { engine in
                            Text(engine.title).tag(engine)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("翻譯引擎")
                } footer: {
                    if browser.engine == .claude && !browser.usesClaude {
                        Text("尚未輸入 API 金鑰，目前會先用 Apple 翻譯。")
                    }
                }

                if browser.engine == .claude {
                    Section {
                        Picker("模型", selection: $browser.claudeModel) {
                            ForEach(ClaudeModel.allCases) { model in
                                Text(model.title).tag(model)
                            }
                        }
                        SecureField("API 金鑰（sk-ant-…）", text: $browser.apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Link("到 Anthropic Console 申請金鑰", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    } header: {
                        Text("Claude")
                    } footer: {
                        Text("金鑰只存在這支 iPhone 的鑰匙圈。翻譯時會把網頁文字送到 Anthropic，依用量計費。")
                    }
                }

                Section("來源語言") {
                    Picker("來源語言", selection: $browser.sourceLanguage) {
                        ForEach(SourceLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    if let detected = browser.detectedLanguage {
                        Text("偵測到：\(detected) → 繁體中文")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle("開啟網頁時自動翻譯", isOn: $browser.autoTranslate)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
