# テスタビリティとDependency Injection

## 現在の問題

### Cartクラスの実装

[Cart.swift](../sampleShop/Model/Cart.swift)

```swift
class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            saveItems()  // UserDefaultsに保存
        }
    }

    private let storageKey = "cart_items"

    init() {
        loadItems()  // UserDefaultsから読み込み
    }

    private func saveItems() {
        let data = try? JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        items = try? JSONDecoder().decode([Product].self, from: data)
    }
}
```

### テストでの問題

```swift
@Test("初期状態ではカートが空である")
func testInitialState() {
    let cart = Cart()  // loadItems()が呼ばれる

    #expect(cart.items.isEmpty)  // ❌ 失敗！
    // 理由: UserDefaultsに前回のテストのデータが残っている
}
```

**なぜ失敗するか**:
1. `Cart()`を作成
2. `init()`で`loadItems()`が実行される
3. UserDefaultsに前のテストで保存したデータがある
4. `cart.items`が空じゃない！

## これは設計が悪い？

### 答え: いいえ、実用上は問題ありません

**実際のアプリでは**:
- ✅ カートの永続化は必要な機能
- ✅ アプリ起動時に前回のカートを復元するのは正しい動作
- ✅ ユーザー体験として優れている

**問題は**:
- ❌ テストが独立していない（副作用がある）
- ❌ UserDefaultsというグローバルな状態に依存している
- ❌ テスト時と本番時で動作を変えられない

## 解決策: Dependency Injection（依存性の注入）

### パターン1: ストレージを抽象化する（推奨）

#### ステップ1: プロトコルを定義

```swift
// ストレージの抽象化
protocol CartStorageProtocol {
    func save(_ items: [Product])
    func load() -> [Product]
}
```

#### ステップ2: 本番用の実装

```swift
// 本番用: UserDefaultsを使う実装
class UserDefaultsCartStorage: CartStorageProtocol {
    private let storageKey = "cart_items"

    func save(_ items: [Product]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("保存成功:", items)
        } catch {
            print("保存失敗:", error)
        }
    }

    func load() -> [Product] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Product].self, from: data)
        } catch {
            print("読み込み失敗:", error)
            return []
        }
    }
}
```

#### ステップ3: テスト用の実装

```swift
// テスト用: メモリ内のみ（永続化しない）
class InMemoryCartStorage: CartStorageProtocol {
    private var items: [Product] = []

    func save(_ items: [Product]) {
        self.items = items
        print("メモリに保存:", items)
    }

    func load() -> [Product] {
        return items
    }
}
```

#### ステップ4: Cartクラスを修正

```swift
class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            storage.save(items)
        }
    }

    private let storage: CartStorageProtocol

    // Dependency Injection
    init(storage: CartStorageProtocol = UserDefaultsCartStorage()) {
        self.storage = storage
        self.items = storage.load()
    }

    func add(_ product: Product) {
        items.append(product)
    }

    func remove(_ product: Product) {
        items.removeAll { $0.id == product.id }
    }
}
```

#### ステップ5: テストを修正

```swift
@Test("初期状態ではカートが空である")
func testInitialState() {
    // テスト用のストレージを注入
    let cart = Cart(storage: InMemoryCartStorage())

    #expect(cart.items.isEmpty)  // ✅ 成功！
}

@Test("商品を追加できる")
func testAddProduct() {
    let storage = InMemoryCartStorage()
    let cart = Cart(storage: storage)
    let product = createSampleProduct()

    cart.add(product)

    #expect(cart.items.count == 1)
}
```

#### ステップ6: 本番コードは変更不要

```swift
// アプリ側: デフォルトでUserDefaultsが使われる
@main
struct sampleShopApp: App {
    @StateObject var cart = Cart()  // デフォルトでUserDefaultsCartStorage

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cart)
        }
    }
}
```

### パターン2: UserDefaultsをラップする（シンプル）

```swift
class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            saveItems()
        }
    }

    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "cart_items"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        loadItems()
    }

    private func saveItems() {
        let data = try? JSONEncoder().encode(items)
        userDefaults.set(data, forKey: storageKey)
    }

    private func loadItems() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        items = try? JSONDecoder().decode([Product].self, from: data)
    }
}

// テストコード
@Test("初期状態ではカートが空である")
func testInitialState() {
    // テスト用のUserDefaultsを作成
    let testDefaults = UserDefaults(suiteName: "test_suite")!
    testDefaults.removePersistentDomain(forName: "test_suite")

    let cart = Cart(userDefaults: testDefaults, storageKey: "test_cart")

    #expect(cart.items.isEmpty)  // ✅ 成功！
}
```

### パターン3: テストでUserDefaultsをクリアする（簡易版）

```swift
// テストコード
struct CartTests {
    // 各テストの前にUserDefaultsをクリア
    func createFreshCart() -> Cart {
        // UserDefaultsをクリア
        UserDefaults.standard.removeObject(forKey: "cart_items")

        return Cart()
    }

    @Test("初期状態ではカートが空である")
    func testInitialState() {
        let cart = createFreshCart()

        #expect(cart.items.isEmpty)  // ✅ 成功！
    }
}
```

**注意**: この方法は簡単ですが、テストが実際のUserDefaultsを使うため、並列実行で問題が起きる可能性があります。

## Dependency Injectionのメリット

### 1. テストしやすい

```swift
// ✅ テスト用のモックを注入できる
let cart = Cart(storage: InMemoryCartStorage())

// ❌ グローバルなUserDefaultsに依存
let cart = Cart()  // UserDefaultsが勝手に使われる
```

### 2. 柔軟性が高い

```swift
// 本番: UserDefaults
let cart = Cart(storage: UserDefaultsCartStorage())

// テスト: メモリ内
let cart = Cart(storage: InMemoryCartStorage())

// 将来: CloudKitに変更したい
let cart = Cart(storage: CloudKitCartStorage())

// ログ機能付き
let cart = Cart(storage: LoggingCartStorage(
    wrapping: UserDefaultsCartStorage()
))
```

### 3. 並列テストが安全

```swift
// テスト1: 独自のストレージ
let cart1 = Cart(storage: InMemoryCartStorage())

// テスト2: 別のストレージ
let cart2 = Cart(storage: InMemoryCartStorage())

// お互いに影響しない！
```

## 実装の比較

### Before（現在の実装）

```swift
class Cart: ObservableObject {
    init() {
        loadItems()  // UserDefaultsに直接依存
    }

    private func saveItems() {
        UserDefaults.standard.set(...)  // ハードコード
    }
}

// テスト
let cart = Cart()  // UserDefaultsが使われる（変更不可）
```

**問題**:
- UserDefaultsへの依存がハードコード
- テスト時に動作を変えられない
- テストが互いに影響し合う

### After（DI適用後）

```swift
class Cart: ObservableObject {
    private let storage: CartStorageProtocol

    init(storage: CartStorageProtocol = UserDefaultsCartStorage()) {
        self.storage = storage
        self.items = storage.load()
    }

    private func saveItems() {
        storage.save(items)  // 抽象化されたストレージ
    }
}

// 本番
let cart = Cart()  // デフォルトでUserDefaults

// テスト
let cart = Cart(storage: InMemoryCartStorage())  // メモリ内のみ
```

**メリット**:
- ストレージの実装を差し替え可能
- テストが独立している
- 本番コードは変更不要（デフォルト引数）

## 実際のコード例

### 改善したCart.swift

```swift
// ストレージプロトコル
protocol CartStorageProtocol {
    func save(_ items: [Product])
    func load() -> [Product]
}

// UserDefaults実装
class UserDefaultsCartStorage: CartStorageProtocol {
    private let storageKey = "cart_items"

    func save(_ items: [Product]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("保存失敗:", error)
        }
    }

    func load() -> [Product] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([Product].self, from: data) else {
            return []
        }
        return items
    }
}

// メモリ内実装（テスト用）
class InMemoryCartStorage: CartStorageProtocol {
    private var storedItems: [Product] = []

    func save(_ items: [Product]) {
        storedItems = items
    }

    func load() -> [Product] {
        return storedItems
    }
}

// Cartクラス
class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            storage.save(items)
        }
    }

    private let storage: CartStorageProtocol

    init(storage: CartStorageProtocol = UserDefaultsCartStorage()) {
        self.storage = storage
        self.items = storage.load()
    }

    func add(_ product: Product) {
        items.append(product)
    }

    func remove(_ product: Product) {
        items.removeAll { $0.id == product.id }
    }
}
```

### 改善したCartTests.swift

```swift
struct CartTests {
    func createSampleProduct(id: Int = 1, title: String = "Test", price: Double = 100) -> Product {
        Product(id: id, title: title, price: price, thumbnail: "https://example.com/image.jpg")
    }

    @Test("初期状態ではカートが空である")
    func testInitialState() {
        // テスト用ストレージを注入
        let cart = Cart(storage: InMemoryCartStorage())

        #expect(cart.items.isEmpty)  // ✅ 成功！
    }

    @Test("商品を追加できる")
    func testAddProduct() {
        let cart = Cart(storage: InMemoryCartStorage())
        let product = createSampleProduct()

        cart.add(product)

        #expect(cart.items.count == 1)
        #expect(cart.items.first?.id == 1)
    }

    @Test("永続化が機能する")
    func testPersistence() {
        let storage = InMemoryCartStorage()
        let product = createSampleProduct()

        // カート1: 商品を追加
        let cart1 = Cart(storage: storage)
        cart1.add(product)

        // カート2: 同じストレージから読み込み
        let cart2 = Cart(storage: storage)

        #expect(cart2.items.count == 1, "永続化されたデータが読み込まれる")
        #expect(cart2.items.first?.id == 1)
    }
}
```

## まとめ

### 現在の設計は悪くない

| 観点 | 評価 |
|------|------|
| **実用性** | ✅ 完璧（永続化が機能している） |
| **ユーザー体験** | ✅ 優れている（カートが保持される） |
| **コードの簡潔さ** | ✅ シンプル |
| **テスタビリティ** | ⚠️ 改善の余地あり |

### Dependency Injectionで改善できること

| メリット | 説明 |
|---------|------|
| **テストが独立** | 各テストが独自のストレージを持つ |
| **並列実行可能** | テスト同士が干渉しない |
| **柔軟性** | ストレージを簡単に差し替え可能 |
| **本番コードは変更不要** | デフォルト引数で互換性を保つ |

### どちらを選ぶべきか

```
小規模アプリ、学習目的
  → 現在の実装でOK（シンプルで理解しやすい）

テストを重視、チーム開発、大規模アプリ
  → DI版を採用（保守性・テスタビリティが高い）

迷ったら
  → まず現在の実装で動かす
  → テストで困ったらDIに移行
```

### 重要な教訓

**「動くコード」と「テストしやすいコード」は別物**

- 動くコード: 機能が正しく動作する
- テストしやすいコード: 依存関係が明示的、差し替え可能

**あなたのコードは「動くコード」です。それは素晴らしいことです。**

テストを書くことで「テストしやすくする改善点」が見つかった、これはTDDの本質です！

### 次のステップ

1. **今は**: 現在の実装のまま使い続ける（問題ない）
2. **学習したら**: Dependency Injectionを試してみる
3. **必要になったら**: リファクタリングする

**設計は悪くありません。むしろ、テストを書くことで改善点が見えたのは成長の証です！**
