# 基于规则的分享系统重构

## 概述

重构分享扩展，实现基于 FileHandlerSettings 规则的动态文件类型匹配，而不是硬编码的类型判断。

## 主要改进

### 1. 动态规则匹配

**旧方式** - 硬编码类型判断：
```swift
if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
    // 处理PDF
} else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
    // 处理图片
}
```

**新方式** - 基于规则匹配：
```swift
// 获取文件扩展名
let fileExtension = fileURL.pathExtension.lowercased()

// 从设置中查找匹配的规则
let matched = settingsManager.rules.filter { 
    $0.ruleType == .file && 
    $0.isEnabled && 
    $0.fileExtensions.contains(fileExtension) 
}
```

### 2. 多规则支持

- 一个文件扩展名可以匹配多个处理规则
- 用户可以从匹配的规则中选择一个
- 选择的规则信息保存在元数据中

### 3. 不支持的文件类型处理

- 如果文件扩展名没有匹配任何启用的规则，拒绝分享
- 显示友好的错误提示，引导用户在设置中配置规则

### 4. URL 处理规则

- 检查是否有启用的 URL 处理规则（`ruleType == .url`）
- 只有配置了 URL 规则才能分享网页链接
- 支持将文本中的 URL 自动识别

## 新增功能

### 1. 规则选择界面

当一个文件匹配到多个规则时，显示选择界面：

```
┌─────────────────────────────────┐
│ 选择处理规则                     │
│                                  │
│ ┌─────────────────────────────┐ │
│ │ PDF转换                      │ │
│ │ https://api.example.com/pdf │ │
│ │                         ○   │ │
│ └─────────────────────────────┘ │
│                                  │
│ ┌─────────────────────────────┐ │
│ │ PDF压缩                      │ │
│ │ https://compress.com/pdf    │ │
│ │                         ✓   │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 2. 不支持文件提示

```
┌─────────────────────────────────┐
│       ⚠️                         │
│                                  │
│   不支持的文件类型               │
│                                  │
│   当前文件类型未在设置中配置     │
│   处理规则，无法分享。           │
│                                  │
│   请在应用设置中添加对应的       │
│   文件处理规则。                 │
└─────────────────────────────────┘
```

## 代码结构

### ShareViewModel 新增属性

```swift
@Published var hasUnsupportedItems: Bool = false
@Published var matchedRules: [FileHandlerRule] = []
@Published var selectedRule: FileHandlerRule?

var hasMultipleRuleMatches: Bool {
    return matchedRules.count > 1
}

var canPost: Bool {
    if hasUnsupportedItems { return false }
    if hasMultipleRuleMatches && selectedRule == nil { return false }
    return true
}
```

### 处理流程

```
1. loadSharedContent()
   ↓
2. 检测内容类型
   ├─ 文件 → handleFile()
   ├─ URL  → handleURL()
   └─ 文本 → handleText()
   ↓
3. 匹配规则
   ├─ 无匹配 → hasUnsupportedItems = true
   ├─ 单个匹配 → 自动选择
   └─ 多个匹配 → 用户选择
   ↓
4. 保存数据
   └─ saveSharedItems()
      └─ 包含规则信息的元数据
```

### 处理方法

#### handleFile(fileURL: URL)
- 提取文件扩展名
- 查找匹配的文件处理规则
- 读取文件数据
- 设置 matchedRules 和 selectedRule

#### handleURL(url: URL)
- 查找 URL 处理规则（ruleType == .url）
- 如果没有规则，标记为不支持

#### handleText(text: String)
- 检测是否为 URL 格式
- 如果是 URL，调用 handleURL()
- 否则作为纯文本保存

## 元数据结构

保存的文件会包含以下元数据：

```swift
metadata = [
    "extension": "pdf",
    "size": "1234567",
    "original_filename": "document.pdf",
    "handler_rule_id": "UUID",
    "handler_rule_type": "PDF转换",
    "handler_url": "https://api.example.com/convert/pdf"
]
```

## 使用场景

### 场景 1: 配置了多个 PDF 规则

用户设置：
- PDF转换规则：转换为图片
- PDF压缩规则：压缩文件大小

分享 PDF 文件时：
1. 检测到 .pdf 扩展名
2. 匹配到两个规则
3. 显示选择界面
4. 用户选择"PDF压缩"
5. 保存时附带规则信息

### 场景 2: 分享未配置的文件类型

用户尝试分享 .docx 文件：
1. 检测到 .docx 扩展名
2. 没有匹配的规则
3. 显示"不支持的文件类型"提示
4. 禁用"发布"按钮

### 场景 3: 分享 URL

用户分享网页链接：
1. 检测到 http:// URL
2. 查找 URL 处理规则
3. 如果有规则，允许分享
4. 如果没有规则，显示不支持提示

## 优势

1. **灵活性**：不需要修改代码就能支持新的文件类型
2. **用户控制**：用户可以在设置中配置要处理的文件类型
3. **多规则**：同一文件可以有多种处理方式
4. **清晰反馈**：明确告知用户哪些文件类型受支持
5. **可追溯**：保存规则信息，便于调试和处理

## 测试建议

### 测试 1: 单规则匹配
1. 在设置中只配置 PDF 规则
2. 分享 PDF 文件
3. 应该自动选择该规则并保存

### 测试 2: 多规则匹配
1. 在设置中配置两个 PDF 规则
2. 分享 PDF 文件
3. 应该显示规则选择界面
4. 选择后才能发布

### 测试 3: 未配置类型
1. 确保没有 .docx 规则
2. 分享 Word 文档
3. 应该显示不支持提示
4. 无法发布

### 测试 4: URL 处理
1. 配置 URL 处理规则
2. 分享网页链接
3. 应该正常保存
4. 禁用 URL 规则后，应该无法分享链接

## 后续扩展

1. **规则优先级**：支持设置规则的优先级
2. **规则预览**：在选择界面显示规则的详细信息
3. **批量分享**：支持同时分享多个文件，每个文件独立选择规则
4. **规则推荐**：根据文件大小、类型等自动推荐最合适的规则
