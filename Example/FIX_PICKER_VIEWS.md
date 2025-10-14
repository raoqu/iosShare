# 修复 PhotoPickerView 和 DocumentPickerView 编译错误

## 问题

```
Cannot find 'PhotoPickerView' in scope
Cannot find 'DocumentPickerView' in scope
```

## 原因

文件已创建，但没有添加到 Xcode 项目的 App target 中。

## 解决步骤

### 方法 1：在 Xcode 中添加文件

1. **打开 Xcode Project Navigator**（左侧面板）

2. **找到 App 文件夹**

3. **右键点击 App 文件夹**
   - 选择 "Add Files to..."

4. **选择文件**
   - 导航到 `Example/App/` 目录
   - 选中以下文件：
     - `PhotoPickerView.swift`
     - `DocumentPickerView.swift`

5. **配置选项**
   ```
   ☑️ Copy items if needed (不勾选，文件已经在正确位置)
   ☑️ Create groups (选中)
   
   Add to targets:
   ☑️ App (必须勾选)
   ☐ Extension (不勾选)
   ```

6. **点击 "Add"**

### 方法 2：检查现有文件的 Target Membership

如果文件已经在项目中但报错：

1. **在 Project Navigator 中选中文件**
   - 点击 `PhotoPickerView.swift`

2. **打开 File Inspector**（右侧面板）
   - 快捷键：`Cmd + Option + 1`

3. **检查 Target Membership**
   ```
   ☑️ App              ← 必须勾选
   ☐ Extension         ← 不要勾选
   ```

4. **对 `DocumentPickerView.swift` 重复相同操作**

### 方法 3：通过命令行验证

```bash
cd /Users/raoqu/mylab/iosShare/Example

# 验证文件存在
ls -la App/PhotoPickerView.swift
ls -la App/DocumentPickerView.swift

# 如果文件存在，问题在 Xcode 项目配置
```

## 验证修复

### 1. Clean Build Folder
```
Product → Clean Build Folder (Shift + Cmd + K)
```

### 2. 重新编译
```
Product → Build (Cmd + B)
```

### 3. 检查错误消失
- ✅ `PhotoPickerView` 不再报错
- ✅ `DocumentPickerView` 不再报错
- ✅ `fontWeight` 错误已修复

## 常见问题

### Q: 文件显示为红色？
**A:** 文件引用丢失
- 删除红色引用（Remove Reference）
- 重新添加文件（Add Files to...）

### Q: 添加后仍然报错？
**A:** 检查步骤：
1. 确认文件在 Project Navigator 中可见
2. 选中文件，查看右侧 Target Membership
3. 确保 App target 已勾选
4. Clean Build
5. 重新编译

### Q: 找不到 Add Files to... 选项？
**A:** 
- 确保右键点击的是文件夹（而不是文件）
- 或使用菜单：File → Add Files to "XExtensionItemExample"...

### Q: 编译时提示其他错误？
**A:** 可能的问题：
1. Swift 版本不匹配（需要 Swift 5+）
2. iOS 版本不匹配（需要 iOS 14+）
3. 缺少 import 语句

## 完整的文件列表

确保以下文件都在 App target 中：

```
App/
├── MainView.swift              ✓
├── SharedItem.swift            ✓
├── SharedItemRow.swift         ✓
├── PhotoPickerView.swift       ← 新增，需要添加
├── DocumentPickerView.swift    ← 新增，需要添加
├── ViewController.m            ✓
└── AppDelegate.m               ✓

Shared/
└── SharedItemModel.swift       ✓ (App + Extension)
```

## iOS 版本兼容性已修复

**之前：**
```swift
.font(.title2)
.fontWeight(.semibold)  // ❌ iOS 16.0+
```

**现在：**
```swift
.font(.system(size: 24, weight: .semibold))  // ✅ iOS 13+
```

## 预期结果

修复后应该可以正常编译，并且：
- ✅ 点击"+"按钮显示菜单
- ✅ 选择"拍照或选择照片"打开照片选择器
- ✅ 选择"选择文件"打开文档选择器
- ✅ 选择"输入文本"显示输入框

## 如果问题仍然存在

尝试以下步骤：

1. **完全重建项目**
   ```
   1. 关闭 Xcode
   2. 删除 DerivedData:
      rm -rf ~/Library/Developer/Xcode/DerivedData
   3. 重新打开项目
   4. Clean + Build
   ```

2. **手动检查 project.pbxproj**
   ```bash
   # 查看文件是否在项目配置中
   cd XExtensionItemExample.xcodeproj
   grep -n "PhotoPickerView.swift" project.pbxproj
   grep -n "DocumentPickerView.swift" project.pbxproj
   ```

3. **重新创建文件引用**
   - 在 Xcode 中删除文件引用（Remove Reference）
   - 重新添加文件（Add Files to...）
   - 确保勾选正确的 target

---

完成这些步骤后，项目应该可以正常编译运行了！
