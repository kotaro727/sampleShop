import SwiftUI

struct ContentView: View {
    @StateObject private var service = ProductService()
    @EnvironmentObject var cart: Cart

    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading {
                    ProgressView("読み込み中...")
                } else if let errorMessage = service.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.headline)
                        Button("再試行") {
                            Task {
                                await service.fetchProducts()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if service.products.isEmpty {
                    Text("商品がありません")
                        .foregroundColor(.gray)
                } else {
                    List(service.products) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            HStack {
                                AsyncImage(url: URL(string: product.thumbnail)) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .padding(.trailing, 8)

                                VStack(alignment: .leading) {
                                    Text(product.title)
                                        .font(.headline)
                                    Text("¥\(String(format: "%.0f", product.price))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("商品一覧")
            .toolbar {
                NavigationLink(destination: CartView()) {
                    HStack {
                        Image(systemName: "cart")
                        Text("\(cart.items.count)")
                    }
                }
            }
            .task {
                await service.fetchProducts()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Cart())
}

