# SwiftUIの設計思想: Viewが値型である理由

SwiftUIでは**Viewは必ずstruct（値型）**で定義します。これは偶然ではなく、SwiftUIの根幹をなす設計思想に基づいています。

## 従来のUIKit（参照型）の問題点

### UIKitの設計（Class-based）

```swift
// UIKit: Classベース
class MyViewController: UIViewController {
    var label: UILabel!
    var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // UIを手動で構築
        label = UILabel()
        label.text = "Hello"
        view.addSubview(label)

        button = UIButton()
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc func buttonTapped() {
        label.text = "Tapped!"
    }
}
```

**問題点**:

1. **状態とUIが分離している**
   - `label.text`を変更しても、それがいつどこで変わったか追跡しにくい
   - UIの更新を手動で管理する必要がある

2. **可変性（Mutability）が高い**
   - どこからでも`label.text`を書き換えられる
   - 予期しない変更が起きやすい

3. **複雑な状態管理**
   - UIの状態がクラスのプロパティとして散らばる
   - デバッグが困難

4. **メモリ管理**
   - 循環参照のリスク
   - `weak`や`unowned`を適切に使う必要がある

## SwiftUIの設計思想

### 1. 宣言的UI（Declarative UI）

**命令的（Imperative）vs 宣言的（Declarative）**

```swift
// UIKit: 命令的（HOW - どうやって作るか）
func updateUI() {
    if isLoggedIn {
        loginButton.isHidden = true
        logoutButton.isHidden = false
        welcomeLabel.text = "Welcome, \(username)"
    } else {
        loginButton.isHidden = false
        logoutButton.isHidden = true
        welcomeLabel.text = "Please log in"
    }
}

// SwiftUI: 宣言的（WHAT - 何を表示するか）
var body: some View {
    if isLoggedIn {
        VStack {
            Text("Welcome, \(username)")
            Button("Logout") { logout() }
        }
    } else {
        VStack {
            Text("Please log in")
            Button("Login") { login() }
        }
    }
}
```

**SwiftUIの考え方**:
- 「今の状態ならこう表示される」を記述する
- 状態が変わればUIが自動的に更新される
- UIの更新方法は考えなくていい

### 2. 不変性（Immutability）

**Viewは状態のスナップショット**

```swift
struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
        }
    }
}
```

**何が起きているか**:

```
1. 初期状態: count = 0
   → ContentView(count: 0) が作られる（struct）
   → Text("Count: 0") が表示される

2. ボタンタップ: count = 1
   → 新しいContentView(count: 1) が作られる（新しいstruct）
   → Text("Count: 1") が表示される

3. ボタンタップ: count = 2
   → 新しいContentView(count: 2) が作られる（新しいstruct）
   → Text("Count: 2") が表示される
```

**重要なポイント**:
- Viewは毎回**新しく作り直される**
- 前のViewは捨てられる
- 状態（count）だけが保持される

### 3. 単一方向データフロー（Unidirectional Data Flow）

```
     状態（State）
         ↓
      View
         ↓
      イベント
         ↓
     状態を更新
         ↓
     （最初に戻る）
```

```swift
struct CounterView: View {
    @State private var count = 0  // ← 状態

    var body: some View {  // ← 状態からViewを生成
        VStack {
            Text("Count: \(count)")

            Button("Increment") {  // ← イベント
                count += 1  // ← 状態を更新
            }
            // → 自動的にbodyが再評価される
        }
    }
}
```

**なぜ値型が必要か**:
- 状態が変わるたびに新しいViewを作る
- 古いViewは捨てられる
- これを効率的に行うには値型（struct）が最適

## 値型（Struct）がもたらすメリット

### 1. 予測可能性（Predictability）

```swift
// Struct: 予測可能
struct MyView: View {
    let title: String  // 外から変更できない

    var body: some View {
        Text(title)
        // titleは常に初期値のまま
    }
}

// もしClassだったら...
class MyView: View {  // ❌ 実際にはできない
    var title: String  // どこからでも変更できてしまう

    var body: some View {
        Text(title)
        // title が別の場所で変わっているかも？
    }
}
```

### 2. スレッドセーフティ

```swift
// Struct: コピーされるので安全
let view1 = MyView(title: "Hello")
let view2 = view1  // 完全に別のコピー

// 別スレッドで変更しても影響なし
DispatchQueue.global().async {
    var view3 = view2
    // view3.title = "Changed"  // letなので変更不可
}
```

### 3. パフォーマンス最適化

SwiftUIは内部的に**差分検出（Diffing）**を行います。

```swift
struct ProductListView: View {
    let products: [Product]

    var body: some View {
        List(products) { product in
            ProductRow(product: product)
        }
    }
}
```

**Structだからできること**:

1. **効率的な比較**
   ```swift
   // 古いView
   ProductRow(product: Product(id: 1, name: "iPhone", price: 999))

   // 新しいView
   ProductRow(product: Product(id: 1, name: "iPhone", price: 999))

   // → 値が同じなので再描画不要（最適化）
   ```

2. **Copy-on-Write**
   ```swift
   // Swiftの最適化により、実際にはコピーされない
   // 変更があった時のみコピーが作られる
   ```

### 4. 関数型プログラミングの親和性

```swift
struct MyView: View {
    let items: [String]

    var body: some View {
        VStack {
            // map, filter などの関数型操作が自然
            ForEach(items.filter { $0.count > 3 }, id: \.self) { item in
                Text(item)
            }
        }
    }
}
```

**Viewは関数のようなもの**:
- 入力（プロパティ）を受け取る
- 出力（body）を返す
- 副作用がない（純粋関数）

## SwiftUIの内部動作

### Viewの生成と破棄

```swift
struct ContentView: View {
    @State private var count = 0

    var body: some View {
        print("body が評価されました")  // デバッグ用

        return VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}
```

**実行すると**:
```
初回表示: "body が評価されました"
ボタンタップ: "body が評価されました"
ボタンタップ: "body が評価されました"
...
```

**重要**: `body`は何度も評価される！

### なぜ何度も評価しても大丈夫？

1. **Structは軽量**
   ```swift
   // これは非常に軽い操作
   let view = ContentView(count: 1)
   ```

2. **実際のUIは賢く更新される**
   ```swift
   // SwiftUIは差分だけを更新
   Text("Count: 0") → Text("Count: 1")
   // Buttonは変わっていないので更新しない
   ```

3. **レンダリングと分離**
   ```
   Viewの生成（軽い） → 差分検出 → 実際のレンダリング（必要な部分のみ）
   ```

## 実際のコード例で理解する

### このアプリでの例

[ContentView.swift](sampleShop/ContentView.swift)

```swift
struct ContentView: View {
    @StateObject private var service = ProductService()
    @EnvironmentObject var cart: Cart

    var body: some View {
        // この body は何度も評価される
        NavigationStack {
            Group {
                if service.isLoading {
                    ProgressView("読み込み中...")
                } else if service.products.isEmpty {
                    Text("商品がありません")
                } else {
                    List(service.products) { product in
                        // ...
                    }
                }
            }
        }
    }
}
```

**動作**:

1. 初回表示: `service.isLoading = true`
   ```swift
   ContentView(service: <loading>, cart: <empty>)
   → ProgressView が表示される
   ```

2. API取得完了: `service.products = [...]`
   ```swift
   新しい ContentView(service: <loaded>, cart: <empty>)
   → List が表示される
   ```

3. カート追加: `cart.items = [product1]`
   ```swift
   新しい ContentView(service: <loaded>, cart: <1 item>)
   → ツールバーの数字が更新される
   ```

**Structだから**:
- 状態が変わるたびに新しいViewが作られる
- 古いViewのことは気にしなくていい
- 常に「今の状態」を表すViewが存在する

## 他のフレームワークとの比較

### React（JavaScript）

Reactも同じ思想を採用しています。

```jsx
// React: 関数コンポーネント（SwiftUIに近い）
function Counter() {
    const [count, setCount] = useState(0);

    return (
        <div>
            <p>Count: {count}</p>
            <button onClick={() => setCount(count + 1)}>
                Increment
            </button>
        </div>
    );
}
```

- 関数が何度も実行される
- 状態が変わると新しいVirtual DOMが作られる
- 差分検出で効率的に更新

### Flutter（Dart）

Flutterも同じ思想です。

```dart
// Flutter: StatelessWidget
class MyWidget extends StatelessWidget {
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text('Count: $count');
  }
}
```

- Widgetは不変（immutable）
- buildメソッドが何度も呼ばれる

## なぜClassではダメなのか

### もしViewがClassだったら...

```swift
// ❌ もしこう書けたとしたら（実際は書けない）
class ContentView: View {
    var count = 0  // Classのプロパティ

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                self.count += 1  // ← これで更新される？
            }
        }
    }
}
```

**問題**:

1. **UIが更新されない**
   - `count`を変更しても、SwiftUIは知らない
   - `body`が再評価されない

2. **どこで変更されたか追跡できない**
   ```swift
   let view = ContentView()
   view.count = 10  // どこからでも変更可能
   anotherFunction(view)  // この中で変更されるかも
   ```

3. **メモリ管理が複雑**
   ```swift
   class ContentView: View {
       var someObject: SomeClass  // 循環参照の危険
   }
   ```

## まとめ

### SwiftUIの設計思想

| 思想 | 説明 | 値型の役割 |
|------|------|----------|
| **宣言的UI** | 「何を表示するか」を記述 | 状態のスナップショットとして機能 |
| **不変性** | Viewは変更されず、作り直される | Structは自然に不変 |
| **単一方向データフロー** | 状態 → View → イベント → 状態 | 予測可能な動作を保証 |
| **関数型** | Viewは純粋関数のようなもの | 副作用がない |

### 値型（Struct）がもたらすもの

| メリット | 説明 |
|---------|------|
| **予測可能性** | 外から勝手に変更されない |
| **スレッドセーフティ** | コピーされるので安全 |
| **パフォーマンス** | 差分検出が効率的 |
| **シンプルさ** | メモリ管理が簡単 |

### 設計の根底にある考え方

```
UI = f(State)

Viewは状態の関数である
状態が変われば、Viewも変わる
でも、Viewそのものは変更されない（作り直される）
```

**これこそが「Viewは値型であるべき」という思想の核心です。**

### 実用的な意味

開発者として覚えておくべきこと：

1. **Viewは軽量に保つ**
   - 何度も作り直されることを前提に設計
   - 重い処理はViewの外で行う

2. **状態は@Stateや@ObservedObjectで管理**
   - Viewのプロパティに状態を持たせない

3. **Viewは純粋に見た目の記述**
   - ビジネスロジックは別の場所に

4. **この思想を理解すれば、SwiftUIの動作が自然に理解できる**
   - なぜbodyが何度も呼ばれるのか
   - なぜ@Stateが必要なのか
   - なぜstructなのか

**すべては「Viewは状態のスナップショットである」という思想から来ています。**
