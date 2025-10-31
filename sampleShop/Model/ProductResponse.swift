import Foundation

struct ProductResponse: Decodable {
    let products: [Product]
}

struct Product: Identifiable, Decodable {
    let id: Int
    let title: String
    let price: Int
    let thumbnail: String
}
