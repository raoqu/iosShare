# 故障排除指南

## 🔧 问题 1: SceneDelegate 类找不到

### 错误信息：
```
Info.plist configuration "Default Configuration" for UIWindowSceneSessionRoleApplication 
contained UISceneDelegateClassName key, but could not load class with name "SceneDelegate".
```

### 原因：
SceneDelegate.h 和 SceneDelegate.m 文件已创建，但未添加到 Xcode 项目中。

### ✅ 解决步骤：

#### 方法 1：在 Xcode 中手动添加文件

1. **在 Xcode 的 Project Navigator（左侧面板）中：**
   - 找到 `App` 文件夹（黄色图标）
   - 右键点击 → 选择 **"Add Files to 'XExtensionItemExample'..."**

2. **选择文件：**
   - 导航到：`/Users/raoqu/mylab/iosShare/Example/App`
   - 按住 ⌘ 键，选择：
     - `SceneDelegate.h`
     - `SceneDelegate.m`

3. **配置选项：**
   - ⚠️ **取消勾选** "Copy items if needed" （文件已在正确位置）
   - ✅ **勾选** Target: "XExtensionItemExample"
   - 点击 **"Add"**

4. **验证文件已添加：**
   - 在 Project Navigator 中，`App` 文件夹下应该看到：
     - SceneDelegate.h（白色文档图标）
     - SceneDelegate.m（白色文档图标）
   - 点击文件，在右侧的 File Inspector 中检查 "Target Membership" 是否勾选了 XExtensionItemExample

5. **清理并重新构建：**
   ```
   ⌘ + Shift + K   (Clean Build Folder)
   ⌘ + B           (Build)
   ⌘ + R           (Run)
   ```

#### 方法 2：使用命令行验证文件

在终端运行以下命令，确认文件存在：
```bash
cd /Users/raoqu/mylab/iosShare/Example
ls -la App/SceneDelegate.*
```

应该看到：
```
-rw-r--r-- SceneDelegate.h
-rw-r--r-- SceneDelegate.m
```

---

## 🔧 问题 2: "发送到TransAny" 未显示在分享菜单中

### 可能的原因：

1. **Extension Target 未被构建**
2. **Extension 未安装到模拟器/设备**
3. **Extension 需要重新安装**
4. **模拟器/设备缓存问题**

### ✅ 解决步骤：

#### 步骤 1: 确保 Extension Target 被构建

1. **在 Xcode 中选择 Scheme：**
   - 点击顶部工具栏的 Scheme 选择器（项目名称旁边）
   - 应该看到两个 scheme：
     - `XExtensionItemExample` （主应用）
     - `XExtensionItemExample Extension` 或类似名称
   
2. **检查 Extension Target：**
   - 点击 Xcode 左侧的项目图标（蓝色）
   - 在 TARGETS 列表中应该看到：
     - XExtensionItemExample
     - XExtensionItemExample Extension (或类似名称)

3. **构建 Extension：**
   - 选择主应用的 scheme: `XExtensionItemExample`
   - 点击 Product → Build (⌘ + B)
   - 这会同时构建主应用和 Extension

#### 步骤 2: 完全重新安装应用

**方法 A：使用 Xcode**
```
1. 停止当前运行的应用
2. 在模拟器中完全删除应用（长按图标 → 删除 App）
3. 在 Xcode 中：Product → Clean Build Folder (⌘ + Shift + K)
4. 重新运行：⌘ + R
```

**方法 B：重置模拟器（如果问题持续）**
```
1. 停止模拟器
2. 在 Xcode 菜单：Window → Devices and Simulators
3. 选择你的模拟器
4. 右键 → Delete
5. 点击 "+" 创建新模拟器
6. 重新运行应用
```

#### 步骤 3: 验证 Extension 是否安装

1. **运行主应用后：**
   - 打开 iOS 的 **照片** 应用
   - 选择任意一张照片
   - 点击 **分享按钮** (⬆️)
   
2. **查找你的 Extension：**
   - 在分享菜单的应用图标行中寻找 **"发送到TransAny"**
   - 如果在第一排没看到，向左滑动查看更多
   - 如果还是没有，滚动到底部，点击 **"编辑操作"** 或 **"更多"**
   - 在列表中找到 **"发送到TransAny"**，确保开关是打开的

#### 步骤 4: 检查 Extension 的 Info.plist

确认 Extension 配置正确：

```bash
cd /Users/raoqu/mylab/iosShare/Example
cat Extension/Info.plist | grep -A 1 "CFBundleDisplayName"
```

应该看到：
```xml
<key>CFBundleDisplayName</key>
<string>发送到TransAny</string>
```

#### 步骤 5: 使用真机测试（推荐）

**Share Extensions 在真机上更可靠：**

1. 连接 iPhone/iPad 到电脑
2. 在 Xcode 中选择你的设备（而不是模拟器）
3. 配置 Signing & Capabilities：
   - 选择项目 → 选择 Target（主应用和 Extension）
   - 在 "Signing & Capabilities" 选项卡
   - 选择你的 Team
   - Xcode 会自动管理签名
4. 构建并运行到真机
5. 在真机的照片应用中测试分享功能

---

## 🎯 完整的检查清单

### SceneDelegate 问题：
- [ ] SceneDelegate.h 文件存在
- [ ] SceneDelegate.m 文件存在  
- [ ] 两个文件都添加到 Xcode 项目中
- [ ] Target Membership 勾选了 XExtensionItemExample
- [ ] 清理并重新构建项目
- [ ] 运行应用时没有 SceneDelegate 错误

### Share Extension 问题：
- [ ] Extension/Info.plist 中 CFBundleDisplayName 是 "发送到TransAny"
- [ ] Extension Target 在 Xcode 中可见
- [ ] 主应用构建时包含了 Extension
- [ ] 应用已完全重新安装（不是只是重新运行）
- [ ] 模拟器/设备上能看到 Extension（在分享菜单或"更多"中）
- [ ] Extension 的开关是打开的

---

## 📱 测试 Share Extension 的正确步骤

### 1. 构建并安装应用

```bash
# 在 Xcode 中
⌘ + Shift + K  # Clean
⌘ + B          # Build
⌘ + R          # Run
```

### 2. 等待应用完全安装

- 应用图标出现在主屏幕
- 应用启动并运行正常

### 3. 打开系统应用测试

**测试图片分享：**
1. 打开 **照片** 应用
2. 选择一张照片
3. 点击分享按钮 ⬆️
4. 查找 "发送到TransAny"

**测试 URL 分享：**
1. 打开 **Safari** 浏览器
2. 访问任意网页（如 apple.com）
3. 点击分享按钮 ⬆️
4. 查找 "发送到TransAny"

**测试文本分享：**
1. 打开 **备忘录** 应用
2. 创建或选择一条备忘录
3. 选中一些文本
4. 点击分享按钮
5. 查找 "发送到TransAny"

### 4. 如果 Extension 在"更多"中

如果 "发送到TransAny" 出现在分享菜单底部的 "更多" 中：

1. 点击 **"更多"** 或 **"编辑操作"**
2. 找到 **"发送到TransAny"**
3. 确保开关是**打开**的（绿色）
4. 可以拖动它到列表顶部以提高优先级
5. 点击 **"完成"**
6. 再次尝试分享，它应该出现在主菜单中

---

## 🐛 调试技巧

### 查看 Extension 是否被安装

运行以下命令（需要先在 Xcode 中运行应用）：

```bash
# 列出模拟器上安装的应用
xcrun simctl listapps booted | grep -i extension
```

### 查看控制台日志

1. 在 Xcode 中打开 Console（⌘ + Shift + Y）
2. 运行应用
3. 在 Safari 或照片中触发分享
4. 查看是否有错误信息

### 常见错误及解决方案

| 错误 | 解决方案 |
|------|---------|
| "Could not load class SceneDelegate" | 添加 SceneDelegate 文件到 Xcode 项目 |
| Extension 不出现 | 完全删除应用，重新安装 |
| Extension 在"更多"中 | 检查 NSExtensionActivationRule 配置 |
| 分享时应用崩溃 | 检查 ShareViewController 实现 |
| "Attempting to send message using a canceled session" | 重启模拟器或使用真机 |

---

## 💡 提示

### 最快的解决方案：

1. **在 Xcode 中添加 SceneDelegate 文件**
2. **完全删除应用（不是只停止运行）**
3. **Clean Build Folder**
4. **重新构建并运行**
5. **在照片应用中测试分享功能**

### 如果还是不行：

1. **使用真机而不是模拟器**
2. **重启 Xcode**
3. **重启 Mac**
4. **删除 DerivedData：**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

---

## 📞 需要更多帮助？

如果问题仍然存在：

1. 检查 Xcode 的 Issues Navigator (⌘ + 5) 查看所有警告和错误
2. 查看完整的控制台日志
3. 确认 iOS 版本（推荐 iOS 14+）
4. 确认 Xcode 版本（推荐 Xcode 12+）

---

## ✅ 成功的标志

当一切正常时，你应该看到：

1. ✅ 应用运行时没有 SceneDelegate 错误
2. ✅ 在照片应用的分享菜单中看到 "发送到TransAny"
3. ✅ 点击后打开你的 Share Extension 界面
4. ✅ Extension 能够接收和处理共享的内容

**当你看到 "发送到TransAny" 出现在分享菜单的第一排时，就成功了！** 🎉
