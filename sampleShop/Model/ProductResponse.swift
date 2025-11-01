import Foundation

struct ProductResponse: Codable {
    let products: [Product]
}

struct Product: Identifiable, Codable {
    let id: Int
    let title: String
    let price: Double
    let thumbnail: String
}
