# @AppStorage解説

`@AppStorage`は、SwiftUIで**UserDefaultsを簡単に使うための**プロパティラッパーです。設定値をビューで直接使い、自動的に保存・読み込み・UI更新ができます。

## 基本概念

### UserDefaultsとの関係

```
@AppStorage
    ↓（内部的にUserDefaultsを使用）
UserDefaults
    ↓
ディスクに永続化
```

`@AppStorage`は**UserDefaultsのSwiftUI版**と考えればOKです。

## 基本的な使い方

### 従来の方法（UserDefaults）

```swift
struct SettingsView: View {
    @State private var isDarkMode: Bool

    init() {
        // 読み込み
        _isDarkMode = State(initialValue: UserDefaults.standard.bool(forKey: "isDarkMode"))
    }

    var body: some View {
        Toggle("ダークモード", isOn: $isDarkMode)
            .onChange(of: isDarkMode) { newValue in
                // 保存
                UserDefaults.standard.set(newValue, forKey: "isDarkMode")
            }
    }
}
```

→ コードが煩雑、保存を忘れる可能性がある

### @AppStorageを使う方法

```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some View {
        Toggle("ダークモード", isOn: $isDarkMode)
    }
}
```

→ たった1行！自動的に保存・読み込み

**メリット**:
- 保存処理が不要（自動）
- 読み込み処理が不要（自動）
- 値が変わるとビューが自動更新
- コードが簡潔

## 使用例

### 1. Bool値（トグルスイッチ）

```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("notificationsEnabled") var notificationsEnabled = true

    var body: some View {
        Form {
            Toggle("ダークモード", isOn: $isDarkMode)
            Toggle("通知を有効化", isOn: $notificationsEnabled)
        }
    }
}
```

### 2. String（テキスト入力）

```swift
struct ProfileView: View {
    @AppStorage("username") var username = "ゲスト"

    var body: some View {
        VStack {
            TextField("ユーザー名", text: $username)
            Text("こんにちは、\(username)さん")
        }
    }
}
```

### 3. Int（数値、ピッカー）

```swift
struct SettingsView: View {
    @AppStorage("fontSize") var fontSize = 16

    var body: some View {
        VStack {
            Picker("フォントサイズ", selection: $fontSize) {
                Text("小").tag(14)
                Text("中").tag(16)
                Text("大").tag(20)
            }

            Text("サンプルテキスト")
                .font(.system(size: CGFloat(fontSize)))
        }
    }
}
```

### 4. Double（スライダー）

```swift
struct SettingsView: View {
    @AppStorage("volume") var volume = 50.0

    var body: some View {
        VStack {
            Slider(value: $volume, in: 0...100)
            Text("音量: \(Int(volume))%")
        }
    }
}
```

## 対応している型

### 基本型

```swift
// Bool
@AppStorage("flag") var flag = false

// Int
@AppStorage("count") var count = 0

// Double
@AppStorage("value") var value = 0.0

// String
@AppStorage("text") var text = ""

// URL
@AppStorage("website") var website = URL(string: "https://example.com")!

// Data
@AppStorage("rawData") var rawData = Data()
```

### RawRepresentable（Enum）

Enumも使えます（`String`や`Int`をRawValueとする場合）

```swift
enum Theme: String {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
}

struct SettingsView: View {
    @AppStorage("theme") var theme = Theme.auto

    var body: some View {
        Picker("テーマ", selection: $theme) {
            Text("ライト").tag(Theme.light)
            Text("ダーク").tag(Theme.dark)
            Text("自動").tag(Theme.auto)
        }
    }
}
```

### カスタム型（Codableを使う）

```swift
// ❌ 直接は使えない
struct User: Codable {
    let name: String
    let age: Int
}

// @AppStorage("user") var user = User(name: "太郎", age: 20)  // エラー！

// ✅ 代わりにUserDefaultsを使う
class UserSettings: ObservableObject {
    @Published var user: User {
        didSet {
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: "user")
            }
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "user"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.user = user
        } else {
            self.user = User(name: "ゲスト", age: 0)
        }
    }
}
```

## 複数のビューで共有

`@AppStorage`は**アプリ全体で自動的に同期**されます。

```swift
// ビュー1
struct SettingsView: View {
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some View {
        Toggle("ダークモード", isOn: $isDarkMode)
    }
}

// ビュー2（別の画面）
struct HomeView: View {
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some View {
        Text("ホーム")
            .background(isDarkMode ? Color.black : Color.white)
    }
}
```

**動作**:
1. SettingsViewで`isDarkMode`をONにする
2. UserDefaultsに保存される
3. HomeViewの`isDarkMode`も**自動的に更新**される
4. HomeViewが**自動的に再描画**される

## デフォルト値

### デフォルト値の扱い

```swift
@AppStorage("score") var score = 100
```

**動作**:
1. 初回起動時: `score = 100`（デフォルト値）
2. ユーザーが変更: `score = 200`（UserDefaultsに保存）
3. 次回起動時: `score = 200`（UserDefaultsから復元）

### デフォルト値の注意点

```swift
// ❌ nilはデフォルト値にできない
@AppStorage("username") var username: String? = nil  // エラー

// ✅ 空文字列を使う
@AppStorage("username") var username = ""

// ✅ またはOptionalを使う別の方法
var username: String? {
    let value = UserDefaults.standard.string(forKey: "username")
    return value?.isEmpty == false ? value : nil
}
```

## 実用的なパターン

### パターン1: 設定画面

```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("fontSize") var fontSize = 16
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("soundEnabled") var soundEnabled = true

    var body: some View {
        Form {
            Section("表示") {
                Toggle("ダークモード", isOn: $isDarkMode)
                Stepper("フォントサイズ: \(fontSize)", value: $fontSize, in: 12...24)
            }

            Section("通知") {
                Toggle("通知を有効化", isOn: $notificationsEnabled)
                Toggle("サウンドを有効化", isOn: $soundEnabled)
            }
        }
        .navigationTitle("設定")
    }
}
```

### パターン2: アプリ全体のテーマ

```swift
enum ColorScheme: String {
    case light, dark, auto
}

@main
struct MyApp: App {
    @AppStorage("colorScheme") var colorScheme = ColorScheme.auto

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(schemeValue)
        }
    }

    var schemeValue: SwiftUI.ColorScheme? {
        switch colorScheme {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }
}
```

### パターン3: 初回起動チェック

```swift
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainView()
        } else {
            VStack {
                Text("ようこそ！")
                Button("始める") {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
```

### パターン4: 設定とビューの連携

```swift
struct ContentView: View {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("fontSize") var fontSize = 16.0

    var body: some View {
        NavigationStack {
            VStack {
                Text("メインコンテンツ")
                    .font(.system(size: fontSize))
            }
            .background(isDarkMode ? Color.black : Color.white)
            .toolbar {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("fontSize") var fontSize = 16.0

    var body: some View {
        Form {
            Toggle("ダークモード", isOn: $isDarkMode)
            Slider(value: $fontSize, in: 12...24)
        }
        .navigationTitle("設定")
    }
}
```

## @AppStorage vs @State vs @Published

### 違いの比較

| プロパティラッパー | 保存場所 | アプリ終了後 | 複数ビューで共有 | 用途 |
|------------------|---------|------------|----------------|------|
| `@State` | メモリ | ❌ 消える | ❌ できない | 一時的なUI状態 |
| `@AppStorage` | UserDefaults | ✅ 残る | ✅ 自動的に共有 | 設定値 |
| `@Published` | メモリ（ObservableObject内） | ❌ 消える | ✅ EnvironmentObjectで共有 | 複雑な状態管理 |

### 使い分け

```swift
struct MyView: View {
    // 一時的なUI状態（このビューだけ、アプリ終了で消える）
    @State private var isShowingSheet = false

    // 設定値（アプリ全体、アプリ終了後も残る）
    @AppStorage("isDarkMode") var isDarkMode = false

    // 複雑なデータ（アプリ全体で共有、手動で永続化）
    @EnvironmentObject var cart: Cart

    var body: some View {
        VStack {
            Button("シートを表示") {
                isShowingSheet = true  // @State
            }

            Toggle("ダークモード", isOn: $isDarkMode)  // @AppStorage

            Text("カート: \(cart.items.count)点")  // @EnvironmentObject
        }
    }
}
```

## このアプリへの適用例

現在のCartの実装をより簡単にできます：

### 現在の実装（UserDefaults + didSet）

[Cart.swift](sampleShop/Model/Cart.swift)

```swift
class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            saveItems()
        }
    }

    init() {
        loadItems()
    }

    private func saveItems() {
        let data = try? JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: "cart_items")
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: "cart_items"),
              let items = try? JSONDecoder().decode([Product].self, from: data) else {
            return
        }
        self.items = items
    }
}
```

### @AppStorageを使った簡単な設定値の例

もし単純な設定値なら、このように書けます：

```swift
// 設定画面の例
struct SettingsView: View {
    @AppStorage("showThumbnails") var showThumbnails = true
    @AppStorage("sortOrder") var sortOrder = "price"

    var body: some View {
        Form {
            Toggle("サムネイルを表示", isOn: $showThumbnails)

            Picker("並び順", selection: $sortOrder) {
                Text("価格順").tag("price")
                Text("名前順").tag("name")
            }
        }
    }
}

// ContentViewで設定を使用
struct ContentView: View {
    @AppStorage("showThumbnails") var showThumbnails = true
    @StateObject private var service = ProductService()

    var body: some View {
        List(service.products) { product in
            HStack {
                if showThumbnails {  // 設定に応じて表示切り替え
                    AsyncImage(url: URL(string: product.thumbnail))
                        .frame(width: 60, height: 60)
                }
                Text(product.title)
            }
        }
    }
}
```

## 注意点

### 1. カスタム型は直接使えない

```swift
// ❌ これはできない
@AppStorage("cart") var cart = [Product]()

// ✅ 基本型のみ
@AppStorage("cartCount") var cartCount = 0
```

カスタム型は従来の方法（UserDefaults + JSONEncoder）を使う必要があります。

### 2. パフォーマンス

```swift
// ⚠️ 重い処理を避ける
@AppStorage("items") var items = Data() {
    didSet {
        // @AppStorageにdidSetは使えない
    }
}
```

`@AppStorage`には`didSet`が使えません。監視が必要な場合は`.onChange(of:)`を使います。

```swift
struct MyView: View {
    @AppStorage("count") var count = 0

    var body: some View {
        Text("Count: \(count)")
            .onChange(of: count) { newValue in
                print("countが変更されました: \(newValue)")
            }
    }
}
```

### 3. プレビュー

Previewでは初期値が使われます。

```swift
#Preview {
    SettingsView()
        // @AppStorageの値はPreviewでは常にデフォルト値
}
```

## デバッグ

### 保存された値を確認

```swift
struct DebugView: View {
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some View {
        VStack {
            Toggle("ダークモード", isOn: $isDarkMode)

            Button("UserDefaultsの値を表示") {
                print(UserDefaults.standard.bool(forKey: "isDarkMode"))
            }

            Button("リセット") {
                UserDefaults.standard.removeObject(forKey: "isDarkMode")
                isDarkMode = false  // デフォルト値に戻す
            }
        }
    }
}
```

## まとめ

### @AppStorageの特徴

| 特徴 | 説明 |
|------|------|
| **簡単** | 1行で宣言、自動保存・読み込み |
| **SwiftUI専用** | SwiftUIビューで使用 |
| **UserDefaults** | 内部的にUserDefaultsを使用 |
| **自動同期** | 値が変わると全てのビューが自動更新 |
| **基本型のみ** | カスタム型は直接使えない |
| **設定値向け** | アプリの設定や簡単な状態管理に最適 |

### いつ使うべきか

| ケース | 使うべきもの |
|--------|-------------|
| アプリの設定値 | ✅ @AppStorage |
| 一時的なUI状態 | @State |
| 複雑なカスタム型 | @Published + UserDefaults（このアプリのCart） |
| 機密情報 | Keychain |
| 大量のデータ | Core Data / File System |

**ベストプラクティス**: 設定画面や簡単なフラグには`@AppStorage`を使うと、コードが劇的に簡潔になります！
