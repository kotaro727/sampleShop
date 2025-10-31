import SwiftUI

struct ProductDetailView: View {
    let product: Product

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .resizable()
                .frame(width: 150, height: 150)
                .cornerRadius(12)
                .padding(.top, 40)

            Text(product.name)
                .font(.title)
                .bold()

            Text("¥\(product.price)")
                .font(.title2)
                .foregroundColor(.gray)

            Spacer()
        }
        .navigationTitle("商品詳細")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#Preview {
    ProductDetailView(product: sampleProducts[0])
}
