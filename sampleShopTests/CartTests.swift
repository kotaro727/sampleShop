//
//  CartTests.swift
//  sampleShopTests
//
//  Tests for Cart Model/ViewModel
//

import Testing
import Foundation
@testable import sampleShop

struct CartTests {

    // テスト用のサンプル商品を作成
    func createSampleProduct(id: Int = 1, title: String = "Test Product", price: Double = 100.0) -> Product {
        return Product(id: id, title: title, price: price, thumbnail: "https://example.com/image.jpg")
    }

    // MARK: - 初期状態のテスト

    @Test("初期状態ではカートが空である")
    func testInitialState() {
        // Arrange & Act
        // テスト用のメモリ内ストレージを注入
        let cart = Cart(storage: InMemoryCartStorage())

        // Assert
        #expect(cart.items.isEmpty)
    }

    // MARK: - 商品追加のテスト

    @Test("商品を1つ追加できる")
    func testAddSingleProduct() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product = createSampleProduct(id: 1, title: "iPhone", price: 999.0)

        // Act
        cart.add(product)

        // Assert
        #expect(cart.items.count == 1)
        #expect(cart.items.first?.id == 1)
        #expect(cart.items.first?.title == "iPhone")
        #expect(cart.items.first?.price == 999.0)
    }

    @Test("複数の商品を追加できる")
    func testAddMultipleProducts() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product1 = createSampleProduct(id: 1, title: "iPhone", price: 999.0)
        let product2 = createSampleProduct(id: 2, title: "iPad", price: 599.0)
        let product3 = createSampleProduct(id: 3, title: "MacBook", price: 1999.0)

        // Act
        cart.add(product1)
        cart.add(product2)
        cart.add(product3)

        // Assert
        #expect(cart.items.count == 3)

        let titles = cart.items.map { $0.title }
        #expect(titles.contains("iPhone"))
        #expect(titles.contains("iPad"))
        #expect(titles.contains("MacBook"))
    }

    @Test("同じ商品を複数回追加できる")
    func testAddDuplicateProducts() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product = createSampleProduct(id: 1, title: "iPhone", price: 999.0)

        // Act
        cart.add(product)
        cart.add(product)
        cart.add(product)

        // Assert
        #expect(cart.items.count == 3, "同じ商品を3回追加したので3個になるはず")

        let allIdsMatch = cart.items.allSatisfy { $0.id == 1 }
        #expect(allIdsMatch, "全て同じ商品IDであるはず")
    }

    // MARK: - 商品削除のテスト

    @Test("商品を削除できる")
    func testRemoveProduct() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product1 = createSampleProduct(id: 1, title: "iPhone", price: 999.0)
        let product2 = createSampleProduct(id: 2, title: "iPad", price: 599.0)

        cart.add(product1)
        cart.add(product2)

        // Act
        cart.remove(product1)

        // Assert
        #expect(cart.items.count == 1)
        #expect(cart.items.first?.id == 2)
        #expect(cart.items.first?.title == "iPad")
    }

    @Test("同じ商品が複数ある場合、全て削除される")
    func testRemoveAllDuplicates() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product = createSampleProduct(id: 1, title: "iPhone", price: 999.0)

        cart.add(product)
        cart.add(product)
        cart.add(product)

        #expect(cart.items.count == 3)

        // Act
        cart.remove(product)

        // Assert
        #expect(cart.items.isEmpty, "同じIDの商品は全て削除されるはず")
    }

    @Test("存在しない商品を削除しようとしてもエラーにならない")
    func testRemoveNonExistentProduct() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product1 = createSampleProduct(id: 1, title: "iPhone", price: 999.0)
        let product2 = createSampleProduct(id: 2, title: "iPad", price: 599.0)

        cart.add(product1)

        // Act
        cart.remove(product2) // 存在しない商品を削除

        // Assert
        #expect(cart.items.count == 1, "何も削除されないはず")
        #expect(cart.items.first?.id == 1)
    }

    @Test("空のカートから削除してもエラーにならない")
    func testRemoveFromEmptyCart() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product = createSampleProduct(id: 1, title: "iPhone", price: 999.0)

        // Act
        cart.remove(product)

        // Assert
        #expect(cart.items.isEmpty)
    }

    // MARK: - 追加と削除の組み合わせテスト

    @Test("商品の追加と削除を繰り返す")
    func testAddAndRemoveCombination() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let product1 = createSampleProduct(id: 1, title: "iPhone", price: 999.0)
        let product2 = createSampleProduct(id: 2, title: "iPad", price: 599.0)
        let product3 = createSampleProduct(id: 3, title: "MacBook", price: 1999.0)

        // Act & Assert
        cart.add(product1)
        #expect(cart.items.count == 1)

        cart.add(product2)
        #expect(cart.items.count == 2)

        cart.remove(product1)
        #expect(cart.items.count == 1)
        #expect(cart.items.first?.id == 2)

        cart.add(product3)
        #expect(cart.items.count == 2)

        cart.remove(product2)
        #expect(cart.items.count == 1)
        #expect(cart.items.first?.id == 3)

        cart.remove(product3)
        #expect(cart.items.isEmpty)
    }

    // MARK: - 永続化のテスト

    @Test("カートのデータが永続化される")
    func testCartPersistence() async throws {
        // Arrange
        let storage = InMemoryCartStorage()
        let product = createSampleProduct(id: 1, title: "iPhone", price: 999.0)

        // Act
        // カート1: 商品を追加して保存
        let cart1 = Cart(storage: storage)
        cart1.add(product)

        // カート2: 同じストレージから読み込み
        let cart2 = Cart(storage: storage)

        // Assert
        #expect(cart2.items.count == 1, "永続化されたデータが読み込まれる")
        #expect(cart2.items.first?.id == 1)
        #expect(cart2.items.first?.title == "iPhone")
        #expect(cart2.items.first?.price == 999.0)
    }

    // MARK: - データ整合性のテスト

    @Test("商品データが正しく保持される")
    func testProductDataIntegrity() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())
        let originalProduct = createSampleProduct(
            id: 123,
            title: "Test Product with Special Characters: 日本語 & Emoji 🎉",
            price: 12345.67
        )

        // Act
        cart.add(originalProduct)

        // Assert
        guard let storedProduct = cart.items.first else {
            Issue.record("商品が取得できませんでした")
            return
        }

        #expect(storedProduct.id == originalProduct.id)
        #expect(storedProduct.title == originalProduct.title)
        #expect(storedProduct.price == originalProduct.price)
        #expect(storedProduct.thumbnail == originalProduct.thumbnail)
    }

    @Test("価格が正しく保持される")
    func testPriceHandling() {
        // Arrange
        let cart = Cart(storage: InMemoryCartStorage())

        // 様々な価格パターンをテスト
        let products = [
            createSampleProduct(id: 1, title: "Free Item", price: 0.0),
            createSampleProduct(id: 2, title: "Cheap Item", price: 0.99),
            createSampleProduct(id: 3, title: "Normal Item", price: 99.99),
            createSampleProduct(id: 4, title: "Expensive Item", price: 9999.99)
        ]

        // Act
        products.forEach { cart.add($0) }

        // Assert
        #expect(cart.items.count == 4)

        #expect(cart.items[0].price == 0.0)
        #expect(cart.items[1].price == 0.99)
        #expect(cart.items[2].price == 99.99)
        #expect(cart.items[3].price == 9999.99)
    }
}
