# 列表存储机制说明

## 概述

TransAny 使用**累积式列表存储**，每次分享都会添加到历史记录中，不会覆盖之前的内容。

## 数据结构

### UserDefaults 存储格式

```swift
// App Group UserDefaults: "group.cc.raoqu.transany"
// Key: "SharedItems"
// Value: Array of Dictionaries

[
    {
        "title": "用户输入的描述",
        "type": "image",
        "content": "图片 750×1334",
        "timestamp": Date()
    },
    {
        "title": "网页标题",
        "type": "url",
        "content": "https://example.com",
        "timestamp": Date()
    },
    // ... 更多项目
]
```

### 主应用格式

主应用使用 `SharedItem` 结构体：

```swift
struct SharedItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let contentType: SharedContentType
    let content: String
    let timestamp: Date
}
```

## 工作流程

### 1. 分享新内容

```
用户分享照片
    ↓
Extension 处理
    ↓
加载现有列表 (existingItems)
    ↓
在开头插入新项目 (insert at 0)
    ↓
保存回 UserDefaults
    ↓
列表更新完成
```

**代码实现（ShareView.swift）：**
```swift
// 加载现有项目列表
var existingItems = defaults.array(forKey: sharedItemsKey) as? [[String: Any]] ?? []
print("📋 Loading existing items: \(existingItems.count) items")

// 在列表开头插入新项目（最新的在最前面）
existingItems.insert(itemDict, at: 0)

// 保存回 UserDefaults
defaults.set(existingItems, forKey: sharedItemsKey)
```

### 2. 主应用加载

```
主应用启动/刷新
    ↓
从 UserDefaults 加载列表
    ↓
转换为 SharedItem 对象
    ↓
在 UI 中显示
    ↓
最新的在最前面
```

**代码实现（SharedItem.swift）：**
```swift
// 从 UserDefaults 加载
if let dictArray = defaults.array(forKey: userDefaultsKey) as? [[String: Any]] {
    items = dictArray.compactMap { dict -> SharedItem? in
        // 转换每个字典为 SharedItem
    }
}
```

## 列表顺序

### 时间顺序
- **最新的在最前面** (index 0)
- 旧的项目依次往后排
- 按照分享时间倒序排列

### 示例
```
Index 0: 刚刚分享的照片     (最新)
Index 1: 5分钟前分享的链接
Index 2: 1小时前分享的文本
Index 3: 昨天分享的图片
...
Index 99: 最早的记录        (最旧)
```

## 列表大小限制

### 为什么需要限制？
- 防止 UserDefaults 占用过多存储空间
- 提升加载性能
- 避免 UI 列表过长

### 当前限制
```swift
let maxItems = 100  // 保留最新的 100 条记录
```

### 自动清理
当列表超过限制时，自动删除最旧的项目：

```swift
if existingItems.count > maxItems {
    existingItems = Array(existingItems.prefix(maxItems))
    print("✂️ Trimmed to \(maxItems) items")
}
```

## 数据流图

```
┌─────────────────────────────────────────────────────────┐
│                    App Group UserDefaults                │
│              "group.cc.raoqu.transany"                   │
│                  Key: "SharedItems"                      │
│                                                           │
│  [Item 0] 最新 ← Extension 插入                          │
│  [Item 1]                                                │
│  [Item 2]                                                │
│  [Item 3]                                                │
│  ...                                                     │
│  [Item 99] 最旧 ← 超过限制时被删除                       │
└─────────────────────────────────────────────────────────┘
            ↑                               ↓
    Extension 保存                   主应用加载
            │                               │
            │                               │
┌───────────────────┐           ┌─────────────────────┐
│  Share Extension  │           │     Main App         │
│                   │           │                      │
│  1. 处理分享内容  │           │  1. 读取列表         │
│  2. 加载现有列表  │           │  2. 转换为 Model    │
│  3. 插入新项目   │           │  3. 显示在 UI       │
│  4. 保存列表     │           │  4. 支持删除/清空   │
└───────────────────┘           └─────────────────────┘
```

## 多次分享示例

### 场景：用户连续分享 3 次

#### 第 1 次分享（照片）
```
操作前: []
添加: {title: "美丽风景", type: "image", ...}
操作后: [照片]
总数: 1
```

#### 第 2 次分享（网页）
```
操作前: [照片]
添加: {title: "新闻", type: "url", ...}
操作后: [网页, 照片]
总数: 2
```

#### 第 3 次分享（文本）
```
操作前: [网页, 照片]
添加: {title: "笔记", type: "text", ...}
操作后: [文本, 网页, 照片]
总数: 3
```

### UI 显示效果

主应用的列表会显示：
```
┌──────────────────────────────────┐
│  TransAny                    ⋯  │
│  3 项内容                        │
├──────────────────────────────────┤
│  📝 笔记                         │
│  文本内容预览...                 │
│  刚刚                            │
├──────────────────────────────────┤
│  🔗 新闻                         │
│  https://example.com/news       │
│  5分钟前                         │
├──────────────────────────────────┤
│  📷 美丽风景                     │
│  图片 750×1334                  │
│  10分钟前                        │
└──────────────────────────────────┘
```

## 调试和验证

### Console 日志输出

#### Extension 保存时
```
📋 Loading existing items: 2 items
➕ Added: [text] 笔记
✅ Saved successfully! Total items: 3 (was: 2)
```

#### 主应用加载时
```
🔄 Loading shared items from UserDefaults...
📋 Found 3 items (Dictionary format)
✅ Converted to 3 SharedItem objects
```

### 验证步骤

1. **清空现有数据**
   - 在主应用点击"清空所有"
   - 确认列表为空

2. **第一次分享**
   - 分享一张照片
   - 主应用应显示：`1 项内容`
   - 列表包含 1 个项目

3. **第二次分享**
   - 分享一个网页
   - 主应用应显示：`2 项内容`
   - 网页在照片上方

4. **第三次分享**
   - 分享一段文本
   - 主应用应显示：`3 项内容`
   - 文本在最上方

## 性能优化

### UserDefaults 读写
- ✅ 使用 App Group 共享
- ✅ 同步调用 `synchronize()`
- ✅ 限制列表大小避免过大数据

### 主应用加载
- ✅ 异步加载 `async/await`
- ✅ 仅在需要时刷新
- ✅ 使用 `@Published` 自动更新 UI

### 内存管理
- ✅ 最多保存 100 条记录
- ✅ 自动清理旧数据
- ⚠️ 图片不保存实际数据（仅元信息）

## 常见问题

### Q: 分享后主应用看不到新内容？
**A:** 
1. 检查 Console 日志
2. 确认 App Group 配置正确
3. 手动触发刷新（返回前台）

### Q: 列表顺序不对？
**A:**
- 确认使用 `insert(at: 0)` 而非 `append()`
- 最新的应该在 index 0

### Q: 旧数据会被删除吗？
**A:**
- 只在超过 100 条时删除最旧的
- 手动"清空所有"会全部删除
- 单个删除不影响其他项

### Q: 如何修改列表大小限制？
**A:**
修改 `ShareView.swift` 中的：
```swift
let maxItems = 100  // 改成你想要的数量
```

## 未来扩展建议

1. **分类管理**
   - 按类型分组（图片/链接/文本）
   - 支持标签系统

2. **搜索功能**
   - 按标题搜索
   - 按内容搜索
   - 按日期筛选

3. **导出功能**
   - 导出为 JSON
   - 导出为 CSV
   - 批量导出

4. **云同步**
   - iCloud 同步
   - 跨设备共享

5. **持久化优化**
   - 使用 Core Data
   - 使用 SQLite
   - 图片保存到文件系统

---

**结论：** 当前实现已经是完整的累积式列表存储，每次分享都会保留历史记录，不会覆盖！✅
