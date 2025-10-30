//
//  Product.swift
//  sampleShop
//
//  Created by 鈴木光太郎 on 2025/10/30.
//

import Foundation

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
    let imageName: String
}

let sampleProducts = [
    Product(name: "Tシャツ", price: 2500, imageName: "tshirt"),
    Product(name: "スニーカー", price: 8500, imageName: "sneakers"),
    Product(name: "キャップ", price: 1800, imageName: "cap")
]
