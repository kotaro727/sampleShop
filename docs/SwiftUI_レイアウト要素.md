# SwiftUI レイアウト要素まとめ

SwiftUIでUIを構築する際に使用する主要なレイアウト要素について解説します。

## 基本的なレイアウトコンテナ

### VStack（垂直スタック）

子ビューを**縦方向（上から下）**に並べます。

```swift
VStack(spacing: 16) {  // 要素間のスペース: 16pt
    Text("タイトル")
    Text("説明文")
    Button("ボタン") { }
}
```

**使用例**（このアプリ）:
- [ProductDetailView.swift:8](sampleShop/Views/ProductDetailView.swift#L8) - 商品画像、タイトル、価格、ボタンを縦に配置
- [ContentView.swift:13](sampleShop/ContentView.swift#L13) - エラー画面の要素を縦に配置

**オプション**:
- `spacing`: 要素間の間隔
- `alignment`: 横方向の揃え位置（`.leading`, `.center`, `.trailing`）

### HStack（水平スタック）

子ビューを**横方向（左から右）**に並べます。

```swift
HStack(spacing: 8) {
    Image(systemName: "photo")
    Text("タイトル")
}
```

**使用例**（このアプリ）:
- [ContentView.swift:32](sampleShop/ContentView.swift#L32) - サムネイル画像とテキストを横に配置
- [ContentView.swift:57](sampleShop/ContentView.swift#L57) - カートアイコンと数字を横に配置

**オプション**:
- `spacing`: 要素間の間隔
- `alignment`: 縦方向の揃え位置（`.top`, `.center`, `.bottom`）

### ZStack（重ねスタック）

子ビューを**重ねて**配置します（奥から手前へ）。

```swift
ZStack {
    Color.blue          // 背景
    Text("前面テキスト")  // テキストが上に表示される
}
```

**用途**:
- 背景色や画像の上にコンテンツを配置
- オーバーレイ効果
- バッジやアイコンの重ね表示

## ナビゲーション要素

### NavigationStack（iOS 16+）

画面遷移を管理するコンテナ。階層的なナビゲーションを実現します。

```swift
NavigationStack {
    List {
        NavigationLink("詳細へ", destination: DetailView())
    }
    .navigationTitle("一覧")
}
```

**使用例**（このアプリ）:
- [ContentView.swift:8](sampleShop/ContentView.swift#L8) - 商品一覧から詳細画面への遷移を管理

**主な機能**:
- `.navigationTitle()`: ナビゲーションバーのタイトル
- `.navigationBarTitleDisplayMode()`: タイトルの表示モード（`.large`, `.inline`）
- `.toolbar()`: ナビゲーションバーにボタンなどを追加
- `NavigationLink`: 遷移先を指定

**旧型との違い**:
- `NavigationView`（iOS 13-15）の後継
- より型安全で柔軟なナビゲーション

## グループ化要素

### Group

ビューをグループ化するが、**レイアウトに影響しない**透明なコンテナ。

```swift
Group {
    if isLoading {
        ProgressView()
    } else {
        ContentView()
    }
}
.padding()  // グループ全体に適用
```

**使用例**（このアプリ）:
- [ContentView.swift:9](sampleShop/ContentView.swift#L9) - 条件分岐したビューをまとめる

**主な用途**:
1. **SwiftUIの10個制限を回避**: 1つのコンテナに最大10個までしか子ビューを置けない制限を回避
2. **条件分岐のラッピング**: if-else で異なるビューを返す際に型を統一
3. **共通のモディファイアを適用**: グループ全体に一括で設定を適用

**VStackとの違い**:
```swift
// Group: レイアウトに影響なし（元のレイアウトを保持）
Group {
    Text("A")
    Text("B")
}

// VStack: 縦に並べる（新しいレイアウトを作成）
VStack {
    Text("A")
    Text("B")
}
```

## リスト要素

### List

スクロール可能な行のリスト。UITableViewに相当します。

```swift
List(products) { product in
    Text(product.title)
}
```

**使用例**（このアプリ）:
- [ContentView.swift:30](sampleShop/ContentView.swift#L30) - 商品一覧を表示
- [CartView.swift:7](sampleShop/Views/CartView.swift#L7) - カート内の商品を表示

**主な機能**:
- `ForEach`: 配列から複数の行を生成
- `NavigationLink`: リスト項目をタップして画面遷移
- セクション、スワイプアクション、削除機能など

## このアプリでの使用例

### ContentViewの構造

```swift
NavigationStack {                    // ナビゲーション管理
    Group {                          // 条件分岐をまとめる
        if service.isLoading {
            ProgressView()           // ローディング表示
        } else {
            List(products) { product in    // 商品リスト
                NavigationLink(...) {
                    HStack {         // 横並び
                        AsyncImage(...)
                        VStack {     // 縦並び
                            Text(...)
                            Text(...)
                        }
                    }
                }
            }
        }
    }
    .navigationTitle("商品一覧")
}
```

### ProductDetailViewの構造

```swift
VStack(spacing: 16) {        // 全体を縦並び
    Image(...)               // 商品画像
    Text(product.title)      // タイトル
    Text(price)              // 価格
    Button("カートに追加") { } // ボタン
    Spacer()                 // 下部の余白
}
```

## よく使うモディファイア

### レイアウト調整

```swift
.padding()              // 余白を追加
.frame(width: 60, height: 60)  // サイズ指定
.cornerRadius(8)        // 角丸
.background(Color.blue) // 背景色
```

### テキストスタイル

```swift
.font(.headline)        // フォントスタイル
.foregroundColor(.gray) // テキスト色
.bold()                 // 太字
```

## まとめ

| 要素 | 用途 | レイアウト |
|------|------|----------|
| `VStack` | 縦に並べる | 縦方向の配置を作成 |
| `HStack` | 横に並べる | 横方向の配置を作成 |
| `ZStack` | 重ねる | 重ね合わせを作成 |
| `Group` | グループ化 | レイアウトに影響なし |
| `List` | リスト表示 | スクロール可能なリスト |
| `NavigationStack` | 画面遷移 | ナビゲーション管理 |

**選び方のポイント**:
- 並べ方で選ぶ → VStack（縦）、HStack（横）、ZStack（重ね）
- レイアウトを変えずにまとめる → Group
- スクロール可能なリスト → List
- 画面遷移が必要 → NavigationStack
