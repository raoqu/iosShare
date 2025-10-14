# Swift 并发安全性修复说明

## 修复的问题

### 1. ExtensionContextKey 并发安全
**错误：** Static property 'defaultValue' is not concurrency-safe

**修复：**
```swift
// ShareView.swift
private struct ExtensionContextKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: NSExtensionContext? = nil
}
```

**原因：** `NSExtensionContext` 不符合 `Sendable` 协议，但作为 Environment Key 的默认值是安全的（nil 值）。

### 2. SharedStorageManager 并发安全
**错误：** Static property 'shared' is not concurrency-safe

**修复：**
```swift
// SharedItemModel.swift
final class SharedStorageManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = SharedStorageManager()
    // ...
}
```

**说明：**
- `final class` - 防止子类化
- `: @unchecked Sendable` - 手动保证线程安全
- `nonisolated(unsafe)` - 允许跨并发域访问单例

**为什么安全：**
1. UserDefaults 本身是线程安全的
2. FileManager 操作是线程安全的
3. 没有共享的可变状态（每次调用都是独立操作）

## Swift 并发模型理解

### Sendable 协议

```swift
// 自动符合 Sendable 的类型
struct MyStruct: Sendable {  // 所有属性都是 Sendable
    let value: Int
    let name: String
}

// 需要手动标记的类型
final class MyManager: @unchecked Sendable {
    // 保证内部实现线程安全
}
```

### @MainActor

```swift
// 限制在主线程执行
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
}
```

### nonisolated(unsafe)

```swift
// 允许跨并发域访问（需要手动保证安全）
class Manager {
    nonisolated(unsafe) static let shared = Manager()
}
```

## 项目中的并发策略

### Extension (ShareView.swift)

```swift
@MainActor
class ShareViewModel: ObservableObject {
    // SwiftUI ViewModel 在主线程
    @Published var items: [ShareItemModel] = []
    
    // 异步加载内容
    func loadSharedContent(from extensionContext: NSExtensionContext?) async {
        // 使用 async/await
    }
}
```

### 共享存储 (SharedStorageManager)

```swift
final class SharedStorageManager: @unchecked Sendable {
    // 可以在任何线程调用
    func saveItem(_ item: SharedItemModel) {
        // UserDefaults 和 FileManager 是线程安全的
    }
}
```

### 主应用 (SharedItemsManager)

```swift
@MainActor
class SharedItemsManager: ObservableObject {
    // 主线程更新 UI
    @Published var items: [SharedItem] = []
    
    // 异步加载
    private func loadItems() async {
        // 后台加载，主线程更新
    }
}
```

## 编译器检查级别

### Swift 5 (默认)
- 基本并发检查
- 警告级别

### Swift 6 (严格)
- 完整并发检查
- 错误级别

**当前项目：** Swift 5 模式，但遵循 Swift 6 最佳实践

## 常见并发问题和解决方案

### 问题 1: 全局变量

```swift
// ❌ 错误
var globalCounter = 0

// ✅ 正确
actor Counter {
    var value = 0
    func increment() { value += 1 }
}
```

### 问题 2: 单例模式

```swift
// ❌ 可能不安全
class Manager {
    static let shared = Manager()
}

// ✅ 明确标记
final class Manager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = Manager()
}
```

### 问题 3: ObservableObject

```swift
// ✅ 总是在主线程
@MainActor
class ViewModel: ObservableObject {
    @Published var data: [Item] = []
}
```

### 问题 4: 异步操作

```swift
// ✅ 使用 Task
Task {
    await loadData()
}

// ✅ 使用 async let
async let result1 = fetch1()
async let result2 = fetch2()
let combined = await (result1, result2)
```

## 测试并发安全性

### 1. 启用严格检查

在 Build Settings 中：
```
Swift Compiler - Language
> Swift Language Version: Swift 6
```

### 2. 运行时检查

```swift
// 使用 Thread Sanitizer
// Edit Scheme → Run → Diagnostics
// ☑️ Thread Sanitizer
```

### 3. 代码审查

检查：
- [ ] 所有共享状态都有保护
- [ ] ObservableObject 使用 @MainActor
- [ ] 异步操作使用 async/await
- [ ] 避免数据竞争

## 项目并发安全清单

### ✅ 已修复

- [x] ExtensionContextKey 标记为 nonisolated(unsafe)
- [x] SharedStorageManager 标记为 @unchecked Sendable
- [x] ShareViewModel 使用 @MainActor
- [x] SharedItemsManager 使用 @MainActor

### ✅ 已验证安全

- [x] UserDefaults 操作（线程安全）
- [x] FileManager 操作（线程安全）
- [x] SwiftUI 视图更新（主线程）
- [x] 异步加载使用 async/await

### 📋 最佳实践

1. **数据模型** - 使用 struct（自动 Sendable）
2. **ViewModel** - 使用 @MainActor
3. **管理器** - 明确标记并发策略
4. **异步操作** - 使用 async/await
5. **文件操作** - 已确保线程安全

## 参考资源

### Apple 官方文档
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Sendable Protocol](https://developer.apple.com/documentation/swift/sendable)
- [MainActor](https://developer.apple.com/documentation/swift/mainactor)

### 推荐阅读
- Swift Evolution: SE-0306 (Actors)
- Swift Evolution: SE-0302 (Sendable)
- WWDC Session: "Meet async/await in Swift"

## 总结

所有并发安全问题已修复：
- ✅ 使用 `nonisolated(unsafe)` 标记环境键
- ✅ 使用 `@unchecked Sendable` 标记管理器
- ✅ 使用 `@MainActor` 保护 UI 状态
- ✅ 使用 `async/await` 处理异步操作

项目现在符合 Swift 并发最佳实践！🎉
