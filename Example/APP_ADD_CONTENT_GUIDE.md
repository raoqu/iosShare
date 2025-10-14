# App 内主动添加内容功能指南

## 功能概述

除了通过 Share Extension 接收外部分享，TransAny 现在支持在应用内主动添加内容。

## UI 布局

### 底部"+"按钮
- 📍 位置：屏幕底部居中
- 🎨 样式：蓝色圆形浮动按钮
- 🔘 尺寸：56x56 点
- 💫 效果：带阴影，悬浮感

### 添加菜单
点击"+"按钮显示操作菜单：
- 📷 **拍照或选择照片** - 从相册选择图片
- 📄 **选择文件** - 从文件系统选择文档
- 📝 **输入文本** - 直接输入文本内容

## 功能详解

### 1. 选择照片

**流程：**
```
点击"+" → 选择"拍照或选择照片" → 打开照片选择器 → 选择照片 → 自动保存
```

**特性：**
- 支持多选（最多10张）
- 自动压缩（JPEG 80%质量）
- 记录元数据（尺寸、格式等）
- 异步处理，不阻塞 UI

**实现：**
```swift
// PhotoPickerView.swift
- 使用 PHPickerViewController
- 支持批量选择
- 自动加载和转换图片
```

**保存逻辑：**
```swift
func savePhotos(_ images: [UIImage]) {
    for image in images {
        // 转换为 JPEG
        let imageData = image.jpegData(compressionQuality: 0.8)
        
        // 创建元数据
        let metadata = [
            "source": "app_picker",
            "width": "\(Int(image.size.width))",
            "height": "\(Int(image.size.height))",
            "format": "jpeg"
        ]
        
        // 保存
        SharedItemModel.createPhotoItem(...)
    }
}
```

### 2. 选择文件

**流程：**
```
点击"+" → 选择"选择文件" → 打开文档选择器 → 选择文件 → 自动保存
```

**支持的文件类型：**
- 📄 PDF (.pdf)
- 📊 Excel (.xlsx, .xls)
- 📝 文本 (.txt)
- 📷 图片 (.jpg, .png)
- 🎬 视频 (.mp4, .mov)
- 📦 其他文件

**实现：**
```swift
// DocumentPickerView.swift
- 使用 UIDocumentPickerViewController
- 支持多选
- 自动识别文件类型
```

**保存逻辑：**
```swift
func saveDocuments(_ urls: [URL]) {
    for url in urls {
        // 获取文件数据
        let data = try? Data(contentsOf: url)
        
        // 根据扩展名识别类型
        switch fileExtension {
        case "pdf":
            SharedItemModel.createPDFItem(...)
        case "xlsx", "xls":
            SharedItemModel.createExcelItem(...)
        case "jpg", "jpeg", "png":
            SharedItemModel.createPhotoItem(...)
        // ...
        }
    }
}
```

### 3. 输入文本

**流程：**
```
点击"+" → 选择"输入文本" → 输入文本 → 点击"保存" → 自动保存
```

**特性：**
- 使用 Alert 对话框输入
- 自动截取标题（前30字符）
- 记录文本长度

**实现：**
```swift
.alert("输入文本", isPresented: $showingTextInput) {
    TextField("请输入内容", text: $inputText)
    Button("保存") {
        saveText(inputText)
    }
}
```

**保存逻辑：**
```swift
func saveText(_ text: String) {
    let item = SharedItemModel.createTextItem(
        title: String(text.prefix(30)),
        text: text,
        metadata: ["source": "app_input", "length": "\(text.count)"]
    )
    SharedStorageManager.shared.saveItem(item)
}
```

## 文件处理

### 图片处理
```swift
// 压缩优化
let imageData = image.jpegData(compressionQuality: 0.8)

// 记录尺寸
metadata["width"] = "\(Int(image.size.width))"
metadata["height"] = "\(Int(image.size.height))"
```

### 文档处理
```swift
// 安全访问
url.startAccessingSecurityScopedResource()
defer { url.stopAccessingSecurityScopedResource() }

// 读取数据
let data = try? Data(contentsOf: url)
```

### 类型识别
```swift
let fileExtension = url.pathExtension.lowercased()

switch fileExtension {
case "pdf":     // → PDF 类型
case "xlsx":    // → Excel 类型
case "jpg":     // → 图片类型
case "mp4":     // → 视频类型
default:        // → 通用文件
}
```

## 数据存储

### 统一存储格式
所有通过应用添加的内容都使用 `SharedItemModel` 格式：

```swift
SharedItemModel(
    id: UUID().uuidString,
    title: "标题",
    contentType: "photo/pdf/text/url/...",
    filePath: "相对路径（文件类型）",
    textContent: "文本内容（文本类型）",
    metadata: ["key": "value"],
    timestamp: Date()
)
```

### 元数据标记
```swift
// 标记来源
metadata["source"] = "app_picker"      // 应用内选择
metadata["source"] = "app_input"       // 应用内输入
metadata["source"] = "extension"       // Extension 分享

// 其他信息
metadata["filename"] = "原始文件名"
metadata["size"] = "文件大小（字节）"
metadata["extension"] = "文件扩展名"
```

### 存储位置
```
App Group Container/
├── SharedFiles/                   # 文件存储
│   ├── {uuid}.jpg                # 照片
│   ├── {uuid}.pdf                # PDF
│   └── {uuid}.xlsx               # Excel
└── Library/Preferences/
    └── SharedItemsV2             # 元数据（UserDefaults）
```

## UI 状态管理

### 状态变量
```swift
@State private var showingAddMenu = false           // 显示添加菜单
@State private var showingTextInput = false         // 显示文本输入
@State private var showingPhotoPicker = false       // 显示照片选择器
@State private var showingDocumentPicker = false    // 显示文档选择器
@State private var inputText = ""                   // 输入的文本
```

### 动画效果
```swift
withAnimation {
    manager.refresh()  // 刷新列表，带动画
}
```

## 权限配置

### Info.plist
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问您的照片库以选择要分享的照片</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要访问您的照片库以保存照片</string>
```

### 运行时权限
- 照片库访问：首次使用时自动请求
- 文件访问：无需额外权限（用户主动选择）

## 用户体验

### 反馈机制
```swift
// Console 日志
print("✅ Saved photo: \(item.title)")
print("✅ Saved document: \(filename)")
print("✅ Saved text: \(text.prefix(50))...")

// UI 反馈
withAnimation {
    manager.refresh()  // 立即显示在列表中
}
```

### 错误处理
```swift
// 数据读取失败
guard let data = try? Data(contentsOf: url) else {
    continue  // 跳过该文件
}

// 权限被拒绝
guard url.startAccessingSecurityScopedResource() else {
    continue  // 跳过该文件
}
```

### 性能优化
```swift
// 异步处理
DispatchGroup 批量处理多张照片

// 压缩优化
jpegData(compressionQuality: 0.8)

// 限制数量
config.selectionLimit = 10  // 最多10张
```

## 完整流程示例

### 添加照片完整流程

1. **用户点击"+"按钮**
   ```swift
   Button(action: { showingAddMenu = true })
   ```

2. **显示操作菜单**
   ```swift
   .confirmationDialog("添加内容", isPresented: $showingAddMenu)
   ```

3. **选择"拍照或选择照片"**
   ```swift
   Button("拍照或选择照片") {
       showingPhotoPicker = true
   }
   ```

4. **打开照片选择器**
   ```swift
   .sheet(isPresented: $showingPhotoPicker) {
       PhotoPickerView { images in
           savePhotos(images)
       }
   }
   ```

5. **处理选择的照片**
   ```swift
   func savePhotos(_ images: [UIImage]) {
       // 转换、压缩、添加元数据
       // 创建 SharedItemModel
       // 保存到 SharedStorageManager
   }
   ```

6. **刷新 UI**
   ```swift
   withAnimation {
       manager.refresh()
   }
   ```

7. **照片显示在列表中**
   - 自动滚动到顶部
   - 带动画效果
   - 显示缩略图

## 文件结构

```
Example/App/
├── MainView.swift              # 主界面（包含"+"按钮）
├── PhotoPickerView.swift       # 照片选择器
├── DocumentPickerView.swift    # 文档选择器
├── SharedItem.swift            # 数据管理
└── Info.plist                  # 权限配置

Example/Shared/
└── SharedItemModel.swift       # 统一数据模型
```

## 调试技巧

### 检查保存
```swift
// 查看 Console 输出
✅ Saved photo: 照片 10/14/2025, 5:06 PM
✅ Saved document: example.pdf
✅ Saved text: 这是一段测试文本...
```

### 验证文件
```bash
# 查看保存的文件
cd [App Group Container]/SharedFiles
ls -la

# 应该看到
550e8400-e29b-41d4-a716-446655440000.jpg
660e8400-e29b-41d4-a716-446655440001.pdf
```

### 检查元数据
```swift
let storage = SharedStorageManager.shared
let items = storage.loadItems()
print("Total items: \(items.count)")

for item in items {
    print("- \(item.contentType): \(item.title)")
    print("  Metadata: \(item.metadata)")
}
```

## 总结

应用内添加功能提供了完整的内容管理能力：

- ✅ 照片选择（相册/相机）
- ✅ 文件选择（所有类型）
- ✅ 文本输入（快速记录）
- ✅ 统一存储（标准格式）
- ✅ 实时更新（自动刷新）
- ✅ 元数据记录（来源追踪）
- ✅ 权限管理（自动请求）
- ✅ 错误处理（优雅降级）

用户现在可以：
1. 通过 Extension 接收外部分享
2. 通过"+"按钮主动添加内容
3. 统一管理所有分享内容

---

**版本：** V1.0  
**更新时间：** 2025-10-14
