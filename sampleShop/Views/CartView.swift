import SwiftUI
import Foundation

struct CartView: View {
    @EnvironmentObject var cart: Cart

    var body: some View {
        List {
            if cart.items.isEmpty {
                Text("カートは空です 🛒")
                    .foregroundColor(.gray)
            } else {
                ForEach(cart.items) { product in
                    HStack {
                        Image(systemName: "photo")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            .padding(.trailing, 8)
                        VStack(alignment: .leading) {
                            Text(product.title)
                                .font(.headline)
                            Text("¥\(product.price)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("カート")
    }
}

#Preview {
    CartView()
        .environmentObject(Cart())
}
