# SwiftUI Share Extension 配置清单

## ✅ 已完成的代码更改

- ✅ 创建 `ShareView.swift`（SwiftUI 视图 + ViewModel）
- ✅ 创建 `ShareViewController.swift`（Swift UIViewController）
- ✅ 备份旧文件为 `.old` 后缀
- ✅ 更新 `Info.plist` 使用 Swift Principal Class

## 🔧 需要在 Xcode 中手动完成的步骤

### 1. 文件管理（在 Xcode Project Navigator 中）

#### 添加新文件到 Extension Target
1. 在项目中找到 `Extension` 文件夹
2. 确认以下文件的 Target Membership：
   - ✅ `ShareView.swift` → 勾选 **Extension** target
   - ✅ `ShareViewController.swift` → 勾选 **Extension** target

#### 移除旧文件
1. 选择 `ShareViewController.m.old`
2. 在 Target Membership 中取消勾选 **Extension**（或直接删除引用）
3. 选择 `ShareViewController.h.old`  
4. 在 Target Membership 中取消勾选 **Extension**（或直接删除引用）

#### 可选：移除 MainInterface.storyboard
因为 SwiftUI 不再需要 storyboard：
1. 选择 `MainInterface.storyboard`
2. 可以取消勾选 Extension target（保留备份）或完全删除

### 2. Extension Target 配置

#### Build Settings
1. 选择 **Extension** target
2. 进入 **Build Settings**
3. 搜索 "Swift Language Version"
   - 确保设置为 **Swift 5** 或更高
4. 搜索 "Defines Module"
   - 设置为 **Yes**

#### General
1. 选择 **Extension** target
2. 进入 **General** 标签
3. **Deployment Info**
   - 确认 **Deployment Target** >= **iOS 15.0**

### 3. App Groups（重要）

确保 Extension 和 App 都配置了相同的 App Group：

#### Extension Target
1. 选择 **Extension** target
2. 进入 **Signing & Capabilities**
3. 检查是否有 **App Groups**
4. 确认勾选：`group.cc.raoqu.transany`

#### App Target  
1. 选择 **App** target
2. 进入 **Signing & Capabilities**
3. 检查是否有 **App Groups**
4. 确认勾选：`group.cc.raoqu.transany`

### 4. Info.plist 验证

在 Xcode 中打开 `Extension/Info.plist`，确认：

```xml
<key>NSExtensionPrincipalClass</key>
<string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
```

**不应该**包含：
```xml
<key>NSExtensionMainStoryboard</key>  <!-- 应该已删除 -->
```

### 5. Clean Build

1. **Product** → **Clean Build Folder**（Shift + Cmd + K）
2. 或在 Finder 中删除 DerivedData：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### 6. 编译和测试

1. 选择正确的 Scheme（App 或 Extension）
2. 选择模拟器或真机
3. **Product** → **Run**（Cmd + R）

## 🧪 验证步骤

### 编译验证
```
✅ Extension target 编译成功
✅ App target 编译成功
✅ 没有 "Cannot find 'ShareViewController'" 错误
✅ 没有 Objective-C 相关的链接错误
```

### 运行验证
1. 安装应用到设备/模拟器
2. 打开照片应用
3. 选择一张照片
4. 点击分享图标
5. 查找"发送到TransAny"选项

```
✅ 能看到"发送到TransAny"选项
✅ 点击后显示 SwiftUI 界面（不是旧的 SLComposeServiceViewController）
✅ 显示图片预览
✅ 可以输入描述文字
✅ 点击"发布"能保存数据
✅ 主应用能看到分享的内容
```

## 🐛 常见问题排查

### 问题 1: Extension 不显示在分享菜单中

**可能原因：**
- Info.plist 配置错误
- Extension target 没有正确编译

**解决方案：**
1. 完全卸载应用
2. Clean Build Folder
3. 重新安装

### 问题 2: 编译错误 "Cannot find 'ShareViewController' in scope"

**可能原因：**
- 新的 Swift 文件没有添加到 Extension target
- Module name 配置问题

**解决方案：**
1. 检查 `ShareViewController.swift` 的 Target Membership
2. 确认 Extension target 的 "Defines Module" = Yes
3. Clean Build

### 问题 3: 运行时显示旧的 UI

**可能原因：**
- 旧的 Objective-C 文件仍在 target 中
- 缓存问题

**解决方案：**
1. 确认移除了 `.m` 和 `.h` 文件的 target membership
2. 删除应用重新安装
3. 重启 Xcode

### 问题 4: 数据没有保存

**可能原因：**
- App Group 未正确配置
- identifier 不匹配

**解决方案：**
1. 检查两个 target 的 App Groups 配置
2. 确认都使用 `group.cc.raoqu.transany`
3. 查看 Console 日志

## 📊 验证清单

完成配置后，逐项确认：

- [ ] Extension target 包含 `ShareView.swift` 和 `ShareViewController.swift`
- [ ] Extension target 移除了旧的 `.m` 和 `.h` 文件
- [ ] Info.plist 使用 `NSExtensionPrincipalClass` 而非 `NSExtensionMainStoryboard`
- [ ] Swift Language Version >= 5
- [ ] Deployment Target >= iOS 15.0
- [ ] App Groups 在两个 target 都正确配置
- [ ] Clean Build 成功
- [ ] 编译无错误
- [ ] Extension 显示在分享菜单中
- [ ] SwiftUI 界面正确显示
- [ ] 数据能正确保存和加载

## 🎉 成功标志

当你看到：
1. ✅ 分享菜单显示"发送到TransAny"
2. ✅ 点击后显示现代化的 SwiftUI 界面（带图标预览）
3. ✅ 可以输入描述并正确保存
4. ✅ 主应用能看到新分享的内容

恭喜！SwiftUI 迁移成功！

## 🔄 回滚方案

如果遇到无法解决的问题，可以快速回滚：

```bash
cd Example/Extension
mv ShareViewController.m.old ShareViewController.m
mv ShareViewController.h.old ShareViewController.h
```

然后在 Xcode 中：
1. 移除 SwiftUI 文件
2. 恢复 Info.plist（使用 Git）
3. 重新添加 Objective-C 文件到 target
4. Clean Build

## 📝 下一步

迁移成功后，可以：
1. 自定义 SwiftUI UI 样式
2. 添加更多交互功能
3. 优化图片处理性能
4. 实现更复杂的分享逻辑

---

**需要帮助？** 查看详细迁移文档：`MIGRATION_TO_SWIFTUI.md`
