# AsyncImage解説

`AsyncImage`は、SwiftUIで非同期に画像をダウンロードして表示するためのビューです。URLから画像を読み込む際に、読み込み状態を自動的に管理してくれます。

## 基本的な使い方

### シンプルな使用法

```swift
AsyncImage(url: URL(string: "https://example.com/image.jpg"))
```

これだけで画像が表示されますが、読み込み中やエラー時の表示をカスタマイズできません。

### プレースホルダー付き（推奨）

```swift
AsyncImage(url: URL(string: product.thumbnail)) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
.frame(width: 60, height: 60)
```

**使用例**（このアプリ）:
- [ContentView.swift:33](sampleShop/ContentView.swift#L33) - 商品一覧でこの形式を使用

## フェーズを使った詳細な制御

画像の読み込み状態（フェーズ）ごとに異なる表示を定義できます。

```swift
AsyncImage(url: URL(string: product.thumbnail)) { phase in
    switch phase {
    case .empty:
        // 読み込み中
        ProgressView()
    case .success(let image):
        // 読み込み成功
        image.resizable()
    case .failure:
        // 読み込み失敗
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
```

**使用例**（このアプリ）:
- [ProductDetailView.swift:10-30](sampleShop/Views/ProductDetailView.swift#L10-L30) - 商品詳細画面でこの形式を使用

## 3つのフェーズ

### 1. `.empty` - 読み込み中

画像のダウンロードが開始されたが、まだ完了していない状態。

```swift
case .empty:
    ProgressView()              // ローディングインジケーター
        .frame(width: 200, height: 200)
```

**表示例**: くるくる回るインジケーター

### 2. `.success(let image)` - 読み込み成功

画像のダウンロードが成功し、表示可能な状態。

```swift
case .success(let image):
    image
        .resizable()            // リサイズ可能にする
        .scaledToFit()         // アスペクト比を保持
        .frame(maxWidth: 300, maxHeight: 300)
        .cornerRadius(12)       // 角丸
```

**よく使うモディファイア**:
- `.resizable()`: 画像のサイズを変更可能にする（必須）
- `.scaledToFit()`: アスペクト比を保ったまま、フレームに収める
- `.scaledToFill()`: アスペクト比を保ったまま、フレームを埋める
- `.aspectRatio(contentMode: .fit)`: `.scaledToFit()`と同じ

### 3. `.failure` - 読み込み失敗

ネットワークエラーや無効なURLなどで画像の読み込みが失敗した状態。

```swift
case .failure:
    Image(systemName: "photo")  // フォールバック画像
        .resizable()
        .scaledToFit()
        .frame(width: 200, height: 200)
        .foregroundColor(.gray)
```

**失敗する理由**:
- ネットワーク接続がない
- URLが無効
- 画像形式がサポートされていない
- サーバーエラー

## このアプリでの使用例

### ContentView（商品一覧）

```swift
AsyncImage(url: URL(string: product.thumbnail)) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
.frame(width: 60, height: 60)
.cornerRadius(8)
```

- シンプルな実装
- サムネイルなので小さいサイズ（60x60）
- 失敗時の処理は省略（プレースホルダーが表示され続ける）

### ProductDetailView（商品詳細）

```swift
AsyncImage(url: URL(string: product.thumbnail)) { phase in
    switch phase {
    case .empty:
        ProgressView()
            .frame(width: 200, height: 200)
    case .success(let image):
        image
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 300, maxHeight: 300)
            .cornerRadius(12)
    case .failure:
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .foregroundColor(.gray)
    @unknown default:
        EmptyView()
    }
}
```

- フェーズを使った詳細な制御
- 大きいサイズ（最大300x300）
- 失敗時にフォールバック画像を表示

## 画像のサイズ調整

### `.resizable()`

画像をリサイズ可能にします。これがないと`.frame()`が効きません。

```swift
// ❌ 効かない
Image(systemName: "photo")
    .frame(width: 100, height: 100)

// ✅ 正しい
Image(systemName: "photo")
    .resizable()
    .frame(width: 100, height: 100)
```

### `.scaledToFit()` vs `.scaledToFill()`

```swift
// scaledToFit: アスペクト比を保ちつつ、フレーム内に収める
image
    .resizable()
    .scaledToFit()
    .frame(width: 200, height: 200)
// → 画像全体が見えるが、余白ができる可能性がある

// scaledToFill: アスペクト比を保ちつつ、フレームを埋める
image
    .resizable()
    .scaledToFill()
    .frame(width: 200, height: 200)
    .clipped()  // はみ出た部分を切り取る
// → フレームが完全に埋まるが、画像の一部が切れる可能性がある
```

### フレームサイズの指定方法

```swift
// 固定サイズ
.frame(width: 60, height: 60)

// 最大サイズ（これより小さくなる可能性がある）
.frame(maxWidth: 300, maxHeight: 300)

// 最小サイズ（これより大きくなる可能性がある）
.frame(minWidth: 100, minHeight: 100)

// 幅いっぱい、高さは固定
.frame(maxWidth: .infinity, height: 200)
```

## パフォーマンス最適化

### キャッシュ

`AsyncImage`は自動的に画像をキャッシュします。同じURLの画像を再度読み込む場合、キャッシュから取得されるため高速です。

### メモリ管理

大量の画像を表示する場合（Listなど）、スクロールして画面外に出た画像は自動的にメモリから解放されます。

## 従来の方法との比較

### iOS 15以前（手動実装）

```swift
// URLSessionを使って手動で画像をダウンロード
func loadImage(from url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
        throw ImageError.invalidData
    }
    return image
}

// @StateでUIImageを管理
@State private var image: UIImage?
```

→ コードが複雑、エラーハンドリングも自分で実装

### iOS 15以降（AsyncImage）

```swift
AsyncImage(url: URL(string: "...")) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

→ 簡潔、エラーハンドリングも自動

## よくあるパターン

### パターン1: リスト内のサムネイル

```swift
List(products) { product in
    HStack {
        AsyncImage(url: URL(string: product.thumbnail)) { image in
            image.resizable()
        } placeholder: {
            ProgressView()
        }
        .frame(width: 50, height: 50)
        .cornerRadius(8)

        Text(product.title)
    }
}
```

### パターン2: ヒーロー画像（大きな画像）

```swift
AsyncImage(url: URL(string: product.imageURL)) { phase in
    switch phase {
    case .success(let image):
        image
            .resizable()
            .scaledToFill()
            .frame(height: 300)
            .clipped()
    default:
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 300)
    }
}
```

### パターン3: 円形アバター

```swift
AsyncImage(url: URL(string: user.avatarURL)) { image in
    image
        .resizable()
        .scaledToFill()
} placeholder: {
    Image(systemName: "person.circle.fill")
        .resizable()
}
.frame(width: 60, height: 60)
.clipShape(Circle())  // 円形に切り抜き
```

## まとめ

| 特徴 | 説明 |
|------|------|
| **自動ダウンロード** | URLから画像を自動的にダウンロード |
| **状態管理** | 読み込み中・成功・失敗を自動管理 |
| **キャッシュ** | ダウンロードした画像を自動キャッシュ |
| **メモリ効率** | 画面外の画像を自動解放 |
| **iOS 15+** | iOS 15以降で使用可能 |

**使い分け**:
- 簡単な実装 → `placeholder:`クロージャを使う
- 細かい制御 → `phase`を使ったswitch文
- エラー表示が重要 → `.failure`ケースで適切なフォールバックを表示
