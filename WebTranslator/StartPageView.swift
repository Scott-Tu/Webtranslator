import SwiftUI

/// 還沒開啟網頁時顯示的起始頁，附幾個常用的日、英、韓網站。
struct StartPageView: View {
    @EnvironmentObject private var browser: BrowserModel

    private struct Site: Identifiable {
        let name: String
        let url: String
        let flag: String
        var id: String { url }
    }

    private let sites: [Site] = [
        Site(name: "Yahoo! JAPAN", url: "https://www.yahoo.co.jp", flag: "🇯🇵"),
        Site(name: "NHK News", url: "https://www3.nhk.or.jp/news/", flag: "🇯🇵"),
        Site(name: "BBC News", url: "https://www.bbc.com/news", flag: "🇬🇧"),
        Site(name: "Wikipedia (EN)", url: "https://en.wikipedia.org", flag: "🌐"),
        Site(name: "NAVER", url: "https://www.naver.com", flag: "🇰🇷"),
        Site(name: "Daum", url: "https://www.daum.net", flag: "🇰🇷"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "translate")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                    Text("網頁翻譯")
                        .font(.title.bold())
                    Text("開啟日文、英文或韓文網頁，按下「翻譯」即可轉成繁體中文。翻譯在 iPhone 上離線完成，不會把網頁內容傳到伺服器。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(sites) { site in
                        Button {
                            browser.load(site.url)
                        } label: {
                            HStack {
                                Text(site.flag)
                                Text(site.name)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
    }
}
