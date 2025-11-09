# 文件显示修复说明

## 修复的问题

### 1. 详情页显示 "file://..." 路径文本
**原因**: `SharedItem` 的 `content` 字段被设置为文件的完整路径

**修复**:
- 修改 `SharedItem.swift` 中的加载逻辑
- 对于文件类型，`content` 现在显示文件名而不是路径
- 对于文本/URL类型，`content` 显示实际内容

```swift
// 生成显示用的内容
let content: String
if let textContent = model.textContent, !textContent.isEmpty {
    // 有文本内容（文本或URL类型）
    content = textContent
} else if let filePath = model.filePath {
    // 文件类型，显示文件名（不带路径）
    let fileName = (filePath as NSString).lastPathComponent
    content = fileName
} else {
    content = ""
}
```

### 2. 文件标题包含扩展名
**原因**: 保存文件时使用完整文件名作为标题

**修复位置**:

#### ShareView.swift (分享扩展)
- 从 `NSItemProvider` 获取原始文件URL
- 使用 `deletingPathExtension()` 去除扩展名
- 标题示例: "report.pdf" → "report"

```swift
let nameWithoutExt = fileURL.deletingPathExtension().lastPathComponent
tempItem.title = nameWithoutExt.isEmpty ? "PDF" : nameWithoutExt
```

#### MainView.swift (主应用文件选择器)
- 处理文件选择器返回的URL
- 去除扩展名后作为标题
- 保留完整文件名在元数据中

```swift
let fileNameWithoutExt = url.deletingPathExtension().lastPathComponent
let displayTitle = fileNameWithoutExt.isEmpty ? filename : fileNameWithoutExt
```

### 3. 详情页未显示文件专用组件
**原因**: 布局逻辑判断问题

**修复**:
- 创建专用的 `fileContentView` 视图
- 添加 `hasFile` 计算属性，准确判断是否为文件类型
- 文件类型显示专用卡片，文本类型显示文本内容

```swift
// 内容区域
if hasFile {
    // 文件类型：显示文件卡片
    fileContentView
} else {
    // 文本/URL类型：显示文本内容
    VStack(alignment: .leading, spacing: 8) {
        Text("内容")
        Text(item.content)
    }
}
```

## 文件专用组件功能

### 显示内容
1. **文件类型图标** - 60x60 圆角图标
2. **文件名** - 不带扩展名，支持多行
3. **文件大小** - 自动格式化（如 "2.5 MB"）
4. **类型标签** - 显示文件类型（PDF、图片等）
5. **分享按钮** - "分享或打开" 操作按钮

### 特殊功能
- **图片预览**: 图片类型自动显示缩略图（最高200px）
- **一键分享**: 通过 UIActivityViewController 分享文件
- **系统集成**: 支持用其他应用打开、AirDrop等

## 测试要点

### 通过分享扩展添加文件
1. 在其他应用中分享 PDF/图片到 TransAny
2. 检查标题是否为文件名（不带扩展名）
3. 打开详情页，应显示文件卡片而不是路径文本
4. 点击"分享或打开"应弹出系统分享面板

### 通过主应用添加文件
1. 在主应用点击"+"选择文件
2. 检查标题是否为文件名（不带扩展名）
3. 详情页应显示文件卡片
4. 图片应显示缩略图预览

### 文本和URL类型
1. 添加纯文本或URL
2. 详情页应显示文本内容，不显示文件卡片
3. URL应显示完整链接

## 修改的文件

1. **SharedItem.swift**
   - 修改 `loadItems()` 中的 content 生成逻辑

2. **ShareView.swift**
   - 改进图片和PDF的文件名获取逻辑
   - 使用 `deletingPathExtension()` 去除扩展名

3. **MainView.swift**
   - `saveDocuments()` 使用不带扩展名的文件名
   - 添加 `fileContentView` 文件卡片组件
   - 添加 `hasFile` 和 `fileURL` 计算属性
   - 添加 `fileInfo` 获取文件信息
   - 改进详情页布局逻辑

## 效果对比

### 修复前
```
标题: document.pdf
内容: file:///var/mobile/.../document.pdf
```

### 修复后
```
标题: document
内容: [文件卡片组件]
  [图标] document.pdf
         1.2 MB
         [PDF]
  ──────────────
  [↑] 分享或打开 [>]
```
