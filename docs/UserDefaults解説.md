# UserDefaults解説

`UserDefaults`は、iOSアプリで**簡単なデータを永続化（保存）**するための標準的な仕組みです。アプリを終了しても、保存したデータは次回起動時に復元できます。

## 基本概念

### 何ができるか

- アプリの設定や小さなデータを保存
- アプリを再起動してもデータが残る
- キーと値のペアで保存（辞書のような仕組み）

### イメージ

```
UserDefaults = アプリ専用の小さな保存庫

┌─────────────────────────┐
│ UserDefaults            │
├─────────────────────────┤
│ "username"    → "太郎"  │
│ "isDarkMode"  → true    │
│ "score"       → 1000    │
│ "cart_items"  → [...]   │
└─────────────────────────┘

アプリ終了 → 保存される
アプリ起動 → 復元される
```

## 基本的な使い方

### 1. データを保存（書き込み）

```swift
// 文字列を保存
UserDefaults.standard.set("太郎", forKey: "username")

// 数値を保存
UserDefaults.standard.set(1000, forKey: "score")

// Bool値を保存
UserDefaults.standard.set(true, forKey: "isDarkMode")

// 配列を保存
UserDefaults.standard.set(["Apple", "Banana"], forKey: "fruits")
```

### 2. データを読み込み

```swift
// 文字列を取得
let username = UserDefaults.standard.string(forKey: "username")
// → Optional("太郎")

// 数値を取得
let score = UserDefaults.standard.integer(forKey: "score")
// → 1000

// Bool値を取得
let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
// → true

// 配列を取得
let fruits = UserDefaults.standard.array(forKey: "fruits") as? [String]
// → Optional(["Apple", "Banana"])
```

### 3. データを削除

```swift
UserDefaults.standard.removeObject(forKey: "username")
```

## このアプリでの使用例

[Cart.swift:24-41](sampleShop/Model/Cart.swift#L24-L41)

### 保存処理

```swift
private func saveItems() {
    do {
        // 1. ProductsをJSONデータに変換
        let data = try JSONEncoder().encode(items)

        // 2. UserDefaultsに保存
        UserDefaults.standard.set(data, forKey: "cart_items")

        print("保存成功:", items)
    } catch {
        print("保存失敗:", error)
    }
}
```

### 読み込み処理

```swift
private func loadItems() {
    // 1. UserDefaultsからDataを取得
    guard let data = UserDefaults.standard.data(forKey: "cart_items") else { return }

    do {
        // 2. JSONデータを[Product]に変換
        items = try JSONDecoder().decode([Product].self, from: data)
    } catch {
        print("読み込み失敗:", error)
    }
}
```

### 動作の流れ

```swift
// アプリ起動時
init() {
    loadItems()  // UserDefaultsから復元
}

// 商品追加時
func add(_ product: Product) {
    items.append(product)
    // ↓ didSetが発火
    // ↓ saveItems()が自動実行
    // ↓ UserDefaultsに保存
}

// アプリ終了
// → UserDefaultsの内容は自動的にディスクに保存される

// アプリ再起動
// → init()でloadItems()が実行される
// → カートの内容が復元される
```

## 保存できるデータ型

### 基本型（直接保存可能）

```swift
// String
UserDefaults.standard.set("テキスト", forKey: "text")

// Int, Double, Float
UserDefaults.standard.set(42, forKey: "number")
UserDefaults.standard.set(3.14, forKey: "pi")

// Bool
UserDefaults.standard.set(true, forKey: "flag")

// Date
UserDefaults.standard.set(Date(), forKey: "lastLogin")

// Data
let data = "Hello".data(using: .utf8)!
UserDefaults.standard.set(data, forKey: "rawData")

// Array, Dictionary（要素が基本型の場合）
UserDefaults.standard.set([1, 2, 3], forKey: "numbers")
UserDefaults.standard.set(["name": "太郎"], forKey: "user")

// URL
UserDefaults.standard.set(URL(string: "https://example.com"), forKey: "url")
```

### カスタム型（JSONエンコードが必要）

```swift
struct Product: Codable {
    let id: Int
    let name: String
}

// 保存
let product = Product(id: 1, name: "iPhone")
if let data = try? JSONEncoder().encode(product) {
    UserDefaults.standard.set(data, forKey: "product")
}

// 読み込み
if let data = UserDefaults.standard.data(forKey: "product"),
   let product = try? JSONDecoder().decode(Product.self, from: data) {
    print(product.name)
}
```

## 読み込みメソッドの種類

### 型ごとのメソッド

```swift
// String（nilの可能性あり）
let name = UserDefaults.standard.string(forKey: "name")
// → String?

// Int（存在しない場合は0）
let score = UserDefaults.standard.integer(forKey: "score")
// → Int（非Optional）

// Bool（存在しない場合はfalse）
let flag = UserDefaults.standard.bool(forKey: "flag")
// → Bool（非Optional）

// Double（存在しない場合は0.0）
let value = UserDefaults.standard.double(forKey: "value")
// → Double（非Optional）

// Data
let data = UserDefaults.standard.data(forKey: "data")
// → Data?

// Array
let array = UserDefaults.standard.array(forKey: "array")
// → [Any]?

// Dictionary
let dict = UserDefaults.standard.dictionary(forKey: "dict")
// → [String: Any]?

// Any（汎用）
let any = UserDefaults.standard.object(forKey: "key")
// → Any?
```

### Optionalとデフォルト値の注意

```swift
// ❌ 注意: integer()は存在しない場合0を返す
let count = UserDefaults.standard.integer(forKey: "count")
// → 初回は0（保存していなくても0）

// ✅ 存在チェックが必要な場合
if UserDefaults.standard.object(forKey: "count") != nil {
    let count = UserDefaults.standard.integer(forKey: "count")
    print("保存されている: \(count)")
} else {
    print("まだ保存されていない")
}
```

## 実用的なパターン

### パターン1: 設定の保存

```swift
class Settings {
    static let shared = Settings()

    var isDarkMode: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isDarkMode")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isDarkMode")
        }
    }

    var username: String? {
        get {
            UserDefaults.standard.string(forKey: "username")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "username")
        }
    }
}

// 使用例
Settings.shared.isDarkMode = true
print(Settings.shared.isDarkMode)  // true
```

### パターン2: @AppStorage（SwiftUI）

SwiftUIでは`@AppStorage`を使うとさらに簡単：

```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("fontSize") var fontSize = 16.0

    var body: some View {
        Toggle("ダークモード", isOn: $isDarkMode)
        Slider(value: $fontSize, in: 12...24)
    }
}
```

- 値が変更されると自動的にUserDefaultsに保存
- UserDefaultsの値が変わるとビューも自動更新

### パターン3: プロパティラッパー

```swift
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

class Settings {
    @UserDefault(key: "username", defaultValue: "ゲスト")
    static var username: String

    @UserDefault(key: "score", defaultValue: 0)
    static var score: Int
}

// 使用例
Settings.username = "太郎"
print(Settings.username)  // "太郎"
```

## UserDefaultsの仕組み

### 内部的な動作

```
┌─────────────────────────┐
│ アプリのメモリ          │
│ UserDefaults.standard   │
└──────────┬──────────────┘
           │
           │ 自動的に同期
           ↓
┌─────────────────────────┐
│ ディスクのplistファイル │
│ (永続化されたデータ)    │
└─────────────────────────┘
```

- メモリ上のキャッシュとディスクの両方を使用
- 書き込みは即座にメモリに反映、ディスクへは自動的に同期
- アプリ終了時に確実にディスクに書き込まれる

### 手動で同期する（通常は不要）

```swift
UserDefaults.standard.set("value", forKey: "key")
UserDefaults.standard.synchronize()  // 通常は不要（自動的に同期される）
```

## 使用上の注意点

### 1. サイズ制限

UserDefaultsは**小さなデータ専用**です。

| データ | UserDefaults | 推奨する方法 |
|--------|--------------|-------------|
| 設定値 | ✅ OK | - |
| ログイン状態 | ✅ OK | - |
| 少量のキャッシュ | ✅ OK | - |
| カート（このアプリ） | ✅ OK | - |
| 大量の画像 | ❌ NG | ファイルシステム |
| データベース | ❌ NG | Core Data, Realm |
| 大きなJSON | ❌ NG | ファイルシステム |

**目安**: 合計で数百KB程度まで

### 2. セキュリティ

UserDefaultsは**暗号化されていません**。

```swift
// ❌ パスワードやトークンを保存しない
UserDefaults.standard.set("password123", forKey: "password")  // 危険！

// ✅ 機密情報はKeychainを使う
KeychainWrapper.standard.set("token123", forKey: "authToken")
```

### 3. スレッドセーフティ

UserDefaultsは**スレッドセーフ**です。

```swift
// 複数のスレッドから同時にアクセスしてもOK
DispatchQueue.global().async {
    UserDefaults.standard.set("value", forKey: "key")
}
```

### 4. 初回起動時の扱い

```swift
// 初回起動かどうかチェック
let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

if !hasLaunchedBefore {
    // 初回起動時の処理
    print("アプリを初めて起動しました")

    // デフォルト値を設定
    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
    UserDefaults.standard.set(false, forKey: "isDarkMode")
}
```

### 5. デフォルト値の一括登録

```swift
func registerDefaults() {
    let defaults: [String: Any] = [
        "username": "ゲスト",
        "fontSize": 16,
        "isDarkMode": false,
        "soundEnabled": true
    ]
    UserDefaults.standard.register(defaults: defaults)
}

// AppDelegate や @main で実行
registerDefaults()
```

`register(defaults:)`は上書きしない（既に値がある場合はそちらが優先）

## デバッグ方法

### 保存されているデータを確認

```swift
// 全てのキーと値を表示
let allData = UserDefaults.standard.dictionaryRepresentation()
print(allData)

// 特定のキーを確認
if let value = UserDefaults.standard.object(forKey: "cart_items") {
    print("cart_items:", value)
} else {
    print("cart_itemsは保存されていません")
}
```

### テスト時にクリア

```swift
// 特定のキーを削除
UserDefaults.standard.removeObject(forKey: "cart_items")

// 全てのデータを削除（テスト用）
func resetUserDefaults() {
    let domain = Bundle.main.bundleIdentifier!
    UserDefaults.standard.removePersistentDomain(forName: domain)
    UserDefaults.standard.synchronize()
}
```

## 他の永続化方法との比較

| 方法 | 用途 | 容量 | 複雑さ | セキュリティ |
|------|------|------|--------|-------------|
| **UserDefaults** | 設定、簡単なデータ | 小（数百KB） | ⭐ 簡単 | 低（暗号化なし） |
| **Keychain** | パスワード、トークン | 小 | ⭐⭐ 中 | 高（暗号化） |
| **File System** | 画像、大きなファイル | 大 | ⭐⭐ 中 | 低 |
| **Core Data** | 構造化されたデータ | 大 | ⭐⭐⭐⭐ 難 | 低（暗号化可） |
| **Realm** | データベース | 大 | ⭐⭐⭐ 中 | 低（暗号化可） |
| **CloudKit** | クラウド同期 | 大 | ⭐⭐⭐⭐ 難 | 中 |

## まとめ

### UserDefaultsの特徴

| 特徴 | 説明 |
|------|------|
| **簡単** | コード数行で保存・読み込み可能 |
| **永続化** | アプリ終了後も残る |
| **キーバリュー** | 辞書のようにキーで値を管理 |
| **スレッドセーフ** | 複数スレッドから安全にアクセス可能 |
| **自動同期** | メモリとディスクを自動的に同期 |
| **小さなデータ専用** | 大量データには向かない |
| **暗号化なし** | 機密情報の保存には不向き |

### このアプリでの使い方

```swift
// Cart.swift での使用パターン
class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            saveItems()  // 変更のたびに保存
        }
    }

    init() {
        loadItems()  // 起動時に復元
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

**結果**: カートに商品を追加してアプリを終了しても、再起動時にカートの内容が復元される！
