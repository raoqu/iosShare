# 修复 Framework 沙盒权限错误

## 错误信息
```
Sandbox: rsync deny(1) file-read-data XExtensionItem.framework
Sandbox: rsync deny(1) file-write-unlink XExtensionItem.framework
```

## 原因
在构建真机版本时，Xcode 的沙盒机制阻止 rsync 复制 XExtensionItem.framework。

---

## ✅ 解决方案 1：使用模拟器（推荐）

### 优点：
- ✅ 无需代码签名
- ✅ 无需开发者账号
- ✅ 构建更快
- ✅ 不会遇到沙盒问题

### 步骤：
1. 在 Xcode 顶部选择 **iPhone 模拟器**（不要选 iPhone 设备）
2. Clean: **⌘ + Shift + K**
3. Run: **⌘ + R**

---

## ✅ 解决方案 2：修复真机构建

如果必须在真机上测试：

### 步骤 1：检查 Framework 嵌入设置

1. 在 Xcode 中点击项目图标（蓝色）
2. 选择 **XExtensionItemExample** target
3. 选择 **General** 标签
4. 滚动到 **"Frameworks, Libraries, and Embedded Content"** 部分
5. 找到 **XExtensionItem.framework**
6. 确保右侧选择的是 **"Embed & Sign"** 或 **"Do Not Embed"**

**推荐设置：**
```
XExtensionItem.framework → Do Not Embed
```

因为这是通过 CocoaPods 管理的，不需要手动嵌入。

### 步骤 2：检查 CocoaPods 配置

在终端执行：
```bash
cd /Users/raoqu/mylab/iosShare/Example
pod deintegrate
pod install
```

### 步骤 3：清理并重新构建

```bash
# 删除 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/XExtensionItemExample-*

# 在 Xcode 中
⌘ + Shift + K  # Clean
⌘ + B          # Build
⌘ + R          # Run
```

---

## ✅ 解决方案 3：配置代码签名

真机构建需要正确的签名配置：

### 步骤 1：配置 App Target

1. 选择项目 → **XExtensionItemExample** target
2. **Signing & Capabilities** 标签
3. ✅ 勾选 **"Automatically manage signing"**
4. 选择你的 **Team**（需要 Apple Developer 账号）
5. Bundle Identifier 会自动调整

### 步骤 2：配置 Extension Target

1. 选择项目 → **XExtensionItemExample Extension** target（或类似名称）
2. **Signing & Capabilities** 标签
3. ✅ 勾选 **"Automatically manage signing"**
4. 选择相同的 **Team**
5. Bundle Identifier 应该是：`主应用ID.Extension`

### 步骤 3：配置 Pods Target

1. 选择 **Pods-XExtensionItemExample** target
2. **Build Settings** 标签
3. 搜索 **"Code Signing Identity"**
4. 设置为 **"iOS Developer"**

---

## 🎯 推荐方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **使用模拟器** | ✅ 简单<br>✅ 无需签名<br>✅ 快速 | ❌ 不是真机环境 | ⭐⭐⭐⭐⭐ |
| **修复 Framework 设置** | ✅ 可以用真机<br>✅ 真实环境 | ❌ 需要配置<br>❌ 可能遇到其他问题 | ⭐⭐⭐ |
| **重新安装 Pods** | ✅ 彻底解决依赖问题 | ❌ 需要时间<br>❌ 可能需要网络 | ⭐⭐⭐⭐ |

---

## 🚀 快速修复（推荐）

**最简单的方法：使用模拟器**

```
1️⃣ 在 Xcode 顶部选择模拟器（如 iPhone 14 Pro）
2️⃣ 按 ⌘ + Shift + K (Clean)
3️⃣ 按 ⌘ + R (Run)
✅ 完成！
```

---

## 📱 测试 Share Extension

无论使用模拟器还是真机，测试步骤相同：

### 在照片应用中测试：
1. 打开 **照片** 应用
2. 选择一张照片（模拟器可能需要先添加）
3. 点击 **分享按钮** ⬆️
4. 查找 **"发送到TransAny"**

### 在 Safari 中测试：
1. 打开 **Safari**
2. 访问任意网页（如 apple.com）
3. 点击 **分享按钮** ⬆️
4. 查找 **"发送到TransAny"**

---

## 🐛 如果问题仍然存在

### 完全重置（终极方案）

```bash
cd /Users/raoqu/mylab/iosShare/Example

# 1. 清理 Pods
pod deintegrate
rm -rf Pods
rm Podfile.lock

# 2. 清理构建产物
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. 重新安装 Pods
pod install

# 4. 在 Xcode 中
# - 关闭 Xcode
# - 打开 XExtensionItemExample.xcworkspace
# - 选择模拟器
# - Clean (⌘ + Shift + K)
# - Run (⌘ + R)
```

---

## 💡 为什么会出现这个错误？

### 技术原因：
1. **CocoaPods 管理的 Framework** 在真机构建时有特殊的嵌入规则
2. **Xcode 的沙盒** 限制了 rsync 对某些文件的访问
3. **代码签名冲突** 导致 Framework 无法正确复制
4. **DerivedData 缓存** 可能包含过期的构建信息

### 为什么模拟器不会有这个问题？
- 模拟器使用 x86_64/arm64 架构（Mac 的）
- 不需要代码签名
- 沙盒限制较少
- Framework 处理方式不同

---

## ✅ 成功的标志

当问题解决后：

✅ 构建过程没有 rsync 错误  
✅ 没有沙盒拒绝访问的消息  
✅ 应用成功安装到模拟器/设备  
✅ 应用正常运行  
✅ Share Extension "发送到TransAny" 出现在分享菜单中

---

**对于开发和测试 Share Extension，强烈推荐使用模拟器！** 🎯
