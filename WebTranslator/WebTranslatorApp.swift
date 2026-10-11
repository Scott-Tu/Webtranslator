import SwiftUI

@main
struct WebTranslatorApp: App {
    @StateObject private var browser = BrowserModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(browser)
                // 支援 webtranslator://open?url=https://... ，方便從「捷徑」App 開啟網頁
                .onOpenURL { url in
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let target = components.queryItems?.first(where: { $0.name == "url" })?.value
                    else { return }
                    browser.load(target)
                }
        }
    }
}
