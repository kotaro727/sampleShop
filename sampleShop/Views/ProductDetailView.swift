import SwiftUI
import Foundation

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cart: Cart // 共有Cartを受け取る

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .resizable()
                .frame(width: 150, height: 150)
                .cornerRadius(12)
                .padding(.top, 40)

            Text(product.title)
                .font(.title)
                .bold()

            Text("¥\(product.price)")
                .font(.title2)
                .foregroundColor(.gray)

            Button(action: {
                cart.add(product)
            }) {
                Text("カートに追加")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 30)    

            Spacer()
        }
        .navigationTitle("商品詳細")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#Preview {
    ProductDetailView(product: Product(id: 1, title: "サンプル商品", price: 1000, thumbnail: ""))
        .environmentObject(Cart()) // 共有Cartを設定
}
