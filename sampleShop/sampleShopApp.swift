//
//  sampleShopApp.swift
//  sampleShop
//
//  Created by 鈴木光太郎 on 2025/10/30.
//

import SwiftUI

@main
struct sampleShopApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var cart = Cart()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cart) // 全Viewで使える
        }
    }
}
