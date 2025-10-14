# 统一分享内容存储格式标准

## 概述

TransAny 使用统一的标准格式存储所有分享内容，支持文件、文本、URL 等多种类型。

## 数据结构

### SharedItemModel

```swift
struct SharedItemModel: Codable, Identifiable {
    let id: String              // UUID 字符串
    let title: String           // 用户输入的描述
    let contentType: String     // photo, pdf, excel, text, url, video
    let filePath: String?       // 文件相对路径
    let textContent: String?    // 文本内容
    let metadata: [String: String]  // 扩展参数
    let timestamp: Date         // 创建时间
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| `id` | String | ✅ | 唯一标识符（UUID） |
| `title` | String | ✅ | 用户输入的标题/描述 |
| `contentType` | String | ✅ | 内容类型标识 |
| `filePath` | String? | ❌ | 文件相对路径（仅文件类型） |
| `textContent` | String? | ❌ | 文本内容（仅文本/URL类型） |
| `metadata` | [String: String] | ✅ | 扩展参数（可为空字典） |
| `timestamp` | Date | ✅ | 创建时间戳 |

## 内容类型

### 支持的类型

| contentType | 说明 | 存储方式 | 图标 |
|------------|------|---------|------|
| `photo` | 图片 | 文件 | 📷 photo.fill |
| `pdf` | PDF文档 | 文件 | 📄 doc.fill |
| `excel` | Excel表格 | 文件 | 📊 tablecells.fill |
| `text` | 纯文本 | 文本 | 📝 doc.text.fill |
| `url` | 网页链接 | 文本 | 🔗 link.circle.fill |
| `video` | 视频 | 文件 | 🎬 video.fill |

### 类型判断规则

```swift
// 文件类型：需要保存文件数据
if contentType in ["photo", "pdf", "excel", "video"] {
    // filePath 不为空
    // textContent 为空
}

// 文本类型：直接保存文本
if contentType in ["text", "url"] {
    // textContent 不为空
    // filePath 为空
}
```

## 文件存储

### 目录结构

```
App Group Container (group.cc.raoqu.transany)
└── SharedFiles/
    ├── 550e8400-e29b-41d4-a716-446655440000.jpg   # 照片
    ├── 660e8400-e29b-41d4-a716-446655440001.pdf   # PDF
    ├── 770e8400-e29b-41d4-a716-446655440002.xlsx  # Excel
    └── 880e8400-e29b-41d4-a716-446655440003.mp4   # 视频
```

### 文件命名规则

```swift
// 格式：{UUID}.{扩展名}
let filename = "\(UUID().uuidString).\(fileExtension)"

// 示例
"550e8400-e29b-41d4-a716-446655440000.jpg"
"660e8400-e29b-41d4-a716-446655440001.pdf"
```

### 文件路径存储

```swift
// filePath 存储相对路径
filePath = "550e8400-e29b-41d4-a716-446655440000.jpg"

// 读取时获取完整路径
let fullURL = SharedStorageManager.shared.getFileURL(relativePath: filePath)
```

## 扩展参数（metadata）

### 标准字段建议

| 类型 | 推荐字段 | 示例值 |
|-----|---------|--------|
| photo | width, height, format | "750", "1334", "jpeg" |
| pdf | size, pages | "1024000", "10" |
| url | host, scheme | "www.apple.com", "https" |
| text | length, language | "100", "zh-CN" |
| video | duration, resolution | "120", "1920x1080" |
| excel | sheets, rows | "3", "100" |

### 使用示例

```swift
// 创建带元数据的图片项
let metadata: [String: String] = [
    "width": "1920",
    "height": "1080",
    "format": "jpeg",
    "originalName": "sunset.jpg"
]

let item = SharedItemModel.createPhotoItem(
    title: "美丽的日落",
    imageData: imageData,
    metadata: metadata
)
```

## Extension 扩展方法

### 创建不同类型的存储项

#### 1. 创建图片项

```swift
// 方法签名
static func createPhotoItem(
    title: String,
    imageData: Data,
    metadata: [String: String] = [:]
) -> SharedItemModel?

// 使用示例
if let photoItem = SharedItemModel.createPhotoItem(
    title: "风景照片",
    imageData: jpegData,
    metadata: ["width": "1920", "height": "1080"]
) {
    SharedStorageManager.shared.saveItem(photoItem)
}
```

#### 2. 创建 PDF 项

```swift
// 方法签名
static func createPDFItem(
    title: String,
    pdfData: Data,
    metadata: [String: String] = [:]
) -> SharedItemModel?

// 使用示例
if let pdfItem = SharedItemModel.createPDFItem(
    title: "报告文档",
    pdfData: pdfData,
    metadata: ["size": "\(pdfData.count)", "pages": "10"]
) {
    SharedStorageManager.shared.saveItem(pdfItem)
}
```

#### 3. 创建 Excel 项

```swift
// 方法签名
static func createExcelItem(
    title: String,
    excelData: Data,
    metadata: [String: String] = [:]
) -> SharedItemModel?

// 使用示例
if let excelItem = SharedItemModel.createExcelItem(
    title: "数据表格",
    excelData: excelData,
    metadata: ["sheets": "3", "rows": "100"]
) {
    SharedStorageManager.shared.saveItem(excelItem)
}
```

#### 4. 创建文本项

```swift
// 方法签名
static func createTextItem(
    title: String,
    text: String,
    metadata: [String: String] = [:]
) -> SharedItemModel

// 使用示例
let textItem = SharedItemModel.createTextItem(
    title: "笔记",
    text: "这是一段文本内容",
    metadata: ["length": "9", "language": "zh"]
)
SharedStorageManager.shared.saveItem(textItem)
```

#### 5. 创建 URL 项

```swift
// 方法签名
static func createURLItem(
    title: String,
    url: String,
    metadata: [String: String] = [:]
) -> SharedItemModel

// 使用示例
let urlItem = SharedItemModel.createURLItem(
    title: "Apple 官网",
    url: "https://www.apple.com",
    metadata: ["host": "www.apple.com", "scheme": "https"]
)
SharedStorageManager.shared.saveItem(urlItem)
```

#### 6. 创建视频项

```swift
// 方法签名
static func createVideoItem(
    title: String,
    videoData: Data,
    metadata: [String: String] = [:]
) -> SharedItemModel?

// 使用示例
if let videoItem = SharedItemModel.createVideoItem(
    title: "演示视频",
    videoData: videoData,
    metadata: ["duration": "120", "resolution": "1920x1080"]
) {
    SharedStorageManager.shared.saveItem(videoItem)
}
```

## 存储管理器

### SharedStorageManager

单例模式，提供统一的存储管理。

#### 核心方法

```swift
// 获取单例
let storage = SharedStorageManager.shared

// 保存单个项目
storage.saveItem(item)

// 保存多个项目
storage.saveItems([item1, item2, item3])

// 加载所有项目
let items = storage.loadItems()

// 删除项目（包括关联文件）
storage.deleteItem(id: "uuid-string")

// 清空所有（包括所有文件）
storage.clearAll()
```

#### 文件操作

```swift
// 保存文件
let relativePath = storage.saveFile(data: fileData, filename: "example.jpg")

// 获取文件 URL
if let fileURL = storage.getFileURL(relativePath: "example.jpg") {
    // 使用文件
}

// 删除文件
storage.deleteFile(relativePath: "example.jpg")

// 获取共享文件目录
if let filesDir = storage.sharedFilesDirectory {
    print(filesDir.path)
}
```

## App 主应用使用

### 加载和显示

```swift
@StateObject private var manager = SharedItemsManager.shared

// 自动加载最新数据
var body: some View {
    List(manager.items) { item in
        ItemRow(item: item)
    }
    .onAppear {
        manager.refresh()  // 刷新数据
    }
}
```

### 显示文件

```swift
// 获取文件 URL
let storage = SharedStorageManager.shared
if let fileURL = storage.getFileURL(relativePath: item.filePath) {
    // 显示图片
    if let image = UIImage(contentsOfFile: fileURL.path) {
        Image(uiImage: image)
    }
    
    // 或使用 AsyncImage
    AsyncImage(url: fileURL) { image in
        image.resizable()
    } placeholder: {
        ProgressView()
    }
}
```

## 数据流程图

```
┌─────────────────────────────────────────────────────────┐
│                    Share Extension                       │
│                                                          │
│  1. 接收分享内容                                         │
│  2. 处理附件（图片/PDF/文本等）                         │
│  3. 创建 SharedItemModel                                │
│     ├── createPhotoItem()   → 保存图片文件               │
│     ├── createPDFItem()     → 保存 PDF 文件              │
│     ├── createTextItem()    → 保存文本内容               │
│     └── createURLItem()     → 保存 URL                   │
│  4. SharedStorageManager.saveItem()                    │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│              App Group Container                         │
│                                                          │
│  UserDefaults:                                          │
│  └── SharedItemsV2: [SharedItemModel]                  │
│                                                          │
│  File System:                                           │
│  └── SharedFiles/                                       │
│      ├── {uuid}.jpg                                     │
│      ├── {uuid}.pdf                                     │
│      └── {uuid}.xlsx                                    │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                      Main App                            │
│                                                          │
│  1. SharedStorageManager.loadItems()                   │
│  2. 转换为 SharedItem（UI 模型）                        │
│  3. 显示在 List 中                                      │
│  4. 点击查看详情                                        │
│     └── 读取文件或文本内容                              │
└─────────────────────────────────────────────────────────┘
```

## 完整示例：Extension 中处理图片分享

```swift
// ShareView.swift - ViewModel

func loadSharedContent(from extensionContext: NSExtensionContext?) async {
    guard let extensionContext = extensionContext else { return }
    
    for extensionItem in extensionContext.inputItems as? [NSExtensionItem] ?? [] {
        for provider in extensionItem.attachments ?? [] {
            // 处理图片
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                if let image = try? await provider.loadItem(...) as? UIImage {
                    // 转换为 JPEG 数据
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        continue
                    }
                    
                    // 准备元数据
                    let metadata: [String: String] = [
                        "width": "\(Int(image.size.width))",
                        "height": "\(Int(image.size.height))",
                        "format": "jpeg"
                    ]
                    
                    // 创建并保存项目
                    if let photoItem = SharedItemModel.createPhotoItem(
                        title: userComment.isEmpty ? "图片" : userComment,
                        imageData: imageData,
                        metadata: metadata
                    ) {
                        SharedStorageManager.shared.saveItem(photoItem)
                        print("✅ Saved photo: \(photoItem.title)")
                    }
                }
            }
        }
    }
}
```

## 完整示例：App 中显示图片

```swift
// SharedItemRow.swift

struct SharedItemRow: View {
    let item: SharedItem
    
    var body: some View {
        HStack {
            // 如果是图片类型，显示缩略图
            if item.contentType == .image {
                if let fileURL = getFileURL(from: item) {
                    AsyncImage(url: fileURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text(item.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func getFileURL(from item: SharedItem) -> URL? {
        // 从 content 中获取文件路径
        let storage = SharedStorageManager.shared
        return storage.getFileURL(relativePath: item.content)
    }
}
```

## 迁移指南

### 从旧格式迁移

主应用会自动兼容旧格式数据：

```swift
// 优先级顺序
1. 新标准格式（SharedItemModel）
2. 旧 JSON 格式（SharedItem）
3. 旧字典格式（Dictionary）
```

### 清理旧数据

```swift
// 清空旧格式数据
UserDefaults.standard.removeObject(forKey: "SharedItems")

// 使用新格式
SharedStorageManager.shared.clearAll()
```

## 最佳实践

### 1. 文件大小控制

```swift
// 图片压缩
let imageData = image.jpegData(compressionQuality: 0.8)

// 限制文件大小
let maxSize = 10 * 1024 * 1024  // 10MB
if data.count > maxSize {
    // 提示用户或压缩
}
```

### 2. 错误处理

```swift
guard let item = SharedItemModel.createPhotoItem(...) else {
    print("❌ Failed to create photo item")
    // 通知用户
    return
}
```

### 3. 性能优化

```swift
// 异步处理
Task {
    await loadAndSaveItems()
}

// 限制列表大小
let maxItems = 100
```

### 4. 元数据使用

```swift
// 记录有用信息
let metadata: [String: String] = [
    "originalName": originalFilename,
    "source": "Photos App",
    "device": UIDevice.current.model
]
```

## 总结

统一的存储格式提供了：
- ✅ 标准化的数据结构
- ✅ 文件和文本的统一管理
- ✅ 灵活的元数据扩展
- ✅ Extension 和 App 的无缝集成
- ✅ 便捷的扩展方法
- ✅ 向后兼容旧格式

---

**版本：** V2.0  
**更新时间：** 2025-10-14
