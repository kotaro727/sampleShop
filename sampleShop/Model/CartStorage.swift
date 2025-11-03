//
//  CartStorage.swift
//  sampleShop
//
//  ストレージの抽象化（Dependency Injection用）
//

import Foundation

// MARK: - プロトコル

protocol CartStorageProtocol {
    func save(_ items: [Product])
    func load() -> [Product]
}

// MARK: - UserDefaults実装（本番用）

class UserDefaultsCartStorage: CartStorageProtocol {
    private let storageKey: String
    private let userDefaults: UserDefaults

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "cart_items"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    func save(_ items: [Product]) {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: storageKey)
            print("✅ カート保存成功: \(items.count)件")
        } catch {
            print("❌ カート保存失敗:", error)
        }
    }

    func load() -> [Product] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            print("📦 カートデータなし（初回起動）")
            return []
        }

        do {
            let items = try JSONDecoder().decode([Product].self, from: data)
            print("✅ カート読み込み成功: \(items.count)件")
            return items
        } catch {
            print("❌ カート読み込み失敗:", error)
            return []
        }
    }
}

// MARK: - メモリ内実装（テスト用）

class InMemoryCartStorage: CartStorageProtocol {
    private var storedItems: [Product] = []

    func save(_ items: [Product]) {
        storedItems = items
    }

    func load() -> [Product] {
        return storedItems
    }
}
