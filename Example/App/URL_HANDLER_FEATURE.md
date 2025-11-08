# URL 处理功能说明

## 概述

为 TransAny 应用添加了 URL 处理规则支持。与文件处理规则不同，URL 处理规则不需要上传文件，只发送 URL 字符串到远程服务器。

## 主要特性

### 1. 规则类型区分

- **文件上传** (`.file`): 根据文件扩展名匹配，上传文件到远程服务器
- **URL 处理** (`.url`): 处理所有 URL 类型内容，只发送 URL 字符串

### 2. 自动 URL 检测

当用户输入文本时，应用会自动检测是否为 URL（以 `http://` 或 `https://` 开头），如果是 URL 且有启用的 URL 处理规则，则自动发送到远程服务器。

### 3. 请求格式差异

**文件上传类型**:
- Content-Type: `multipart/form-data`
- 包含文件二进制数据、扩展名、自定义参数

**URL 处理类型**:
- Content-Type: `application/x-www-form-urlencoded`
- 只包含 URL 字符串和自定义参数
- 参数自动进行 URL 编码

## 使用场景

- 短链接生成服务
- URL 书签服务
- 网页快照服务
- URL 分析和监控
- 链接有效性检查

## 代码修改说明

### 1. FileHandlerSettings.swift

#### 新增枚举
```swift
enum HandlerRuleType: String, Codable {
    case file       // 需要上传文件
    case url        // 只发送 URL，不上传文件
}
```

#### FileHandlerRule 添加字段
```swift
var ruleType: HandlerRuleType   // 规则类型
```

#### 新增方法
```swift
func getURLRule() -> FileHandlerRule?
```

#### 默认规则
添加了 URL 处理的默认规则示例：
```swift
FileHandlerRule(
    typeName: "URL",
    ruleType: .url,
    fileExtensions: [],
    remoteURL: "https://api.example.com/process/url",
    fileParameterName: "",
    customParameters: ["action": "shorten"],
    isEnabled: false
)
```

### 2. MainView.swift

#### saveText 方法更新
- 自动检测输入文本是否为 URL
- 如果是 URL 且有启用的 URL 处理规则，调用 `sendURLToRemoteHandler`
- 在元数据中记录处理状态

#### 新增方法
```swift
private func sendURLToRemoteHandler(rule: FileHandlerRule, urlString: String) async
```

发送请求格式：
```
POST {remoteURL}
Content-Type: application/x-www-form-urlencoded

url={encodedURL}&{customKey}={customValue}
```

### 3. SettingsView.swift

#### 编辑界面更新
- 添加规则类型选择器（Segmented Picker）
- 根据规则类型动态显示/隐藏相关字段：
  - URL 类型：隐藏"扩展名"和"文件参数名"字段
  - 文件类型：显示所有字段
- 更新验证逻辑：URL 类型不需要扩展名

#### 列表显示更新
- 显示规则类型徽章（"URL" 或 "文件"）
- URL 类型显示"适用于所有 URL"

## API 请求示例

### URL 处理请求

```http
POST https://api.example.com/process/url
Content-Type: application/x-www-form-urlencoded

url=https%3A%2F%2Fgithub.com%2Ftopics%2Fswiftui&action=shorten
```

### 日志输出

```
🌐 Found URL handler rule: [URL] https://api.example.com/process/url
🚀 Sending URL to remote handler: [URL] https://api.example.com/process/url
🔗 URL to process: https://github.com/topics/swiftui
📤 Custom parameter: action = shorten
✅ Successfully sent URL to remote handler
📥 Response: {"short_url": "https://short.ly/abc123", ...}
```

## 配置步骤

1. 打开应用设置
2. 点击"添加规则"
3. 选择"URL 处理"类型
4. 填写：
   - 类型名称：如 "URL"
   - 处理 URL：远程服务器地址
   - 自定义参数：可选的键值对
5. 启用规则
6. 保存

## 测试方法

1. 在设置中启用 URL 处理规则
2. 在主界面点击"+"按钮
3. 选择"输入文本"
4. 输入一个 URL（如 `https://github.com`）
5. 查看控制台日志，确认 URL 被发送到远程服务器

## 注意事项

1. **URL 检测**: 目前只检测以 `http://` 或 `https://` 开头的文本
2. **唯一规则**: 同时只能启用一个 URL 处理规则
3. **文件参数**: URL 类型规则不使用文件参数名字段
4. **扩展名**: URL 类型规则不需要配置扩展名
5. **编码**: URL 和参数会自动进行 URL 编码

## 向后兼容

- 现有的文件处理规则会自动设置为 `.file` 类型
- 旧版本保存的规则在加载时会自动添加 `ruleType` 字段（默认为 `.file`）
