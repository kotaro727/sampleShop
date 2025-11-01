# プロトコル解説: Identifiable & Decodable

Swiftの**プロトコル（Protocol）**は、特定の機能や要件を定義する設計図のようなものです。クラスや構造体がプロトコルに**準拠（conform）**することで、その機能を持つことを保証します。

## プロトコル vs Interface（他言語との比較）

### 他言語でのInterface

Swiftのプロトコルは、他の言語の**Interface**と概念的に似ています。

| 言語 | 用語 |
|------|------|
| Swift | Protocol |
| Java | Interface |
| C# | Interface |
| TypeScript | Interface |
| Go | Interface |
| Kotlin | Interface |

### 共通点

どちらも「この型はこういう機能を持つべき」という**契約（Contract）**を定義します。

```swift
// Swift - Protocol
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    func draw() {
        print("○を描く")
    }
}
```

```java
// Java - Interface
interface Drawable {
    void draw();
}

class Circle implements Drawable {
    public void draw() {
        System.out.println("○を描く");
    }
}
```

### Swiftのプロトコルが強力な点

Swiftのプロトコルは、単なるInterfaceより機能が豊富です：

#### 1. デフォルト実装（Protocol Extension）

```swift
protocol Greetable {
    func greet()
}

// プロトコルにデフォルト実装を追加
extension Greetable {
    func greet() {
        print("こんにちは！")  // デフォルトの挨拶
    }
}

struct Person: Greetable {
    // greet()を実装しなくてもOK（デフォルトが使われる）
}

struct Robot: Greetable {
    // カスタム実装も可能
    func greet() {
        print("Hello, I am a robot")
    }
}
```

Javaの通常のInterfaceでは、実装クラスが必ず全てのメソッドを実装する必要があります（Java 8+ではdefaultメソッドで可能になりました）。

#### 2. 値型（struct）にも適用可能

```swift
// structでもプロトコルに準拠できる
struct Product: Identifiable, Decodable {
    let id: Int
}
```

多くのオブジェクト指向言語では、Interfaceはクラスのみが実装できます。

#### 3. 複数のプロトコルに準拠

```swift
struct Product: Identifiable, Decodable, Equatable, Hashable {
    // 複数のプロトコルに準拠
}
```

これはほとんどの言語で可能ですが、Swiftでは特に頻繁に使われます。

#### 4. プロトコルを型として使用

```swift
protocol Animal {
    func makeSound()
}

// プロトコル型の配列
let animals: [Animal] = [Dog(), Cat(), Bird()]

for animal in animals {
    animal.makeSound()  // ポリモーフィズム
}
```

### まとめ（Protocol vs Interface）

| 特徴 | Swift Protocol | Java Interface |
|------|---------------|----------------|
| 基本概念 | 契約の定義 | 契約の定義 |
| メソッド宣言 | ✅ | ✅ |
| プロパティ宣言 | ✅ | ✅（変数として） |
| デフォルト実装 | ✅（Extension） | △（default メソッド、Java 8+） |
| 値型に適用 | ✅（struct, enum） | ❌（classのみ） |
| 多重準拠 | ✅ | ✅ |
| 型として使用 | ✅ | ✅ |

**結論**: 概念的には似ているが、Swiftのプロトコルはより柔軟で強力です。

## プロトコルとは

### 基本概念

```swift
// プロトコルの定義
protocol Flyable {
    func fly()
}

// プロトコルに準拠
struct Bird: Flyable {
    func fly() {
        print("鳥が飛ぶ")
    }
}
```

プロトコルに準拠すると、そのプロトコルが要求するメソッドやプロパティを実装する必要があります。

## Identifiable プロトコル

### 概要

`Identifiable`は、**一意の識別子（ID）を持つ**ことを保証するプロトコルです。

```swift
protocol Identifiable {
    var id: ID { get }  // IDというプロパティを持つ必要がある
}
```

### なぜ必要？

SwiftUIの`List`や`ForEach`は、各要素を区別するために一意のIDが必要です。

```swift
// ❌ Identifiableに準拠していない場合
struct Product {
    let name: String
    let price: Int
}

List(products) { product in  // エラー！IDがない
    Text(product.name)
}

// ✅ Identifiableに準拠している場合
struct Product: Identifiable {
    let id: Int  // ← これが必要
    let name: String
    let price: Int
}

List(products) { product in  // OK！
    Text(product.name)
}
```

### このアプリでの使用例

[ProductResponse.swift:7](sampleShop/Model/ProductResponse.swift#L7)

```swift
struct Product: Identifiable, Decodable {
    let id: Int         // ← Identifiableが要求するプロパティ
    let title: String
    let price: Double
    let thumbnail: String
}
```

**使用箇所**:
- [ContentView.swift:30](sampleShop/ContentView.swift#L30) - `List(service.products)`
- [CartView.swift:12](sampleShop/Views/CartView.swift#L12) - `ForEach(cart.items)`

### idの型

`id`は任意の型でOKですが、**Hashable**である必要があります。

```swift
struct Product: Identifiable {
    let id: Int           // ✅ Int
}

struct User: Identifiable {
    let id: String        // ✅ String
}

struct Post: Identifiable {
    let id: UUID          // ✅ UUID（よく使われる）
}
```

### id以外の名前を使う場合

```swift
struct Product: Identifiable {
    let productCode: String

    var id: String {      // 計算プロパティでidを提供
        productCode
    }
}
```

## Decodable プロトコル

### 概要

`Decodable`は、**JSONなどのデータから構造体を復元（デコード）できる**ことを保証するプロトコルです。

```swift
protocol Decodable {
    init(from decoder: Decoder) throws
}
```

### なぜ必要？

API通信では、サーバーからJSON形式でデータが返ってきます。これをSwiftの構造体に変換するために使います。

### JSONからSwiftへの変換

```swift
// APIのJSONレスポンス
{
    "id": 1,
    "title": "iPhone",
    "price": 999.99
}

// Swiftの構造体
struct Product: Decodable {
    let id: Int
    let title: String
    let price: Double
}

// デコード
let product = try JSONDecoder().decode(Product.self, from: jsonData)
```

### このアプリでの使用例

[ProductService.swift:20](sampleShop/Services/ProductService.swift#L20)

```swift
do {
    let (data, _) = try await URLSession.shared.data(from: url)
    // ↓ DecodableなのでJSONから構造体に変換できる
    let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
    self.products = decoded.products
} catch {
    print("デコードエラー:", error)
}
```

### 自動的にDecodableに準拠

プロパティが全てDecodableな型なら、自動的にDecodableに準拠します。

```swift
// これだけでDecodableになる（自動生成）
struct Product: Decodable {
    let id: Int           // IntはDecodable
    let title: String     // StringもDecodable
    let price: Double     // DoubleもDecodable
}
```

### JSONキーとプロパティ名が異なる場合

```swift
// JSON
{
    "product_id": 1,
    "product_name": "iPhone"
}

// Swift
struct Product: Decodable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "product_id"
        case name = "product_name"
    }
}
```

### ネストしたJSON

```swift
// JSON
{
    "products": [
        {"id": 1, "title": "iPhone"},
        {"id": 2, "title": "iPad"}
    ]
}

// Swift - ネストした構造
struct ProductResponse: Decodable {
    let products: [Product]
}

struct Product: Decodable {
    let id: Int
    let title: String
}
```

**このアプリでの使用例**: [ProductResponse.swift](sampleShop/Model/ProductResponse.swift)

## Encodable と Codable

### Encodable

`Decodable`の逆で、**Swiftの構造体をJSONに変換**するプロトコル。

```swift
struct Product: Encodable {
    let id: Int
    let title: String
}

let product = Product(id: 1, title: "iPhone")
let jsonData = try JSONEncoder().encode(product)
// → {"id":1,"title":"iPhone"}
```

### Codable

`Decodable` + `Encodable` の両方を備えたプロトコル。

```swift
typealias Codable = Decodable & Encodable

// この2つは同じ意味
struct Product: Codable { }
struct Product: Decodable, Encodable { }
```

**使い分け**:
- JSON → Swift のみ → `Decodable`
- Swift → JSON のみ → `Encodable`
- 両方向 → `Codable`

## このアプリでのプロトコル使用まとめ

### Product構造体

```swift
struct Product: Identifiable, Decodable {
    let id: Int
    let title: String
    let price: Double
    let thumbnail: String
}
```

| プロトコル | 理由 | 使用箇所 |
|-----------|------|---------|
| `Identifiable` | List/ForEachで一意に識別するため | ContentView, CartView |
| `Decodable` | APIのJSONレスポンスから変換するため | ProductService |

### ProductResponse構造体

```swift
struct ProductResponse: Decodable {
    let products: [Product]
}
```

| プロトコル | 理由 |
|-----------|------|
| `Decodable` | APIのネストしたJSONから変換するため |

## よくあるエラーと解決方法

### エラー1: Identifiable準拠していない

```swift
// ❌ エラー
List(products) { product in
    Text(product.name)
}
// Error: Referencing initializer 'init(_:content:)' on 'ForEach' requires that 'Product' conform to 'Identifiable'

// ✅ 解決策1: Identifiableに準拠
struct Product: Identifiable {
    let id: Int
    // ...
}

// ✅ 解決策2: idを明示的に指定
List(products, id: \.name) { product in
    Text(product.name)
}
```

### エラー2: Decodable対応していない型

```swift
// ❌ エラー
struct Product: Decodable {
    let id: Int
    let customObject: MyCustomClass  // DecodableじゃないとNG
}

// ✅ 解決策: MyCustomClassもDecodableに準拠
class MyCustomClass: Decodable {
    // ...
}
```

### エラー3: JSONキーとプロパティ名の不一致

```swift
// JSON: {"product_id": 1}
// ❌ エラー（product_id != id）
struct Product: Decodable {
    let id: Int  // JSONにはidキーがない
}

// ✅ 解決策: CodingKeysを定義
struct Product: Decodable {
    let id: Int

    enum CodingKeys: String, CodingKey {
        case id = "product_id"
    }
}
```

### エラー4: JSONの型不一致

```swift
// JSON: {"price": 99.99}
// ❌ エラー（Doubleなのに、Intでデコードしようとしている）
struct Product: Decodable {
    let price: Int
}

// ✅ 解決策: 型を一致させる
struct Product: Decodable {
    let price: Double
}
```

**このアプリでの実例**: [修正前のProductResponse.swift](sampleShop/Model/ProductResponse.swift#L10)で`price: Int`だったのを`price: Double`に修正

## まとめ

| プロトコル | 目的 | 必須要件 | 主な用途 |
|-----------|------|---------|---------|
| `Identifiable` | 一意に識別可能 | `id`プロパティ | List, ForEach |
| `Decodable` | JSON→Swiftに変換可能 | `init(from:)` | API通信 |
| `Encodable` | Swift→JSONに変換可能 | `encode(to:)` | API送信 |
| `Codable` | 双方向変換可能 | 両方 | データ永続化 |

**ベストプラクティス**:
- モデル構造体は基本的に`Identifiable`と`Decodable`に準拠させる
- プロパティ名はJSONのキー名と一致させる（可能な限り）
- 型も一致させる（特に`Int` vs `Double`に注意）
