import Foundation

@MainActor
class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchProducts() async {
        guard let url = URL(string: "https://dummyjson.com/products") else {
            errorMessage = "無効なURL"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
            self.products = decoded.products
            print("✅ 商品取得成功: \(decoded.products.count)件")
        } catch let decodingError as DecodingError {
            errorMessage = "データ解析エラー"
            print("❌ デコードエラー:", decodingError)
        } catch {
            errorMessage = "ネットワークエラー"
            print("❌ API取得エラー:", error)
        }

        isLoading = false
    }
}
