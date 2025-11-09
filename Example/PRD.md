# TransAny 产品需求文档（基于现有实现）

## 1. 产品概述
TransAny 由一个主应用与 Share Extension 组成，面向“在任意 App 中快速收集并转发内容到统一收件箱”的场景。产品负责：
- 接收来自系统分享面板的文本、URL 与多种文件（照片、PDF、Office、视频等），并用 App Group 存储结构统一落地。
- 在主应用中以列表形式浏览、搜索、编辑和再次分享这些内容，同时允许用户主动创建内容（文字输入、照片/文件选取）。
- 基于可配置的“远程处理规则”把不同类型的内容 POST 到第三方服务，实现自动化分发或解析。
- 通过 URL Scheme（`transany://`）在扩展完成后唤起主应用，使用户无缝查看刚转存的素材。

## 2. 角色与使用场景
- **采集者（iOS 终端用户）**：在 Safari/微信/文件等 App 中调用 Share Extension 把资料投递到 TransAny；或在主应用内手动添加灵感与素材。
- **运营/分析人员**：在主应用中浏览列表、查看详情、补充备注、再次分享或删除，确保素材被整理干净。
- **开发/集成人员**：通过“设置-文件处理规则”配置第三方 API，实现自动上传 Excel、PDF，或把 URL 直接提交给服务端机器人。

典型场景：
1. 用户在 Safari 选中文章 -> Share Extension 识别为 URL -> 根据 URL 规则写入共享存储并调用远程处理器。
2. 用户在 Files App 选取 Excel -> 扩展检测文件扩展名 -> 询问匹配的规则 -> 上传文件并持久化记录。
3. 用户回到主应用，看到新的条目，进入详情页查看文件信息、二次编辑文本或一键清空无用内容。

## 3. 核心流程
### 3.1 Share Extension 采集流程
1. `ShareView` 读取 `extensionContext.inputItems`，依次解析 URL、纯文本、`UTType.fileURL`。
2. `ShareViewModel` 为每个项目生成 `ShareItemModel`：
   - 读取文件数据并附带 metadata（扩展名、文件大小、原始文件名）。
   - 依据 `FileHandlerSettingsManager` 中启用的规则匹配处理类型，若命中多个规则，则要求用户手动选择。
   - 文本+URL 组合时自动合并，确保标题可读。
3. 发布时：
   - 依据所选规则把内容序列化为 `SharedItemModel` 并写入共享目录（文件写入 `SharedFiles`，元数据写入 `UserDefaults(suiteName: group.cc.raoqu.transany)`）。
   - 触发 `transany://` 打开宿主 App；`extensionContext.completeRequest` 结束流程。

### 3.2 主应用内容体验
1. `MainView` 在 `onAppear` 和 `willEnterForeground` 时通过 `SharedItemsManager.refresh()` 同步存量，优先读取新标准格式并兼容旧 JSON/字典格式。
2. 列表使用 `SharedItemRow` 呈现图标、标题、摘要、类型标签与时间，并提供滑动删除。
3. 中央 “+” 浮动按钮打开添加菜单：
   - **文本输入**：`TextInputView` 收集标题与正文，必要时识别 URL 并触发远程处理；保存为 `SharedItemModel`。
   - **照片选择**：`PhotoPickerView` (PHPicker) 支持多选 JPEG，落地后刷新列表。
   - **文件选择**：`DocumentPickerView` (UIDocumentPicker) 允许多种 UTType，自动处理安全域、复制临时文件并根据扩展名分流。
4. 列表页提供菜单：进入 `SettingsView`、清空所有记录、生成测试数据。
5. `ItemDetailView` 允许查看/编辑文本内容、展示文件卡片（含大小、文件名、预览）、分享文件到其他 App。

### 3.3 远程处理规则
- 规则由 `FileHandlerRule` 描述，属性包含类型名、处理模式（文件/URL）、适用扩展名、远程 URL、文件参数名与自定义参数。
- `SettingsView` 支持增删改、启用开关、参数编辑、规则类型切换，并持久化到 App Group。
- 主应用：当手动添加文本或导入文件时，如果匹配到启用规则，会立即通过 `sendToRemoteHandler`（multipart/form-data）或 `sendURLToRemoteHandler`（x-www-form-urlencoded）向第三方发起 POST，记录 handler 元数据并把状态标记为 `pending`。
- Share Extension：保存前确保至少存在一条可用规则，否则标记 `hasUnsupportedItems` 给出提示。

## 4. 功能需求拆解
### 4.1 Share Extension
- 支持多附件解析，自动过滤/合并文本与 URL。
- 在检测到多个文件规则时，提供规则选择区块。
- 针对未配置规则的文件展示不可分享提示。
- 允许用户在扩展内自定义标题。
- 保存后调用 URL Scheme 唤醒主应用。

### 4.2 主应用
- 列表视图：展示全部记录、滑动删除、空态说明与示例按钮。
- 全局菜单：设置入口、批量清空、调试添加示例。
- 添加入口：文本输入、照片选取、文件选取，全部写入统一模型。
- 详情页：标题/内容编辑、文件信息展示、再次分享文件、URL/文本复制。
- Settings：文件处理规则的 CRUD、启用开关与自定义参数维护。

### 4.3 数据与同步
- 数据存储：`SharedItemModel` JSON 数组存至 `SharedItemsV2`，最多 100 条，文件实际存放在共享容器 `SharedFiles` 目录。
- 兼容历史格式：`SharedItemsManager` 会在读取时 fallback 到旧 JSON 或字典格式，保证迭代兼容。
- 元数据：来源（app_input/app_picker/extension）、文件尺寸、 handler 状态均以字典形式保存便于后续拓展。

### 4.4 非功能需求
- SwiftUI + UIKit 混编；Share Extension 与主 App 共用 App Group，确保线程安全（`@unchecked Sendable` + 缓存 `UserDefaults`).
- 文件操作需处理 security-scoped resource，并在完成后释放。
- 追加的网络调用默认假设在主 App 中执行（Share Extension 端当前版本仅存储，不主动上传）。

## 5. 数据模型与存储
- `SharedItemModel`: `{id(UUID String), title, contentType(photo/pdf/excel/text/url/video/file), filePath?, textContent?, metadata[String:String], timestamp}`。
- `SharedStorageManager`：
  - 负责 SharedFiles 目录创建/写入/删除，提供 `saveFile`, `getFileURL`, `deleteFile`, `clearAll`。
  - 持有缓存的 `UserDefaults(suiteName: group.cc.raoqu.transany)`，限制列表长度 100。
- `SharedItem` (App 端 UI 模型)：`SharedItemModel` 的可视化投影，保留 `SharedContentType`、格式化时间等属性，兼容旧格式。
- `ShareItemModel` (Extension 临时模型)：扩展态下用于解析输入、收集 metadata 的结构，最终转换成 `SharedItemModel`。

## 6. 远程处理与外部依赖
- 规则类型：
  - `file`：使用 multipart/form-data 上传二进制文件，并携带扩展名、规则自定义参数。
  - `url`：使用 application/x-www-form-urlencoded，仅提交 URL 字符串及参数。
- 自定义参数：键值对配置，在上传时逐条写入；UI 允许动态新增/删除。
- 依赖：
  - `PhotosUI`, `UniformTypeIdentifiers`, `XExtensionItem`（用于示例 `ContentViewController`）。
  - URL Scheme `transany://`，用于扩展完成后唤起 App。

## 7. UI/UX 关键点
- 空态：图标 + 说明 + “添加测试内容” 按钮，帮助首次体验。
- 浮动按钮：居中圆形 “+” 覆盖底部安全区。
- 详情页：文件卡片含图标、名称、大小、内容类型标签，并提供分享按钮。
- 设置页：列表展示规则，右滑删除 + Toggle 启停 + Row 点击进入编辑；支持“重置为默认设置”。
- Share Extension：列表预览所有将要导入的项目，处理中的进度提示，以及不支持类型时的强提示。

## 8. 源代码文件说明
| 文件路径 | 说明 |
| --- | --- |
| `Shared/SharedItemModel.swift` | 定义跨 App/Extension 的标准存储模型与 `SharedStorageManager`，负责 App Group 数据/文件的读写、删除、限流以及 `SharedItemModel` 的便捷构造函数与展示辅助属性。 |
| `Shared/FileHandlerRule.swift` | App 与 Extension 共用的规则实体与 `FileHandlerSettingsManager` 实现，提供规则增删改、默认值生成、查找 file/URL 规则等功能。 |
| `App/MainView.swift` | SwiftUI 主界面，包含列表、空态、浮动新增按钮、菜单、添加/编辑/删除/清空逻辑，以及 `ItemDetailView`、`TextInputView`、`ShareSheet`、远程处理（`sendToRemoteHandler`、`sendURLToRemoteHandler`）等核心交互。 |
| `App/SharedItem.swift` | 声明 UI 层使用的 `SharedItem`、`SharedContentType`，以及 `SharedItemsManager`（负责从 App Group 读取/写入、兼容旧格式、同步 UI 列表、清空数据等）。 |
| `App/SharedItemRow.swift` | 列表行组件，渲染类型图标、标题、副文案、标签与时间，支持示例 Preview。 |
| `App/PhotoPickerView.swift` | 使用 `PHPickerViewController` 的 `UIViewControllerRepresentable` 封装，负责多选照片并回调 `UIImage` 数组。 |
| `App/DocumentPickerView.swift` | `UIDocumentPickerViewController` 封装，支持多类型、多选文件，并在 picker 关闭后回传文件 URL。 |
| `App/SettingsView.swift` | 规则设置界面，展示/删除/启停规则，提供新增与编辑弹窗（`FileHandlerRuleEditView`），并在编辑器内维护类型、扩展名、URL、自定义参数等字段。 |
| `App/FileHandlerSettings.swift` | App 侧对 `AppGroupConfig` 的占位描述，标注 `FileHandlerRule` 已迁移至 Shared 模块，方便 Objective-C 桥接。 |
| `App/ContentItem.swift` | 示例 `ContentItem` 与 `ContentItemType` 定义，用于 `ContentViewController` 演示如何把不同类型内容包装成可分享条目。 |
| `App/ContentItemCell.swift` | UIKit `UITableViewCell` 自定义类，负责在示例控制器中以图标+标题+副标题样式展示 `ContentItem`。 |
| `App/ContentViewController.swift` | UIKit 示例控制器，加载若干 `ContentItem`，并使用 `XExtensionItemSource` 将选中内容通过系统分享面板导出，展示如何生成富含 metadata 的分享项。 |
| `App/SceneDelegateHelper.swift` | 为 Objective-C `SceneDelegate` 提供 `UIHostingController` 包装器，设置主视图背景/安全区，确保 SwiftUI `MainView` 能嵌入 UIKit 生命周期。 |
| `SceneDelegateHelper.swift` | 根目录下的简化版本 SceneDelegate 桥接工具，为需要最小依赖的目标提供 `MainView` 宿主（无额外外观配置）。 |
| `Extension/ShareView.swift` | Share Extension 主视图及其 ViewModel，负责解析 `NSExtensionContext`、匹配规则、处理文件/URL/文本、展示预览/规则选择/错误提示，并最终保存数据与调用 URL Scheme。 |
| `Extension/ShareViewController.swift` | Share Extension UIKit 宿主，把 `ShareView` 注入 `UIHostingController` 并填充全屏。 |
| `Extension/FileHandlerRule.swift` | Extension 侧拷贝的规则实现，额外暴露 `resetToDefaults()` 以便在 Extension 沙箱内独立工作。 |

## 9. 后续优化建议
1. **规则共享去重**：当前 App 与 Extension 分别持有一份 `FileHandlerSettingsManager`，可考虑通过 Swift Package 共享，以避免行为漂移。
2. **搜索/过滤**：主列表尚未提供搜索与类型过滤，可在 `MainView` 顶部追加筛选器。
3. **状态同步**：远程处理的结果目前只在 metadata 中标记 `pending`，缺乏轮询/回写机制，后续可新增处理状态刷新。
4. **多语言**：UI/文案主要为中文，可根据目标用户添加本地化。 
