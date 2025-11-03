//
//  ProductServiceTests.swift
//  sampleShopTests
//
//  Tests for ProductService ViewModel
//

import Testing
import Foundation
@testable import sampleShop

@MainActor
struct ProductServiceTests {

    // MARK: - 初期状態のテスト

    @Test("初期状態では商品リストが空である")
    func testInitialState() async throws {
        // Arrange & Act
        let service = ProductService()

        // Assert
        #expect(service.products.isEmpty)
        #expect(service.isLoading == false)
        #expect(service.errorMessage == nil)
    }

    // MARK: - API取得のテスト

    @Test("商品取得が成功する")
    func testFetchProductsSuccess() async throws {
        // Arrange
        let service = ProductService()

        // Act
        await service.fetchProducts()

        // Assert
        #expect(!service.products.isEmpty, "商品が取得できているはず")
        #expect(service.isLoading == false, "ローディングが終了しているはず")
        #expect(service.errorMessage == nil, "エラーメッセージはないはず")

        // 最初の商品が正しく取得できているか確認
        if let firstProduct = service.products.first {
            #expect(firstProduct.id > 0)
            #expect(!firstProduct.title.isEmpty)
            #expect(firstProduct.price > 0)
        }
    }

    @Test("ローディング状態が正しく管理される")
    func testLoadingState() async throws {
        // Arrange
        let service = ProductService()

        // Act: 非同期タスクを開始
        let loadingTask = Task {
            await service.fetchProducts()
        }

        // 少し待ってからローディング状態をチェック（実際の実装では即座に完了する可能性もある）
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒

        // Assert: fetchProducts完了を待つ
        await loadingTask.value

        // 完了後はローディングがfalseになっているはず
        #expect(service.isLoading == false)
    }

    // MARK: - データ構造のテスト

    @Test("取得した商品データが正しい構造を持つ")
    func testProductDataStructure() async throws {
        // Arrange
        let service = ProductService()

        // Act
        await service.fetchProducts()

        // Assert
        guard let product = service.products.first else {
            Issue.record("商品が取得できませんでした")
            return
        }

        // 各フィールドが適切な値を持っているか
        #expect(product.id > 0, "IDは正の整数であるべき")
        #expect(!product.title.isEmpty, "タイトルは空でないべき")
        #expect(product.price >= 0, "価格は0以上であるべき")
        #expect(!product.thumbnail.isEmpty, "サムネイルURLは空でないべき")

        // URLが有効か確認
        let url = URL(string: product.thumbnail)
        #expect(url != nil, "サムネイルは有効なURLであるべき")
    }

    @Test("複数の商品が取得できる")
    func testMultipleProducts() async throws {
        // Arrange
        let service = ProductService()

        // Act
        await service.fetchProducts()

        // Assert
        #expect(service.products.count > 1, "複数の商品が取得できているはず")

        // IDがユニークであることを確認
        let ids = service.products.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count, "商品IDは重複していないはず")
    }

    // MARK: - 複数回呼び出しのテスト

    @Test("fetchProductsを複数回呼び出しても正常に動作する")
    func testMultipleFetchCalls() async throws {
        // Arrange
        let service = ProductService()

        // Act
        await service.fetchProducts()
        let firstCount = service.products.count

        await service.fetchProducts()
        let secondCount = service.products.count

        // Assert
        #expect(firstCount > 0, "最初の呼び出しで商品が取得できている")
        #expect(secondCount > 0, "2回目の呼び出しでも商品が取得できている")
        #expect(firstCount == secondCount, "取得件数は同じはず")
    }
}
