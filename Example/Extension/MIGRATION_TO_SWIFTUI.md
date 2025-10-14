# Share Extension 迁移到 SwiftUI 指南

## 概述

已将 Share Extension 从 Objective-C + SLComposeServiceViewController 迁移到纯 SwiftUI 实现。

## 新架构优势

### 1. **现代化的 Swift/SwiftUI**
- 类型安全
- 声明式 UI
- 更好的可维护性

### 2. **完全自定义的 UI**
- 不再受限于 `SLComposeServiceViewController` 的固定样式
- 可以完全控制 UI 布局和交互
- 更好的用户体验

### 3. **异步处理**
- 使用 Swift 现代并发（async/await）
- 更清晰的异步代码结构
- 自动的错误处理

## 文件结构

### 新文件
```
Extension/
├── ShareView.swift              # SwiftUI 主视图 + ViewModel
├── ShareViewController.swift    # UIViewController 桥接层
└── Info.plist                   # 配置文件（需要更新）
```

### 旧文件（已备份）
```
Extension/
├── ShareViewController.m.old    # 旧的 ObjC 实现
└── ShareViewController.h.old    # 旧的 ObjC 头文件
```

## 配置更新

### 1. Info.plist 修改

需要将 Extension 的主类从 Objective-C 改为 Swift：

**之前（Objective-C）：**
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPrincipalClass</key>
    <string>ShareViewController</string>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
</dict>
```

**之后（SwiftUI）：**
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
    <!-- 移除 MainInterface.storyboard 引用 -->
</dict>
```

### 2. Xcode Target 配置

#### Extension Target 设置：
1. **Build Settings** → **Swift Language Version**: Swift 5 或更高
2. **Build Phases** → 确保 SwiftUI 相关文件已添加
3. **General** → **Deployment Target**: iOS 15.0 或更高

#### 文件成员关系：
- ✅ `ShareView.swift` → Extension target
- ✅ `ShareViewController.swift` → Extension target
- ❌ `ShareViewController.m.old` → 从 target 移除
- ❌ `ShareViewController.h.old` → 从 target 移除
- ❌ `MainInterface.storyboard` → 不再需要（可选择移除）

## 新功能特性

### 1. 实时预览
```swift
// 自动显示分享内容的预览
ForEach(viewModel.items) { item in
    // 显示图标、类型、内容预览
}
```

### 2. 处理状态指示
```swift
if viewModel.isProcessing {
    ProgressView("正在处理...")
}
```

### 3. 现代化输入体验
```swift
TextField("输入描述（可选）", text: $viewModel.userComment)
    .textFieldStyle(RoundedBorderTextFieldStyle())
```

### 4. 类型安全的数据模型
```swift
struct ShareItemModel: Identifiable {
    let id = UUID()
    var type: String
    var content: String
    var title: String
}
```

## 代码对比

### 获取用户输入

**之前（Objective-C）：**
```objc
NSString *userComment = self.contentText;
```

**之后（SwiftUI）：**
```swift
@Published var userComment: String = ""
// 直接绑定到 TextField
TextField("输入描述", text: $viewModel.userComment)
```

### 处理附件

**之前（Objective-C + 回调）：**
```objc
[provider loadItemForTypeIdentifier:kUTTypeImage 
                            options:nil 
                  completionHandler:^(UIImage *image, NSError *error) {
    // 处理回调
}];
```

**之后（Swift async/await）：**
```swift
if let image = try? await provider.loadItem(
    forTypeIdentifier: UTType.image.identifier, 
    options: nil
) as? UIImage {
    // 直接处理
}
```

### 保存数据

**之前（Objective-C）：**
```objc
NSUserDefaults *defaults = [[NSUserDefaults alloc] 
    initWithSuiteName:@"group.cc.raoqu.transany"];
[defaults setObject:allItems forKey:@"SharedItems"];
```

**之后（Swift）：**
```swift
guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
defaults.set(existingItems, forKey: sharedItemsKey)
```

## 测试清单

- [ ] Extension 能在分享菜单中显示
- [ ] 可以分享图片并显示预览
- [ ] 可以分享网页链接并显示 URL
- [ ] 可以分享文本内容
- [ ] 用户输入的描述正确保存
- [ ] "取消"按钮正常工作
- [ ] "发布"按钮正常工作
- [ ] 数据保存到 App Group
- [ ] 主应用能正确加载分享的数据
- [ ] 主应用自动刷新

## 迁移步骤

### 1. 在 Xcode 中更新文件
1. 打开项目
2. 在 Extension target 中：
   - 添加 `ShareView.swift`
   - 添加 `ShareViewController.swift`
   - 移除 `ShareViewController.m` 和 `.h`

### 2. 更新 Info.plist
```xml
<key>NSExtensionPrincipalClass</key>
<string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
```

移除：
```xml
<key>NSExtensionMainStoryboard</key>
<string>MainInterface</string>
```

### 3. 配置 Bridging Header（如果需要）
如果 Extension target 还有其他 Objective-C 代码，确保有正确的 bridging header。

### 4. Clean Build
- Clean Build Folder（Shift + Cmd + K）
- 重新编译

### 5. 测试
完整测试所有分享场景

## 回滚方案

如果遇到问题需要回滚：

```bash
cd Example/Extension
mv ShareViewController.m.old ShareViewController.m
mv ShareViewController.h.old ShareViewController.h
rm ShareView.swift
rm ShareViewController.swift
```

然后在 Xcode 中：
1. 恢复 Info.plist 配置
2. 重新添加旧文件到 target
3. Clean Build

## 性能优化建议

### 1. 图片处理
```swift
// 生成缩略图而不是保存完整图片
let thumbnailSize = CGSize(width: 200, height: 200)
let thumbnail = image.preparingThumbnail(of: thumbnailSize)
```

### 2. 大文件处理
```swift
// 使用共享容器目录保存大文件
if let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupIdentifier
) {
    let fileURL = containerURL.appendingPathComponent("image.jpg")
    // 保存文件
}
```

### 3. 数据限制
```swift
// 限制保存的项目数量
let maxItems = 100
if existingItems.count >= maxItems {
    existingItems.removeLast()
}
```

## 常见问题

### Q: Extension 不显示在分享菜单中
**A:** 
1. 检查 Info.plist 中的 NSExtensionActivationRule
2. 确认 Deployment Target >= iOS 15.0
3. 完全卸载并重新安装应用

### Q: 编译错误 "Cannot find 'ShareViewController' in scope"
**A:**
1. 确认 `ShareViewController.swift` 在 Extension target 中
2. Clean Build Folder
3. 检查 module name 配置

### Q: UI 显示异常
**A:**
1. 确认移除了 MainInterface.storyboard 的引用
2. 检查 NSExtensionPrincipalClass 配置
3. 查看 Console 日志

## 未来改进方向

1. **添加动画效果**
2. **支持多选和批量处理**
3. **添加分类标签功能**
4. **实现本地缓存和离线处理**
5. **优化加载性能**

---

## 技术支持

如遇问题，请检查：
1. Console 日志输出
2. Info.plist 配置
3. Target 成员关系
4. App Group 配置
