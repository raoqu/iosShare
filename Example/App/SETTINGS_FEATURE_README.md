# 设置功能说明

## 功能概述

为 TransAny 应用添加了完整的设置功能，支持配置不同文件类型的远程处理规则，包括：
- 自定义类型名称
- 支持多个文件扩展名
- 配置文件参数名
- 添加自定义参数（键值对）
- 灵活的远程处理 URL 配置

## 新增文件

### 1. `FileHandlerSettings.swift`
**位置**: `Example/App/FileHandlerSettings.swift`

**功能**:
- `FileHandlerRule`: 文件处理规则数据模型
  - `typeName`: 类型名称（如 "EXCEL", "PDF"）
  - `fileExtensions`: 文件扩展名数组（如 ["xls", "xlsx"]）
  - `remoteURL`: 远程处理 URL
  - `fileParameterName`: 文件上传参数名（默认 "file"）
  - `customParameters`: 自定义参数字典
  - `isEnabled`: 是否启用该规则

- `FileHandlerSettingsManager`: 设置管理器
  - 保存/加载规则到 UserDefaults（App Group）
  - 根据扩展名查询处理规则
  - 支持多扩展名匹配
  - 提供默认规则和重置功能

### 2. `SettingsView.swift`
**位置**: `Example/App/SettingsView.swift`

**功能**:
- `SettingsView`: 主设置界面
  - 显示所有文件处理规则列表
  - 支持添加/编辑/删除规则
  - 重置为默认设置

- `FileHandlerRuleRow`: 规则列表项
  - 显示扩展名和 URL
  - 内联启用/禁用开关

- `FileHandlerRuleEditView`: 规则编辑界面
  - 输入扩展名和 URL
  - 实时预览
  - 验证输入合法性

## 修改的文件

### `MainView.swift`

**新增内容**:

1. **状态变量**:
   ```swift
   @State private var showingSettings = false
   ```

2. **右上角菜单**:
   - 添加"设置"菜单项
   - 点击打开设置页面

3. **文件处理集成**:
   - 在 `saveDocuments()` 中检查处理规则
   - 如果文件扩展名有启用的规则，发送到远程 URL
   - 添加处理状态到文件元数据

4. **远程处理方法**:
   ```swift
   private func sendToRemoteHandler(url: String, filename: String, fileData: Data, fileExtension: String) async
   ```
   - 使用 multipart/form-data 格式上传文件
   - 记录详细的处理日志
   - 异步处理，不阻塞 UI

## 使用方法

### 1. 访问设置

在主界面有内容时，点击右上角的 `⋯` 菜单按钮，选择"设置"。

### 2. 添加规则

1. 在设置页面点击"添加规则"
2. 填写规则信息：
   - **类型**：输入类型名称（如 `EXCEL`）
   - **扩展名**：逗号分隔的扩展名（如 `xls,xlsx`）
   - **处理 URL**：远程服务器地址（如 `https://api.example.com/convert/excel`）
   - **文件参数名**：上传文件时使用的参数名（默认 `file`）
   - **自定义参数**：点击"添加参数"可添加额外的键值对
   - **启用规则**：开关控制是否启用
3. 点击"保存"

### 3. 编辑规则

点击规则列表中的任意项即可编辑。

### 4. 启用/禁用规则

使用规则右侧的开关即可快速启用或禁用，无需进入编辑页面。

### 5. 删除规则

在规则上左滑，点击"删除"。

## 工作流程

当用户通过文档选择器选择文件时：

```
1. 读取文件数据
2. 获取文件扩展名
3. 查询是否有启用的处理规则
   ├─ 有规则: 
   │   ├─ 发送文件到远程 URL（异步）
   │   ├─ 在元数据中记录 handler_url 和 handler_status
   │   └─ 保存文件到本地
   └─ 无规则:
       └─ 直接保存文件到本地
4. 刷新界面显示
```

## 远程处理 API 格式

### 文件上传类型（ruleType: .file）

发送到远程服务器的请求格式：

**Method**: POST  
**Content-Type**: multipart/form-data

**标准字段**:
- `{fileParameterName}`: 文件二进制数据（参数名由规则配置，默认 `file`）
- `extension`: 文件扩展名字符串
- `{customKey}`: 自定义参数（可配置多个键值对）

**示例 1 - Excel 转换（带自定义参数）**:
```http
POST https://api.example.com/convert/excel
Content-Type: multipart/form-data; boundary=Boundary-...

--Boundary-...
Content-Disposition: form-data; name="file"; filename="data.xlsx"
Content-Type: application/octet-stream

[二进制文件数据]
--Boundary-...
Content-Disposition: form-data; name="extension"

xlsx
--Boundary-...
Content-Disposition: form-data; name="sheet"

0
--Boundary-...
Content-Disposition: form-data; name="format"

csv
--Boundary-...--
```

**示例 2 - PDF 转换（自定义文件参数名）**:
```http
POST https://api.example.com/convert/pdf
Content-Type: multipart/form-data; boundary=Boundary-...

--Boundary-...
Content-Disposition: form-data; name="document"; filename="report.pdf"
Content-Type: application/octet-stream

[二进制文件数据]
--Boundary-...
Content-Disposition: form-data; name="extension"

pdf
--Boundary-...
Content-Disposition: form-data; name="quality"

high
--Boundary-...--
```

### URL 处理类型（ruleType: .url）

发送到远程服务器的请求格式：

**Method**: POST  
**Content-Type**: application/x-www-form-urlencoded

**标准字段**:
- `url`: URL 字符串（URL 编码）
- `{customKey}`: 自定义参数（可配置多个键值对）

**示例 - URL 短链接服务**:
```http
POST https://api.example.com/process/url
Content-Type: application/x-www-form-urlencoded

url=https%3A%2F%2Fgithub.com%2Ftopics%2Fswiftui&action=shorten
```

**特点**:
- 不上传文件，只发送 URL 字符串
- 使用 `application/x-www-form-urlencoded` 格式
- 自动对参数进行 URL 编码
- 适用于短链接生成、URL 分析、书签服务等场景

## 日志输出

启用规则后，文件和URL处理会输出详细日志：

### 文件处理日志：
```
📄 Processing file: data.xlsx
🌐 Found handler rule for .xlsx: [EXCEL] https://api.example.com/convert/excel
🚀 Sending data.xlsx to remote handler: [EXCEL] https://api.example.com/convert/excel
📤 Custom parameter: sheet = 0
📤 Custom parameter: format = csv
✅ Successfully sent data.xlsx to remote handler
📥 Response: {"status": "success", "id": "12345", "download_url": "..."}
```

### URL 处理日志：
```
🌐 Found URL handler rule: [URL] https://api.example.com/process/url
🚀 Sending URL to remote handler: [URL] https://api.example.com/process/url
🔗 URL to process: https://github.com/topics/swiftui
📤 Custom parameter: action = shorten
✅ Successfully sent URL to remote handler
📥 Response: {"short_url": "https://short.ly/abc123", "original": "https://github.com/topics/swiftui"}
```

## 默认规则

首次启动时会创建以下默认规则（禁用状态）：

### 1. URL
- **类型**: URL
- **规则类型**: URL处理（不上传文件）
- **扩展名**: 无（适用于所有URL）
- **URL**: `https://api.example.com/process/url`
- **文件参数**: 无（URL类型不使用文件参数）
- **自定义参数**: `action: shorten`
- **说明**: 当用户输入URL文本时，自动发送到远程处理器，可用于短链接生成、URL分析等

### 2. PDF
- **类型**: PDF
- **规则类型**: 文件上传
- **扩展名**: pdf
- **URL**: `https://api.example.com/convert/pdf`
- **文件参数**: file
- **自定义参数**: `format: pdf`

### 3. WORD
- **类型**: WORD
- **规则类型**: 文件上传
- **扩展名**: doc, docx
- **URL**: `https://api.example.com/convert/word`
- **文件参数**: file
- **自定义参数**: `target: pdf`

### 4. EXCEL
- **类型**: EXCEL
- **规则类型**: 文件上传
- **扩展名**: xls, xlsx
- **URL**: `https://api.example.com/convert/excel`
- **文件参数**: file
- **自定义参数**: `sheet: 0`

用户可以修改这些规则或添加新规则。

## 注意事项

1. **Xcode 项目配置**：需要将新文件添加到 Xcode 项目的 App target
2. **网络请求**：远程处理是异步的，不会阻塞文件保存
3. **数据存储**：规则保存在 App Group 的 UserDefaults 中，可以跨扩展访问
4. **URL 验证**：编辑界面会验证 URL 必须以 `http://` 或 `https://` 开头

## 添加文件到 Xcode 项目

在 Xcode 中：

1. 右键点击 `Example/App` 文件夹
2. 选择 "Add Files to 'TransAny'..."
3. 选中以下文件：
   - `FileHandlerSettings.swift`
   - `SettingsView.swift`
4. 确保勾选 **App** target（不要勾选 Extension）
5. 点击 "Add"

或者运行项目时 Xcode 会提示添加缺失的文件。
