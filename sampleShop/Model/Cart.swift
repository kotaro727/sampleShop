import Foundation

class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            saveItems()
        }
    }

    private let storageKey = "cart_items"

    init() {
        loadItems()
    }

    func add(_ product: Product) {
        items.append(product)
    }

    func remove(_ product: Product) {
        items.removeAll { $0.id == product.id }
    }

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("保存成功:", items)
        } catch {
            print("保存失敗:", error)
        }
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            items = try JSONDecoder().decode([Product].self, from: data)
        } catch {
            print("読み込み失敗:", error)
        }
    }
}
