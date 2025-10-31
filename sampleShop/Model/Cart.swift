import Foundation

class Cart: ObservableObject {
    @Published var items: [Product] = []
    
    func add(_ product: Product) {
        items.append(product)
    }
}
