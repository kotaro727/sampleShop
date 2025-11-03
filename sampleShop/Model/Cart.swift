import Foundation

class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            storage.save(items)
        }
    }

    private let storage: CartStorageProtocol

    // Dependency Injection
    // デフォルト引数でUserDefaultsを使用（本番環境）
    // テスト時は別のストレージを注入可能
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
