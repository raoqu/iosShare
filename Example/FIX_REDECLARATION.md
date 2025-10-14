# 修复 SharedItemModel 重复声明错误

## 问题原因

`SharedItemModel.swift` 文件被创建在了多个位置：
- ~~App/SharedItemModel.swift~~ ❌ 已删除
- ~~Extension/SharedItemModel.swift~~ ❌ 已删除
- ✅ Shared/SharedItemModel.swift ← 保留此文件

## 已完成的修复

已通过命令行删除重复文件，现在只保留 `Shared/SharedItemModel.swift`。

## Xcode 中需要的操作

### 1. 清理旧引用

如果在 Project Navigator 中看到红色标记的文件：

1. 选中红色的 `SharedItemModel.swift` 引用
2. 按 `Delete` 键
3. 选择 **"Remove Reference"**（不是 Move to Trash）

### 2. 确认 Target Membership

选中 `Shared/SharedItemModel.swift`，在右侧 File Inspector 中确认：

```
Target Membership:
☑️ App              ← 必须勾选
☑️ Extension        ← 必须勾选
```

### 3. Clean Build

执行清理：
```
Product → Clean Build Folder (Shift + Cmd + K)
```

或者删除 DerivedData：
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 4. 重新编译

```
Product → Build (Cmd + B)
```

## 验证步骤

### 检查 1：文件位置
```bash
cd /Users/raoqu/mylab/iosShare/Example
find . -name "SharedItemModel.swift"
```

应该只输出：
```
./Shared/SharedItemModel.swift
```

### 检查 2：编译通过
- App target 编译成功
- Extension target 编译成功
- 没有 "Invalid redeclaration" 错误

### 检查 3：导入正常
在代码中可以正常使用：
```swift
// Extension 中
let item = SharedItemModel.createPhotoItem(...)

// App 中
let storage = SharedStorageManager.shared
```

## 如果仍有问题

### 问题：Xcode 中看不到 Shared 文件夹

**解决方案：**
1. 在 Project Navigator 中右键点击项目根目录
2. 选择 "Add Files to..."
3. 选择 `Shared/SharedItemModel.swift`
4. 确保勾选两个 target
5. 点击 "Add"

### 问题：Cannot find 'SharedStorageManager' in scope

**原因：** 文件没有添加到正确的 target

**解决方案：**
1. 选中 `SharedItemModel.swift`
2. 在 File Inspector 中同时勾选 App 和 Extension

### 问题：编译时仍提示重复声明

**解决方案：**
1. Clean Build Folder
2. 关闭 Xcode
3. 删除 DerivedData
4. 重新打开项目
5. 重新编译

## 文件结构（最终状态）

```
Example/
├── App/
│   ├── MainView.swift
│   ├── SharedItem.swift
│   └── ... (不包含 SharedItemModel.swift)
│
├── Extension/
│   ├── ShareView.swift              # 使用 ShareItemModel (临时)
│   ├── ShareViewController.swift
│   └── ... (不包含 SharedItemModel.swift)
│
└── Shared/
    └── SharedItemModel.swift        # ← 唯一的统一模型
```

## 模型区分

### ShareItemModel (Extension 内部)
```swift
// ShareView.swift 中定义
struct ShareItemModel: Identifiable {
    // Extension UI 使用的临时模型
}
```

### SharedItemModel (跨应用共享)
```swift
// Shared/SharedItemModel.swift
struct SharedItemModel: Codable, Identifiable {
    // 持久化存储的统一模型
}
```

两者名称不同，不会冲突。

## 总结

✅ 删除了重复的文件  
✅ 只保留 `Shared/SharedItemModel.swift`  
⏳ 在 Xcode 中确认 Target Membership  
⏳ Clean Build  
⏳ 重新编译验证

完成这些步骤后，错误应该解决！
