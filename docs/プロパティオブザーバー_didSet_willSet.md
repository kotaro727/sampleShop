# プロパティオブザーバー: didSet & willSet

Swiftの**プロパティオブザーバー（Property Observer）**は、プロパティの値が変更されたときに自動的に実行されるコードを定義できる機能です。

## 2種類のプロパティオブザーバー

| オブザーバー | タイミング | 説明 |
|------------|----------|------|
| `willSet` | 値が変更される**直前** | 新しい値にアクセスできる |
| `didSet` | 値が変更された**直後** | 古い値にアクセスできる |

## didSet - 値変更後の処理

### 基本的な使い方

```swift
class Counter {
    var count: Int = 0 {
        didSet {
            print("カウントが変更されました: \(oldValue) → \(count)")
        }
    }
}

let counter = Counter()
counter.count = 5
// 出力: "カウントが変更されました: 0 → 5"
```

### 特徴

- `didSet`ブロック内では：
  - `oldValue`で**変更前の値**にアクセスできる（省略可能）
  - プロパティ名（`count`）で**変更後の値**にアクセスできる

### このアプリでの使用例

[Cart.swift:4-8](sampleShop/Model/Cart.swift#L4-L8)

```swift
class Cart: ObservableObject {
    @Published var items: [Product] = [] {
        didSet {
            saveItems()  // itemsが変更されるたびに自動保存
        }
    }

    private func saveItems() {
        // UserDefaultsに保存
        let data = try JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
```

**動作の流れ**:

```swift
// 1. 商品を追加
cart.add(Product(id: 1, title: "iPhone", price: 999, thumbnail: ""))

// 2. items.append()が実行される
// ↓
// 3. itemsの値が変更される
// ↓
// 4. didSetが自動的に発火
// ↓
// 5. saveItems()が呼ばれる
// ↓
// 6. UserDefaultsに保存される
```

**メリット**:
- `add()`や`remove()`で個別に`saveItems()`を呼ぶ必要がない
- 保存処理を忘れるリスクがゼロ
- コードが簡潔になる

### oldValueの使用例

```swift
var temperature: Double = 20.0 {
    didSet {
        if temperature > oldValue {
            print("気温が上がりました: \(oldValue)°C → \(temperature)°C")
        } else if temperature < oldValue {
            print("気温が下がりました: \(oldValue)°C → \(temperature)°C")
        }
    }
}

temperature = 25.0
// 出力: "気温が上がりました: 20.0°C → 25.0°C"
```

### 実用例: バリデーション

```swift
class User {
    var age: Int = 0 {
        didSet {
            if age < 0 {
                print("警告: 年齢が負の値です。0に戻します")
                age = 0  // 不正な値を修正
            }
        }
    }
}

let user = User()
user.age = -5
// 出力: "警告: 年齢が負の値です。0に戻します"
// user.age は 0 になる
```

## willSet - 値変更前の処理

### 基本的な使い方

```swift
class Account {
    var balance: Double = 0 {
        willSet {
            print("残高を変更しようとしています")
            print("現在: \(balance), 新しい値: \(newValue)")
        }
    }
}

let account = Account()
account.balance = 1000
// 出力: "残高を変更しようとしています"
//      "現在: 0.0, 新しい値: 1000.0"
```

### 特徴

- `willSet`ブロック内では：
  - `newValue`で**変更後の値**にアクセスできる（省略可能）
  - プロパティ名（`balance`）で**変更前の値**にアクセスできる

### 実用例: UI更新の準備

```swift
class ProgressBar {
    var progress: Double = 0.0 {
        willSet {
            // アニメーションの準備
            if newValue > progress {
                startIncreaseAnimation()
            } else {
                startDecreaseAnimation()
            }
        }
        didSet {
            // 実際のUI更新
            updateProgressBar()
        }
    }
}
```

## didSet と willSet を両方使う

```swift
var score: Int = 0 {
    willSet {
        print("スコアを変更します: \(score) → \(newValue)")
    }
    didSet {
        print("スコアが変更されました")
        if score > oldValue {
            print("+\(score - oldValue)点獲得！")
        }
    }
}

score = 100
// 出力:
// "スコアを変更します: 0 → 100"
// "スコアが変更されました"
// "+100点獲得！"
```

**実行順序**:
1. `willSet` が実行される
2. 値が実際に変更される
3. `didSet` が実行される

## 使用できる場所

### ✅ 使える

```swift
// 1. クラスや構造体のプロパティ
class MyClass {
    var value: Int = 0 {
        didSet { print("変更") }
    }
}

// 2. ローカル変数（関数内）
func test() {
    var count: Int = 0 {
        didSet { print(count) }
    }
    count = 5
}

// 3. グローバル変数
var globalValue: Int = 0 {
    didSet { print("グローバル変更") }
}
```

### ❌ 使えない

```swift
// 1. 計算プロパティには使えない
var computed: Int {
    get { return 10 }
    // didSet { } // ❌ エラー
}

// 2. let定数には使えない
let constant: Int = 0 {
    // didSet { } // ❌ エラー（値が変更されないため）
}

// 3. @Publishedと組み合わせる場合は注意
@Published var items: [Int] = [] {
    didSet { }  // ✅ これはOK
}
```

## @Published との組み合わせ

このアプリで使われているパターン：

```swift
@Published var items: [Product] = [] {
    didSet {
        saveItems()
    }
}
```

**動作の流れ**:
1. `items`が変更される
2. `@Published`がビューに変更を通知
3. `didSet`が実行される

**注意点**:
- `didSet`内で同じプロパティを変更すると、無限ループになる可能性がある
- その場合は別のプロパティや条件分岐で制御する

```swift
// ❌ 無限ループの危険
@Published var items: [Product] = [] {
    didSet {
        items = items.sorted()  // これはNG！
    }
}

// ✅ 別のフラグで制御
private var isUpdating = false

@Published var items: [Product] = [] {
    didSet {
        guard !isUpdating else { return }
        isUpdating = true
        items = items.sorted()
        isUpdating = false
    }
}
```

## 実用的なユースケース

### 1. データの永続化（このアプリ）

```swift
var items: [Product] = [] {
    didSet {
        saveToUserDefaults()
    }
}
```

### 2. ログ記録

```swift
var currentUser: User? {
    didSet {
        if let user = currentUser {
            Analytics.log("User logged in: \(user.id)")
        } else {
            Analytics.log("User logged out")
        }
    }
}
```

### 3. UI更新

```swift
var isDarkMode: Bool = false {
    didSet {
        updateTheme()
        savePreference()
    }
}
```

### 4. 連動する値の更新

```swift
var firstName: String = "" {
    didSet {
        updateFullName()
    }
}

var lastName: String = "" {
    didSet {
        updateFullName()
    }
}

private(set) var fullName: String = ""

private func updateFullName() {
    fullName = "\(firstName) \(lastName)"
}
```

### 5. バリデーションと制限

```swift
var volume: Int = 50 {
    didSet {
        // 0-100の範囲に制限
        if volume < 0 {
            volume = 0
        } else if volume > 100 {
            volume = 100
        }
    }
}
```

## パフォーマンスの考慮

### 注意点

`didSet`は値が変更されるたびに実行されるため、重い処理を入れると性能に影響します。

```swift
// ❌ パフォーマンスに悪影響
var searchText: String = "" {
    didSet {
        // ユーザーが1文字入力するたびにAPIリクエスト
        fetchSearchResults()  // 重い処理
    }
}

// ✅ デバウンスを使う
var searchText: String = "" {
    didSet {
        // 0.3秒後に実行（連続入力時はキャンセル）
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(fetchSearchResults), with: nil, afterDelay: 0.3)
    }
}
```

## まとめ

| 項目 | didSet | willSet |
|------|--------|---------|
| タイミング | 値変更**後** | 値変更**前** |
| アクセス可能な値 | `oldValue`（変更前）と新しい値 | `newValue`（変更後）と現在の値 |
| 主な用途 | 保存、ログ、UI更新 | アニメーション準備、事前チェック |
| 使用頻度 | ⭐⭐⭐⭐⭐ よく使う | ⭐⭐⭐ たまに使う |

**ベストプラクティス**:
- データ保存や副作用の処理には`didSet`を使う
- 重い処理は避ける、または最適化する
- 無限ループに注意（同じプロパティを変更しない）
- このアプリのように自動保存機能に最適
