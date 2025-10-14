# 快速参考指南

## 项目配置清单

### 1. Xcode 项目设置

#### 文件 Target Membership
```
✅ Extension Target:
   - ShareView.swift
   - ShareViewController.swift
   - SharedItemModel.swift (Shared)

✅ App Target:
   - MainView.swift
   - SharedItem.swift
   - SharedItemRow.swift
   - SharedItemModel.swift (Shared)
   - SceneDelegateHelper.swift
```

#### App Groups 配置
```
App Target:       group.cc.raoqu.transany ✓
Extension Target: group.cc.raoqu.transany ✓
```

### 2. 关键文件说明

| 文件 | 位置 | 用途 |
|-----|------|-----|
| `SharedItemModel.swift` | Shared/ | 统一数据模型 |
| `ShareView.swift` | Extension/ | SwiftUI 分享界面 |
| `ShareViewController.swift` | Extension/ | Extension 入口 |
| `SharedItem.swift` | App/ | 主应用数据管理 |
| `MainView.swift` | App/ | 主应用界面 |

### 3. 文档索引

| 文档 | 内容 |
|-----|------|
| `STANDARD_STORAGE_FORMAT.md` | 📚 存储格式完整文档 |
| `SWIFTUI_SETUP_CHECKLIST.md` | ✅ SwiftUI 配置清单 |
| `MIGRATION_TO_SWIFTUI.md` | 🔄 迁移指南 |
| `LIST_STORAGE_GUIDE.md` | 📋 列表存储说明 |
| `APP_GROUP_SETUP.md` | 🔧 App Group 配置 |

## 常用代码片段

### Extension - 保存图片

```swift
// 获取图片数据
if let image = try? await provider.loadItem(...) as? UIImage,
   let imageData = image.jpegData(compressionQuality: 0.8) {
    
    // 创建元数据
    let metadata: [String: String] = [
        "width": "\(Int(image.size.width))",
        "height": "\(Int(image.size.height))"
    ]
    
    // 创建并保存
    if let item = SharedItemModel.createPhotoItem(
        title: userComment,
        imageData: imageData,
        metadata: metadata
    ) {
        SharedStorageManager.shared.saveItem(item)
    }
}
```

### Extension - 保存 PDF

```swift
if let pdfData = try? await provider.loadItem(...) as? Data {
    let metadata = ["size": "\(pdfData.count)"]
    
    if let item = SharedItemModel.createPDFItem(
        title: userComment,
        pdfData: pdfData,
        metadata: metadata
    ) {
        SharedStorageManager.shared.saveItem(item)
    }
}
```

### Extension - 保存文本

```swift
let textItem = SharedItemModel.createTextItem(
    title: userComment,
    text: textContent,
    metadata: ["length": "\(textContent.count)"]
)
SharedStorageManager.shared.saveItem(textItem)
```

### Extension - 保存 URL

```swift
let urlItem = SharedItemModel.createURLItem(
    title: userComment,
    url: urlString,
    metadata: ["host": url.host ?? ""]
)
SharedStorageManager.shared.saveItem(urlItem)
```

### App - 加载数据

```swift
// 在 Manager 中
let storage = SharedStorageManager.shared
let items = storage.loadItems()
```

### App - 显示图片

```swift
if let fileURL = storage.getFileURL(relativePath: item.filePath) {
    AsyncImage(url: fileURL) { image in
        image.resizable()
    } placeholder: {
        ProgressView()
    }
}
```

### App - 删除项目

```swift
SharedStorageManager.shared.deleteItem(id: item.id)
```

### App - 清空所有

```swift
SharedStorageManager.shared.clearAll()
```

## 支持的内容类型

| Type | Extension | Icon | Example |
|------|-----------|------|---------|
| photo | .jpg | 📷 | JPG, JPEG, PNG |
| pdf | .pdf | 📄 | PDF 文档 |
| excel | .xlsx | 📊 | Excel 表格 |
| text | - | 📝 | 纯文本 |
| url | - | 🔗 | 网页链接 |
| video | .mp4 | 🎬 | MP4 视频 |

## 目录结构

```
Example/
├── App/                           # 主应用
│   ├── MainView.swift            # 主界面
│   ├── SharedItem.swift          # 数据管理
│   ├── SharedItemRow.swift       # 列表行
│   ├── SceneDelegateHelper.swift # Scene 帮助
│   └── Info.plist
│
├── Extension/                     # Share Extension
│   ├── ShareView.swift           # SwiftUI 界面
│   ├── ShareViewController.swift # 入口控制器
│   └── Info.plist
│
├── Shared/                        # 共享代码
│   └── SharedItemModel.swift     # 统一数据模型
│
└── Docs/                          # 文档
    ├── STANDARD_STORAGE_FORMAT.md
    ├── SWIFTUI_SETUP_CHECKLIST.md
    └── ...
```

## App Group 容器结构

```
group.cc.raoqu.transany/
├── Library/
│   └── Preferences/
│       └── group.cc.raoqu.transany.plist  # UserDefaults
│
└── SharedFiles/                            # 文件存储
    ├── {uuid}.jpg                          # 图片
    ├── {uuid}.pdf                          # PDF
    └── {uuid}.mp4                          # 视频
```

## 调试技巧

### 查看 Console 日志

```
Extension 保存:
📋 Saving items using new standard format...
✅ Saved: [photo] 美丽风景

App 加载:
🔄 Loading shared items from UserDefaults...
✅ Loaded 1 items (New Standard Format)
```

### 验证 App Group

```swift
// 打印容器路径
if let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.cc.raoqu.transany"
) {
    print("Container: \(containerURL.path)")
}
```

### 检查文件

```swift
let storage = SharedStorageManager.shared
if let filesDir = storage.sharedFilesDirectory {
    let files = try? FileManager.default.contentsOfDirectory(atPath: filesDir.path)
    print("Files: \(files ?? [])")
}
```

## 常见问题

### Q: Extension 不显示？
**A:** 
1. 检查 Info.plist NSExtensionPrincipalClass
2. 确认 App Groups 配置
3. 完全卸载重装应用

### Q: 数据不共享？
**A:**
1. 验证两个 target 使用相同的 App Group ID
2. 检查 Console 日志
3. 确认文件已保存

### Q: 编译错误？
**A:**
1. Clean Build Folder
2. 检查文件 Target Membership
3. 确认 Swift 版本 >= 5

### Q: 图片不显示？
**A:**
1. 检查文件路径是否正确
2. 验证文件确实已保存
3. 确认文件权限

## 性能建议

### 图片优化
```swift
// 压缩质量
let imageData = image.jpegData(compressionQuality: 0.8)

// 缩略图
let thumbnailSize = CGSize(width: 200, height: 200)
let thumbnail = image.preparingThumbnail(of: thumbnailSize)
```

### 限制大小
```swift
// 文件大小限制
let maxSize = 10 * 1024 * 1024  // 10MB

// 列表数量限制
let maxItems = 100
```

### 异步处理
```swift
Task {
    await processItems()
}
```

## 版本兼容

| 功能 | iOS 版本 |
|-----|---------|
| Share Extension | iOS 8+ |
| SwiftUI Extension | iOS 15+ |
| async/await | iOS 15+ |
| App Groups | iOS 8+ |

## 下一步

1. ✅ 配置 App Groups
2. ✅ 添加 SharedItemModel.swift 到两个 target
3. ✅ 更新 Extension 使用新格式
4. ✅ 更新 App 加载逻辑
5. ✅ 测试分享功能
6. ✅ 验证文件保存
7. ✅ 测试数据同步

---

**快速链接：**
- 📚 [完整文档](STANDARD_STORAGE_FORMAT.md)
- ✅ [配置清单](SWIFTUI_SETUP_CHECKLIST.md)
- 🔧 [App Group 设置](APP_GROUP_SETUP.md)
