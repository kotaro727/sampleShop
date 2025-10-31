# EnvironmentObjectとは

`environmentObject`は、SwiftUIでアプリ全体または特定のビュー階層内でデータを共有するための仕組みです。

## 基本概念

### 仕組み
```swift
// 1. ObservableObjectを作成
class Cart: ObservableObject {
    @Published var items: [Product] = []
}

// 2. ルートビューで注入
@main
struct sampleShopApp: App {
    @StateObject var cart = Cart()  // インスタンスを作成

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cart)  // ← ここで注入
        }
    }
}

// 3. 子ビューで受け取り
struct ContentView: View {
    @EnvironmentObject var cart: Cart  // ← 自動的に受け取れる
}
```

## このアプリでの使用例

このアプリでは`Cart`（カート）を共有しています：

```
sampleShopApp (cart作成)
    ↓ .environmentObject(cart)
ContentView (cartを参照)
    ↓
ProductDetailView (cartにアイテム追加)

CartView (cartの中身を表示)
```

## 他の状態管理との違い

| 方法 | 使用場面 | スコープ |
|------|---------|---------|
| `@State` | 単一ビュー内のローカル状態 | そのビューのみ |
| `@StateObject` | ビューが所有するオブジェクト | そのビューと子ビュー |
| `@EnvironmentObject` | 複数ビューで共有するグローバル状態 | 注入された階層全体 |

## メリット

1. **プロパティ渡しが不要**: 深い階層でもビューを経由せずに直接アクセス可能
2. **単一の情報源**: カートデータが1つの場所で管理される
3. **自動更新**: `@Published`プロパティが変更されると、使用しているすべてのビューが自動的に再描画

## 具体例

例えば、`ProductDetailView`で商品を追加すると、`ContentView`のツールバーにあるカート数も自動的に更新されます。

```swift
// ProductDetailView.swift
Button(action: {
    cart.add(product)  // カートに追加
}) {
    Text("カートに追加")
}

// ContentView.swift - ツールバー
Text("\(cart.items.count)")  // 自動的に更新される
```

これは、`cart`が`@Published`プロパティを持つ`ObservableObject`であり、`@EnvironmentObject`として注入されているため、変更が全てのビューに自動的に伝播するからです。

## 注意点

- Previewで使用する場合は、明示的に`.environmentObject()`を指定する必要があります
  ```swift
  #Preview {
      ContentView()
          .environmentObject(Cart())
  }
  ```

- `@EnvironmentObject`を使用するビューは、親ビューで`.environmentObject()`が呼ばれていないとランタイムエラーになります
