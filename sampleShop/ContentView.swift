//
//  ContentView.swift
//  sampleShop
//
//  Created by 鈴木光太郎 on 2025/10/30.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(sampleProducts) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    HStack {
                        Image(systemName: "photo")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .padding(.trailing, 8)
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                            Text("¥\(product.price)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("商品一覧")
        }
    }
}

#Preview {
    ContentView()
}
