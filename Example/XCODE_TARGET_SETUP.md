# Xcode Target 配置说明

## 问题

ShareView.swift 中出现编译错误：
```
Cannot find type 'FileHandlerRule' in scope
Cannot find 'FileHandlerSettingsManager' in scope
```

## 原因

`FileHandlerRule` 和 `FileHandlerSettingsManager` 的定义需要在 **App** 和 **Share Extension** 两个 target 中都可用。

## 解决方案

### 方案 1: 在 Xcode 中添加文件到 Extension Target（推荐）

1. **在 Xcode 中找到文件**
   - 打开项目导航器（⌘1）
   - 找到 `Shared/FileHandlerRule.swift`

2. **检查 Target Membership**
   - 选中 `FileHandlerRule.swift` 文件
   - 打开文件检查器（⌘⌥1）
   - 在右侧面板中找到 "Target Membership" 部分

3. **添加到 Share Extension Target**
   - 勾选 Share Extension 的 target（通常名为 "Share Extension" 或 "TransAny Share Extension"）
   - 确保同时勾选了主 App target

### 方案 2: 手动将文件移动到正确位置（如果方案1不可行）

如果文件已经在项目中但无法识别，可能需要：

1. 在 Xcode 中删除 `Shared/FileHandlerRule.swift` 的引用（Delete → Remove Reference）
2. 重新添加文件到项目（右键 Shared 文件夹 → Add Files to "TransAny"...）
3. 在添加时，确保在 "Add to targets" 选项中同时选中：
   - ✅ TransAny (主应用)
   - ✅ Share Extension (分享扩展)

## 文件结构说明

### 新创建的文件

**`Shared/FileHandlerRule.swift`** - 共享类型定义
```
- HandlerRuleType (enum)
- FileHandlerRule (struct)
- FileHandlerSettingsManager (class)
```

这些类型需要在以下两个地方使用：
- **主应用**: 设置界面、文件处理
- **分享扩展**: 规则匹配、文件验证

### 修改的文件

**`App/FileHandlerSettings.swift`** - 已清理
- 移除了重复的类型定义
- 现在只包含设置界面的 SwiftUI 视图代码
- 导入 Shared 模块来使用共享类型

**`Extension/ShareView.swift`** - 使用共享类型
- 导入 FileHandlerRule 和 FileHandlerSettingsManager
- 实现基于规则的文件匹配

## 验证步骤

配置完成后，执行以下检查：

1. **清理构建**
   ```
   Product → Clean Build Folder (⇧⌘K)
   ```

2. **重新构建**
   ```
   Product → Build (⌘B)
   ```

3. **检查错误**
   - 不应该再有 "Cannot find type" 错误
   - 主应用和分享扩展都应该能成功编译

## Target Membership 检查清单

确保以下文件的 Target Membership 设置正确：

| 文件 | 主应用 | Share Extension |
|-----|-------|----------------|
| `Shared/SharedItemModel.swift` | ✅ | ✅ |
| `Shared/FileHandlerRule.swift` | ✅ | ✅ |
| `App/FileHandlerSettings.swift` | ✅ | ❌ |
| `App/MainView.swift` | ✅ | ❌ |
| `Extension/ShareView.swift` | ❌ | ✅ |

## 常见问题

### Q: 文件已添加但仍然报错？
**A**: 尝试清理派生数据
```
Xcode → Preferences → Locations → Derived Data
点击箭头打开文件夹，删除项目对应的文件夹
```

### Q: public 关键字的作用？
**A**: `FileHandlerRule.swift` 中所有类型都标记为 `public`，这是为了确保它们可以在不同的模块（target）之间共享。

### Q: 如何查看当前 Target 配置？
**A**: 
1. 在 Project Navigator 中选中项目文件（最顶层的蓝色图标）
2. 在中间面板选择对应的 Target
3. 查看 "Build Phases" → "Compile Sources" 查看包含的文件

## 下一步

配置完成后，可以：
1. 运行主应用，测试设置界面
2. 运行分享扩展，测试文件分享
3. 验证规则匹配是否正常工作
