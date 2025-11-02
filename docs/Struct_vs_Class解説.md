# Struct vs Class 解説

Swiftには型を定義する方法が主に2つあります：**struct（構造体）** と **class（クラス）** です。両方とも「型」を作りますが、重要な違いがあります。

## 基本概念

### どちらも型を定義する

```swift
// struct（構造体）
struct Product {
    let id: Int
    let name: String
}

// class（クラス）
class Cart {
    var items: [Product] = []
}
```

両方とも：
- プロパティ（変数）を持てる
- メソッド（関数）を持てる
- イニシャライザ（初期化処理）を持てる
- プロトコルに準拠できる

## 最大の違い：値型 vs 参照型

### Struct = 値型（Value Type）

値そのものをコピーします。

```swift
struct Point {
    var x: Int
    var y: Int
}

var point1 = Point(x: 10, y: 20)
var point2 = point1  // コピーが作られる

point2.x = 100

print(point1.x)  // 10（変わらない）
print(point2.x)  // 100
```

**イメージ**: 紙に書いた数字をコピー機でコピーする感じ

```
point1: [x: 10, y: 20]  ←オリジナル
         ↓ コピー
point2: [x: 10, y: 20]  ←別のコピー

point2を変更しても、point1は影響を受けない
```

### Class = 参照型（Reference Type）

メモリ上の同じ場所を参照します。

```swift
class Person {
    var name: String
    init(name: String) {
        self.name = name
    }
}

var person1 = Person(name: "太郎")
var person2 = person1  // 同じ場所を参照

person2.name = "次郎"

print(person1.name)  // 次郎（変わった！）
print(person2.name)  // 次郎
```

**イメージ**: 住所（参照）をコピーする感じ

```
person1 → [メモリのアドレス: 0x1234] → {name: "太郎"}
                                        ↑
person2 → [メモリのアドレス: 0x1234] ──┘

person2で変更すると、person1も同じ場所を見ているので変わる
```

## このアプリでの使い分け

### Structの使用例

[ProductResponse.swift:7-12](sampleShop/Model/ProductResponse.swift#L7-L12)

```swift
struct Product: Identifiable, Decodable {
    let id: Int
    let title: String
    let price: Double
    let thumbnail: String
}
```

**理由**:
- データを表現するだけ（振る舞いがシンプル）
- 不変（`let`で定義）
- コピーされても問題ない

### Classの使用例

[Cart.swift:3](sampleShop/Model/Cart.swift#L3)

```swift
class Cart: ObservableObject {
    @Published var items: [Product] = []

    func add(_ product: Product) {
        items.append(product)
    }
}
```

**理由**:
- 共有したい（アプリ全体で同じカートを参照）
- 状態が変化する（`@Published`）
- ObservableObjectはclassのみ可能

## 詳しい違い

### 1. コピーの挙動

```swift
// Struct: 完全に別のコピー
struct Book {
    var title: String
}

var book1 = Book(title: "Swift入門")
var book2 = book1
book2.title = "SwiftUI入門"

print(book1.title)  // "Swift入門"（変わらない）
print(book2.title)  // "SwiftUI入門"

// Class: 同じインスタンスを参照
class Person {
    var name: String
    init(name: String) { self.name = name }
}

var person1 = Person(name: "太郎")
var person2 = person1
person2.name = "次郎"

print(person1.name)  // "次郎"（変わる！）
print(person2.name)  // "次郎"
```

### 2. イニシャライザ

```swift
// Struct: 自動的にメンバーワイズイニシャライザが生成される
struct Product {
    let id: Int
    let name: String
    // init(id:name:) が自動生成される
}

let product = Product(id: 1, name: "iPhone")  // OK

// Class: 自分で定義する必要がある
class Cart {
    var items: [Product]

    init() {  // 明示的に定義が必要
        self.items = []
    }
}
```

### 3. 継承

```swift
// Struct: 継承できない
struct Animal {
    var name: String
}

// struct Dog: Animal { }  // ❌ エラー

// Class: 継承できる
class Animal {
    var name: String
    init(name: String) { self.name = name }
}

class Dog: Animal {  // ✅ OK
    var breed: String
    init(name: String, breed: String) {
        self.breed = breed
        super.init(name: name)
    }
}
```

### 4. 変更可能性

```swift
// Struct: letで宣言すると完全に不変
struct Point {
    var x: Int
}

let point = Point(x: 10)
// point.x = 20  // ❌ エラー（letなので変更不可）

var mutablePoint = Point(x: 10)
mutablePoint.x = 20  // ✅ OK（varなので変更可）

// Class: letでも中身は変更できる
class Person {
    var name: String
    init(name: String) { self.name = name }
}

let person = Person(name: "太郎")
person.name = "次郎"  // ✅ OK（参照先は同じ、中身は変わる）
```

### 5. 等価性の比較

```swift
// Struct: ==で値を比較（Equatableに準拠すれば）
struct Point: Equatable {
    let x: Int
    let y: Int
}

let p1 = Point(x: 10, y: 20)
let p2 = Point(x: 10, y: 20)

print(p1 == p2)  // true（値が同じ）

// Class: ===で参照を比較、==で値を比較（実装が必要）
class Person {
    var name: String
    init(name: String) { self.name = name }
}

let person1 = Person(name: "太郎")
let person2 = Person(name: "太郎")

print(person1 === person2)  // false（別のインスタンス）

let person3 = person1
print(person1 === person3)  // true（同じインスタンス）
```

## いつStructを使うべきか

### ✅ Structが適している場合

1. **データを表現する**
   ```swift
   struct Product {
       let id: Int
       let name: String
       let price: Double
   }
   ```

2. **不変（値が変わらない）**
   ```swift
   struct Point {
       let x: Int
       let y: Int
   }
   ```

3. **小さいデータ**
   ```swift
   struct Color {
       let red: Double
       let green: Double
       let blue: Double
   }
   ```

4. **コピーされても問題ない**
   ```swift
   struct Rectangle {
       var width: Double
       var height: Double
   }
   ```

### このアプリでStructを使っている例

- `Product`: 商品データ（変わらない、コピーOK）
- `ProductResponse`: APIレスポンス（一時的なデータ）

## いつClassを使うべきか

### ✅ Classが適している場合

1. **共有したい状態**
   ```swift
   class Cart: ObservableObject {
       @Published var items: [Product] = []
   }
   ```

2. **継承が必要**
   ```swift
   class ViewController: UIViewController {
       // ...
   }
   ```

3. **ObservableObject（SwiftUI）**
   ```swift
   class AppState: ObservableObject {
       @Published var isLoggedIn = false
   }
   ```

4. **参照カウントが必要**
   ```swift
   class FileManager {
       // 同じファイルを複数箇所で管理
   }
   ```

### このアプリでClassを使っている例

- `Cart`: アプリ全体で共有するカート（ObservableObject）
- `ProductService`: APIから取得した商品を管理（ObservableObject）

## パフォーマンス

### Struct（値型）

- スタックに割り当て（高速）
- コピーコストがかかる（大きい構造体は注意）
- 参照カウント不要

### Class（参照型）

- ヒープに割り当て（若干遅い）
- 参照のコピーのみ（軽い）
- 参照カウント管理が必要（ARCのオーバーヘッド）

**実用上の違い**: ほとんどの場合、気にする必要はありません。設計の明確さを優先しましょう。

## SwiftUIでの使い分け

### View: Struct

```swift
struct ContentView: View {  // Viewは常にstruct
    var body: some View {
        Text("Hello")
    }
}
```

**理由**: Viewは値型であるべき（SwiftUIの設計思想）

### ObservableObject: Class

```swift
class Cart: ObservableObject {  // ObservableObjectは必ずclass
    @Published var items: [Product] = []
}
```

**理由**: 状態を共有し、変更を監視する必要があるため

## 比較表

| 特徴 | Struct | Class |
|------|--------|-------|
| 型の種類 | 値型 | 参照型 |
| コピー | 値をコピー | 参照をコピー |
| 継承 | ❌ できない | ✅ できる |
| イニシャライザ | 自動生成 | 手動定義 |
| let宣言 | 完全に不変 | 参照は不変、中身は可変 |
| パフォーマンス | スタック（高速） | ヒープ（参照カウント） |
| 使用例 | データモデル | 共有状態、継承 |
| SwiftUIのView | ✅ 必須 | ❌ 使えない |
| ObservableObject | ❌ 使えない | ✅ 必須 |

## まとめ

### 選択の指針

```
データを表現する？
├─ Yes → Struct
│   └─ 例: Product, Point, Color
│
└─ No → 状態を共有する？
    ├─ Yes → Class
    │   └─ 例: Cart, ViewModel
    │
    └─ No → 継承が必要？
        ├─ Yes → Class
        └─ No → Struct（デフォルト）
```

### Appleの推奨

> **デフォルトでStructを使い、必要な場合のみClassを使う**

**理由**:
- 値型の方が予測可能（どこかで変更されても影響を受けない）
- スレッドセーフティが高い
- コードが理解しやすい

### このアプリでの使い分け

| 型 | 種類 | 理由 |
|----|------|------|
| `Product` | Struct | 商品データ（不変、コピーOK） |
| `ProductResponse` | Struct | APIレスポンス（一時的） |
| `Cart` | Class | 共有状態（ObservableObject） |
| `ProductService` | Class | API管理（ObservableObject） |
| `ContentView` | Struct | SwiftUIのView |
| `ProductDetailView` | Struct | SwiftUIのView |

**パターン**: データはStruct、状態管理はClass、ViewはStruct！
