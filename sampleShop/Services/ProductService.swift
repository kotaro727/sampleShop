import Foundation

@MainActor
class ProductService: ObservableObject {
    @Published var products: [Product] = []

    func fetchProducts() async {
        guard let url = URL(string: "https://dummyjson.com/products") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
            self.products = decoded.products
        } catch {
            print("API取得エラー:", error)
        }
    }
}
