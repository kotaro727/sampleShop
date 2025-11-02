# ViewModel & MVVM解説

「重い処理はViewの外で行う」とは、具体的には**ViewModel**を使うことを指します。これはMVVM（Model-View-ViewModel）アーキテクチャパターンの一部です。

## MVVM パターンとは

### 3つの層

```
Model ←→ ViewModel ←→ View
```

| 層 | 役割 | SwiftUIでの実装 |
|---|------|----------------|
| **Model** | データ、ビジネスロジック | `struct Product`, `class Cart` |
| **ViewModel** | View用のデータ加工、状態管理 | `class ProductService: ObservableObject` |
| **View** | 見た目の記述のみ | `struct ContentView: View` |

### データの流れ

```
User → View → ViewModel → Model
         ↑        ↓
         └────────┘
      (自動的に更新)
```

## このアプリでの実装例

### 現在の構造

実は、このアプリは**すでにMVVMパターン**を採用しています！

#### Model層

[ProductResponse.swift](sampleShop/Model/ProductResponse.swift)
```swift
// データ構造の定義
struct Product: Identifiable, Decodable {
    let id: Int
    let title: String
    let price: Double
    let thumbnail: String
}
```

[Cart.swift](sampleShop/Model/Cart.swift)
```swift
// ビジネスロジック（カートの操作）
class Cart: ObservableObject {
    @Published var items: [Product] = []

    func add(_ product: Product) {
        items.append(product)
    }

    func remove(_ product: Product) {
        items.removeAll { $0.id == product.id }
    }
}
```

#### ViewModel層

[ProductService.swift](sampleShop/Services/ProductService.swift)
```swift
// これがViewModel！
@MainActor
class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 重い処理（API通信）
    func fetchProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
            self.products = decoded.products
        } catch {
            errorMessage = "ネットワークエラー"
        }

        isLoading = false
    }
}
```

#### View層

[ContentView.swift](sampleShop/ContentView.swift)
```swift
struct ContentView: View {
    @StateObject private var service = ProductService()  // ViewModel
    @EnvironmentObject var cart: Cart                    // Model

    var body: some View {
        // 見た目の記述のみ
        NavigationStack {
            if service.isLoading {
                ProgressView("読み込み中...")
            } else {
                List(service.products) { product in
                    // ...
                }
            }
        }
        .task {
            await service.fetchProducts()  // ViewModelに処理を委譲
        }
    }
}
```

## なぜViewとViewModelを分離するのか

### ❌ 悪い例: Viewに重い処理を書く

```swift
struct ProductListView: View {
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List(products) { product in
            Text(product.title)
        }
        .task {
            // ❌ View内で直接API通信
            isLoading = true
            guard let url = URL(string: "https://dummyjson.com/products") else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
                products = decoded.products
            } catch {
                errorMessage = "エラー"
            }

            isLoading = false
        }
    }
}
```

**問題点**:
1. ❌ Viewが長くなる（見た目とロジックが混在）
2. ❌ テストしにくい（Viewをテストできない）
3. ❌ 再利用できない（他のViewで同じコードを書くことに）
4. ❌ 責任が多すぎる（見た目とデータ取得を両方やっている）

### ✅ 良い例: ViewModelに処理を分離

```swift
// ViewModel: ロジックと状態管理
@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchProducts() async {
        isLoading = true
        // ... API通信の処理
        isLoading = false
    }

    func retry() {
        Task {
            await fetchProducts()
        }
    }
}

// View: 見た目の記述のみ
struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.errorMessage {
            VStack {
                Text(error)
                Button("再試行") {
                    viewModel.retry()
                }
            }
        } else {
            List(viewModel.products) { product in
                Text(product.title)
            }
        }
        .task {
            await viewModel.fetchProducts()
        }
    }
}
```

**メリット**:
1. ✅ Viewがシンプル（見た目の記述だけ）
2. ✅ ViewModelを個別にテスト可能
3. ✅ 再利用しやすい
4. ✅ 責任が明確（Viewは見た目、ViewModelはロジック）

## ViewModelの役割

### 1. データの加工・変換

```swift
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []

    // 生のデータ → View用に加工
    var displayProducts: [DisplayProduct] {
        products.map { product in
            DisplayProduct(
                id: product.id,
                title: product.title,
                formattedPrice: "¥\(String(format: "%.0f", product.price))",
                imageURL: URL(string: product.thumbnail)
            )
        }
    }

    var totalPrice: String {
        let total = products.reduce(0) { $0 + $1.price }
        return "¥\(String(format: "%.0f", total))"
    }

    var isEmpty: Bool {
        products.isEmpty
    }
}

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        if viewModel.isEmpty {
            Text("商品がありません")
        } else {
            VStack {
                List(viewModel.displayProducts) { product in
                    Text(product.title)
                    Text(product.formattedPrice)
                }
                Text("合計: \(viewModel.totalPrice)")
            }
        }
    }
}
```

### 2. ビジネスロジック

```swift
class CartViewModel: ObservableObject {
    @Published var items: [Product] = []

    // ビジネスロジック: カートに追加
    func addToCart(_ product: Product) {
        // 在庫チェック
        guard canAddToCart(product) else {
            showError("在庫がありません")
            return
        }

        // 重複チェック
        if items.contains(where: { $0.id == product.id }) {
            showError("すでにカートに入っています")
            return
        }

        items.append(product)
        saveToUserDefaults()
    }

    private func canAddToCart(_ product: Product) -> Bool {
        // 在庫確認のロジック
        return true
    }

    private func saveToUserDefaults() {
        // 保存処理
    }

    private func showError(_ message: String) {
        // エラー表示
    }
}
```

### 3. 非同期処理の管理

```swift
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false

    // 複数のAPI呼び出しを管理
    func loadData() async {
        isLoading = true

        async let products = fetchProducts()
        async let categories = fetchCategories()
        async let recommendations = fetchRecommendations()

        // 並列実行して結果を待つ
        let (p, c, r) = await (products, categories, recommendations)

        self.products = p
        // カテゴリーとレコメンデーションも処理...

        isLoading = false
    }

    private func fetchProducts() async -> [Product] {
        // API呼び出し
    }

    private func fetchCategories() async -> [Category] {
        // API呼び出し
    }

    private func fetchRecommendations() async -> [Product] {
        // API呼び出し
    }
}
```

### 4. 状態管理

```swift
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [Product] = []
    @Published var isSearching = false
    @Published var searchHistory: [String] = []

    func search() async {
        guard !searchText.isEmpty else { return }

        isSearching = true

        // 検索実行
        results = await performSearch(searchText)

        // 履歴に追加
        if !searchHistory.contains(searchText) {
            searchHistory.insert(searchText, at: 0)
            if searchHistory.count > 10 {
                searchHistory.removeLast()
            }
        }

        isSearching = false
    }

    func clearHistory() {
        searchHistory.removeAll()
    }

    private func performSearch(_ query: String) async -> [Product] {
        // API検索
    }
}
```

## 命名規則とパターン

### ViewModelの命名

```swift
// パターン1: [機能名]ViewModel
class ProductListViewModel: ObservableObject { }
class ProductDetailViewModel: ObservableObject { }
class CartViewModel: ObservableObject { }

// パターン2: [機能名]Service（このアプリの例）
class ProductService: ObservableObject { }

// パターン3: [機能名]Store
class CartStore: ObservableObject { }
```

**どれでもOK**: チーム内で統一されていれば問題ありません。

### Viewとの対応

```swift
// View
struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
}

// View
struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
}
```

## 実装パターン

### パターン1: ViewModelをViewが所有

```swift
struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()

    var body: some View {
        List(viewModel.products) { product in
            Text(product.title)
        }
        .task {
            await viewModel.fetchProducts()
        }
    }
}
```

**用途**: そのViewでのみ使う状態

### パターン2: ViewModelを注入（Dependency Injection）

```swift
struct ProductListView: View {
    @ObservedObject var viewModel: ProductListViewModel

    var body: some View {
        List(viewModel.products) { product in
            Text(product.title)
        }
    }
}

// 使用例
struct ParentView: View {
    @StateObject private var viewModel = ProductListViewModel()

    var body: some View {
        VStack {
            ProductListView(viewModel: viewModel)
            SummaryView(viewModel: viewModel)  // 同じViewModelを共有
        }
    }
}
```

**用途**: 複数のViewで共有、テスト時にモックを注入

### パターン3: EnvironmentObjectで共有

```swift
@main
struct MyApp: App {
    @StateObject private var cartViewModel = CartViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cartViewModel)
        }
    }
}

struct ProductDetailView: View {
    @EnvironmentObject var cartViewModel: CartViewModel

    var body: some View {
        Button("カートに追加") {
            cartViewModel.addToCart(product)
        }
    }
}
```

**用途**: アプリ全体で共有する状態（このアプリのCart）

## テストの容易性

### ViewModelはテストしやすい

```swift
// ViewModelのテスト
class ProductViewModelTests: XCTestCase {
    func testFetchProducts() async {
        // Arrange
        let viewModel = ProductViewModel()

        // Act
        await viewModel.fetchProducts()

        // Assert
        XCTAssertFalse(viewModel.products.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testErrorHandling() async {
        let viewModel = ProductViewModel()
        // ネットワークエラーをシミュレート

        await viewModel.fetchProducts()

        XCTAssertNotNil(viewModel.errorMessage)
    }
}
```

### Viewのテストは不要（または最小限）

```swift
// Viewは見た目だけなのでテスト不要
struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        // ロジックがないのでテスト不要
        List(viewModel.products) { product in
            Text(product.title)
        }
    }
}
```

## このアプリをMVVMで整理すると

### 現在の構造

```
Model:
├── Product (struct)
├── ProductResponse (struct)
└── Cart (class) - ビジネスロジック含む

ViewModel:
└── ProductService (class)

View:
├── ContentView
├── ProductDetailView
└── CartView
```

### より明確なMVVM構造に改善する例

```swift
// ViewModel層を整理
class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productService = ProductService()

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            products = try await productService.fetchProducts()
        } catch {
            errorMessage = "商品の読み込みに失敗しました"
        }

        isLoading = false
    }

    func retry() {
        Task {
            await loadProducts()
        }
    }
}

// Service層（ネットワーク処理のみ）
class ProductService {
    func fetchProducts() async throws -> [Product] {
        let url = URL(string: "https://dummyjson.com/products")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ProductResponse.self, from: data)
        return response.products
    }
}

// View
struct ContentView: View {
    @StateObject private var viewModel = ProductListViewModel()

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.errorMessage {
            ErrorView(message: error, retry: viewModel.retry)
        } else {
            ProductList(products: viewModel.products)
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}
```

## まとめ

### ViewModelとは

| 特徴 | 説明 |
|------|------|
| **定義** | Viewとモデルの間の仲介役 |
| **実装** | `ObservableObject` を継承したclass |
| **役割** | データ加工、ビジネスロジック、状態管理 |
| **Viewとの関係** | `@StateObject` または `@ObservedObject` で接続 |

### なぜViewModelを使うのか

| 理由 | 説明 |
|------|------|
| **関心の分離** | View = 見た目、ViewModel = ロジック |
| **テスタビリティ** | ViewModelは個別にテスト可能 |
| **再利用性** | 複数のViewで同じViewModelを使える |
| **保守性** | コードが整理され、理解しやすい |

### Viewの責務

```swift
// ✅ Viewがやるべきこと
var body: some View {
    VStack {
        Text(viewModel.title)      // データの表示
        Button("更新") {
            viewModel.refresh()     // ViewModelのメソッド呼び出し
        }
    }
    .padding()                     // レイアウト調整
}

// ❌ Viewがやるべきでないこと
var body: some View {
    // API通信
    // データ加工
    // ビジネスロジック
    // 複雑な計算
}
```

### 実践的なアドバイス

1. **Viewは薄く保つ**: ロジックが見えたらViewModelへ
2. **ViewModelは1View1つが基本**: 複雑になったら分割
3. **命名規則を統一**: チーム内で一貫性を持つ
4. **テストを書く**: ViewModelはテストしやすい設計

**「重い処理はViewの外で」= ViewModelを使おう！**
