# 網頁翻譯（WebTranslator）

在 iPhone 上瀏覽日文、英文、韓文網頁，一鍵翻成繁體中文的 App。

## 功能

- 內建瀏覽器：輸入網址或關鍵字（關鍵字會用 Google 搜尋），可前進、後退、重新整理，支援左右滑動換頁。
- 一鍵翻譯：按下底部的「翻譯」，整頁文字直接換成繁體中文，版面維持原樣。
- 保留原網頁功能：只替換文字，連結、按鈕、「下一頁」、選單都照常可點；原本會開新分頁的連結改在同一頁開啟。
- 換頁自動續翻：按過一次「翻譯」後，之後點連結、下一頁、上一頁都會自動翻譯，不用重新貼網址或再按翻譯；按「看原文」即停止續翻。
- 原文／譯文切換：翻譯後按「看原文」可立即切回，不必重新翻譯。
- 自動偵測語言：自動判斷是日文、英文還是韓文；判斷錯時可在齒輪選單手動指定。
- 自動翻譯：齒輪選單可開啟「開啟網頁時自動翻譯」。
- 動態內容：往下捲動載入的新文章、展開的留言等會自動補翻。
- 離線、免費、不需 API 金鑰：使用 Apple 內建的翻譯引擎（Translation 框架），翻譯在手機上完成，網頁內容不會送到任何伺服器。

## 安裝到 iPhone（不需要 Mac：GitHub 雲端編譯 + Windows 安裝）

和 3Dface 一樣的做法。iPhone 需要 **iOS 18 以上**。

### 1. GitHub 雲端編譯 IPA
1. 在 github.com 建立新的 repository，例如 `WebTranslator`（選 Public，Actions 免費）。
2. 點 **uploading an existing file**，把解壓後 `WebTranslator` 資料夾**裡面的內容**（`README.md`、`WebTranslator`、`WebTranslator.xcodeproj`、`.github`）拖進去，按 Commit。
3. **檢查 `.github` 資料夾有沒有上傳成功**（隱藏資料夾在網頁上傳時常被略過）。若沒有：Add file → Create new file，檔名輸入
   `.github/workflows/build-ipa.yml`，把同名檔案的內容貼上後 Commit。
4. 到 **Actions** 分頁 → 左側 **Build IPA** → **Run workflow**。
5. 約 5–10 分鐘後，點進完成的執行紀錄，在頁面下方 **Artifacts** 下載 `WebTranslator-ipa`（是 zip，解壓得到 `WebTranslator.ipa`）。
6. 若編譯失敗，把 Actions 的錯誤訊息貼給我修正。

### 2. Windows 用 Sideloadly 安裝
1. 安裝 **iTunes**（建議用 Apple 官網版，不要用 Microsoft Store 版）與 **Sideloadly**。
2. USB 連接 iPhone，iPhone 上點「信任這部電腦」。
3. 把 `WebTranslator.ipa` 拖進 Sideloadly，輸入 Apple ID，按 Start（建議用一個副帳號 Apple ID）。

### 3. iPhone 設定（免費帳號方式）
1. 設定 → 隱私權與安全性 → **開發者模式** → 開啟並重開機。
2. 設定 → 一般 → **VPN 與裝置管理** → 點你的 Apple ID → 信任。
3. 免費 Apple ID 安裝的 App **7 天後失效**，重新用 Sideloadly 安裝即可（不用重新編譯）。想長期使用請改用下面的 TestFlight。

### （有 Mac 的話）用 Xcode 直接安裝
開啟 `WebTranslator.xcodeproj` → Signing & Capabilities 的 Team 選你的 Apple ID（Bundle Identifier 衝突就改成獨一無二的名稱）→ 接上 iPhone 按 ▶。翻譯功能在模擬器上無法運作，請用實機。

## 長期使用：TestFlight（建議，需要 Apple 開發者計畫）

設定一次之後，每次 main 分支有更新，GitHub 會自動編譯、簽章並上傳到 TestFlight，iPhone 上的 TestFlight App 按「更新」就好，不需要電腦或傳輸線。每個版本可以用 90 天。以下步驟在 Windows 或手機的瀏覽器都能完成。

### 1. 加入 Apple 開發者計畫（每年 US$99）
在 iPhone 下載「Apple Developer」App 註冊最方便，或到 developer.apple.com/programs/enroll。審核通過後才能進行下一步，通常需要一到兩天。

### 2. 註冊 Bundle ID
developer.apple.com › Account › **Certificates, IDs & Profiles** › **Identifiers** › 按「+」› **App IDs** › **App**：
- Description：WebTranslator
- Bundle ID 選 **Explicit**，填 `com.scotttu.webtranslator`（必須完全一樣）
- 其他功能都不用勾，按 Continue › Register。

### 3. 在 App Store Connect 建立 App
appstoreconnect.apple.com › **App** › 「+」› **新增 App**：
- 平台：iOS
- 名稱：任何還沒被別人用過的名字，例如「網頁翻譯 Scott」（只有你看得到，不會上架）
- 主要語言：繁體中文
- 套裝識別碼（Bundle ID）：選剛剛註冊的 `com.scotttu.webtranslator`
- SKU：隨意，例如 webtranslator

### 4. 建立 App Store Connect API 金鑰
App Store Connect › **使用者與存取權限** › **整合** › **App Store Connect API** › **團隊金鑰** › 「+」：
- 名稱：GitHub
- 存取權限：**管理（Admin）**（雲端簽章需要這個權限）
- 產生後記下 **Issuer ID** 與這把金鑰的 **Key ID**，並按「下載」取得 `AuthKey_XXXX.p8`。**這個檔案只能下載一次**，請妥善保存。

### 5. 找到 Team ID
developer.apple.com › Account › **Membership details**，複製 **Team ID**（10 個英數字）。

### 6. 把 4 個值存進 GitHub Secrets
GitHub 的 Webtranslator repository › **Settings** › **Secrets and variables** › **Actions** › **New repository secret**，一次新增一個：

| Name | Secret |
|---|---|
| `ASC_KEY_ID` | 第 4 步的 Key ID |
| `ASC_ISSUER_ID` | 第 4 步的 Issuer ID |
| `ASC_KEY_P8` | 用記事本打開 `.p8` 檔，整份內容（含 BEGIN/END 那兩行）貼上 |
| `APPLE_TEAM_ID` | 第 5 步的 Team ID |

這些是私密金鑰，請直接存在 GitHub，不要貼到聊天或其他地方。

### 7. 上傳第一個版本
GitHub › **Actions** › 左側 **TestFlight** › **Run workflow**。跑完後約 10–30 分鐘，App Store Connect 的 **TestFlight** 分頁會出現這個版本。

### 8. 安裝到 iPhone
1. App Store Connect › TestFlight › **內部測試** › 「+」建立群組，把自己的 Apple ID 加進去並勾選這個版本。
2. iPhone 從 App Store 安裝 **TestFlight**，收到邀請後按「接受」再「安裝」。
3. 之後有新版本，TestFlight 會通知你更新。

## 第一次翻譯

第一次翻譯某個語言時，系統會跳出視窗詢問是否下載該語言的翻譯套件（日文、英文、韓文各一次），按「下載」即可。下載後即使離線也能翻譯。也可以事先到 **設定 › App › 翻譯 › 下載的語言** 下載「日文」「英文」「韓文」與「中文（繁體）」。

## 小技巧

- 從「捷徑」App 或其他 App 開啟網址：使用 `webtranslator://open?url=https://網址`。
- 網頁中的程式碼、輸入框、日文假名注音（ruby）不會被翻譯。

## 程式架構

| 檔案 | 用途 |
| --- | --- |
| `WebTranslatorApp.swift` | App 進入點，處理 `webtranslator://` 網址 |
| `ContentView.swift` | 主畫面：網址列、網頁、工具列，並以 `.translationTask` 取得翻譯 session |
| `StartPageView.swift` | 起始頁與常用網站捷徑 |
| `BrowserModel.swift` | 瀏覽狀態、語言偵測（NaturalLanguage）、批次翻譯流程 |
| `WebView.swift` | 把 WKWebView 包成 SwiftUI 元件 |
| `Scripts.swift` | 注入網頁的 JavaScript：收集文字、替換譯文、切換原文、偵測新內容 |

翻譯流程：JavaScript 在獨立的 content world 收集網頁文字（被 `<b>`、`<span>` 切開的句子會整段收集，譯文較通順）→ Swift 去除重複句子後，每 40 句一批交給 Apple 翻譯引擎 → 譯文分批寫回網頁，所以長頁面的中文會分批逐步出現。
