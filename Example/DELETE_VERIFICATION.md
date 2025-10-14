# 删除功能验证指南

## 问题已修复

主应用中的"删除"和"清空所有"功能现在会正确删除数据。

## 修复内容

### 1. deleteItem(at:) - 单项删除

**修复前：**
```swift
func deleteItem(at offsets: IndexSet) {
    items.remove(atOffsets: offsets)
    saveItems()  // 只保存到旧格式
}
```

**修复后：**
```swift
func deleteItem(at offsets: IndexSet) {
    let itemsToDelete = offsets.map { items[$0] }
    items.remove(atOffsets: offsets)
    
    // 从新格式存储中删除（包括文件）
    let storage = SharedStorageManager.shared
    for item in itemsToDelete {
        storage.deleteItem(id: item.id.uuidString)
    }
    
    saveItems()
    print("🗑️ Deleted \(itemsToDelete.count) items")
}
```

### 2. deleteItem(_:) - 指定项目删除

**修复后：**
```swift
func deleteItem(_ item: SharedItem) {
    items.removeAll { $0.id == item.id }
    
    // 从新格式存储中删除（包括文件）
    SharedStorageManager.shared.deleteItem(id: item.id.uuidString)
    
    saveItems()
    print("🗑️ Deleted item: \(item.title)")
}
```

### 3. clearAll() - 清空所有

**修复前：**
```swift
func clearAll() {
    items.removeAll()
    saveItems()  // 只清空内存和旧格式
}
```

**修复后：**
```swift
func clearAll() {
    print("🗑️ Clearing all items...")
    
    // 清空 UI 列表
    items.removeAll()
    
    // 清空新格式存储（包括所有文件）
    SharedStorageManager.shared.clearAll()
    
    // 清空旧格式存储
    defaults.removeObject(forKey: userDefaultsKey)
    defaults.synchronize()
    
    print("✅ All items cleared")
}
```

### 4. ID 映射修复

**加载时保留原始 ID：**
```swift
// 使用 SharedItemModel 的 id 创建 UUID
let itemId: UUID
if let uuid = UUID(uuidString: model.id) {
    itemId = uuid
} else {
    itemId = UUID()
}

return SharedItem(
    id: itemId,  // ← 使用相同的 ID
    title: model.title,
    contentType: contentType,
    content: content,
    timestamp: model.timestamp
)
```

## 删除流程

### 单项删除流程

```
用户滑动删除某项
    ↓
SharedItemsManager.deleteItem(at:)
    ↓
1. 从 items 数组移除
    ↓
2. SharedStorageManager.deleteItem(id:)
    ↓
3. 查找 SharedItemModel
    ↓
4. 如果有文件，删除文件
    ↓
5. 从 SharedItemsV2 移除
    ↓
6. 保存更新后的列表
    ↓
完成
```

### 清空所有流程

```
用户点击"清空所有"
    ↓
SharedItemsManager.clearAll()
    ↓
1. 清空 items 数组
    ↓
2. SharedStorageManager.clearAll()
    ↓
3. 删除 SharedFiles 目录
    ↓
4. 清空 SharedItemsV2
    ↓
5. 清空旧格式 SharedItems
    ↓
完成
```

## 验证步骤

### 测试 1：单项删除

1. **分享一张照片**
   ```
   Extension → 保存图片到 SharedFiles/
   Extension → 添加项目到列表
   ```

2. **检查文件存在**
   ```bash
   # 在 Console 查看日志
   ✅ Saved: [photo] 照片名称
   ```

3. **在主应用中删除该项**
   ```
   滑动删除 → 点击"删除"
   ```

4. **验证结果**
   ```
   Console 输出:
   🗑️ Deleted 1 items
   
   检查：
   - [ ] UI 列表中不再显示
   - [ ] 文件已从 SharedFiles/ 删除
   - [ ] UserDefaults 中已移除
   ```

### 测试 2：清空所有

1. **分享多个项目**
   ```
   - 2 张照片
   - 1 个链接
   - 1 段文本
   ```

2. **检查数据**
   ```bash
   # Console 查看
   ✅ Loaded 4 items (New Standard Format)
   ```

3. **点击"清空所有"**
   ```
   菜单 → 清空所有 → 确认
   ```

4. **验证结果**
   ```
   Console 输出:
   🗑️ Clearing all items...
   ✅ All items cleared
   
   检查：
   - [ ] UI 列表为空
   - [ ] SharedFiles/ 目录已删除
   - [ ] SharedItemsV2 已清空
   - [ ] SharedItems（旧格式）已清空
   ```

### 测试 3：混合格式清理

1. **确保有旧格式数据**
   ```swift
   // 如果使用过旧版本，可能有旧数据
   ```

2. **点击"清空所有"**

3. **验证两种格式都被清空**
   ```
   检查：
   - [ ] 新格式 (SharedItemsV2) 已清空
   - [ ] 旧格式 (SharedItems) 已清空
   - [ ] 所有文件已删除
   ```

## 文件删除验证

### 检查文件是否真正删除

```bash
# 1. 获取 App Group 容器路径
# 在代码中打印：
if let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.cc.raoqu.transany"
) {
    print("Container: \(containerURL.path)")
}

# 2. 在终端中检查
cd [打印的路径]/SharedFiles
ls -la

# 3. 删除前应该看到文件
# 4. 删除后应该看不到文件或目录不存在
```

### Console 日志示例

**正常删除：**
```
🗑️ Deleted 1 items
✅ Deleted file: 550e8400-e29b-41d4-a716-446655440000.jpg
```

**清空所有：**
```
🗑️ Clearing all items...
✅ All items cleared
```

## 常见问题

### Q: 删除后 UI 没有更新？

**A:** 检查 `@Published` 属性是否正确触发：
```swift
items.remove(atOffsets: offsets)  // ✅ 这会触发 UI 更新
```

### Q: 文件没有被删除？

**A:** 检查日志：
```
1. 是否找到了 item？
2. 是否有 filePath？
3. deleteFile 是否被调用？
```

### Q: 清空后重新分享还能看到旧数据？

**A:** 检查：
1. 是否清空了两种格式的数据
2. 是否调用了 `defaults.synchronize()`
3. Extension 是否使用了正确的 key

### Q: ID 不匹配导致删除失败？

**A:** 验证 ID 映射：
```swift
// 加载时
if let uuid = UUID(uuidString: model.id) {
    itemId = uuid  // ✅ 使用相同的 ID
}

// 删除时
storage.deleteItem(id: item.id.uuidString)  // ✅ 转换回字符串
```

## 调试技巧

### 1. 启用详细日志

所有关键操作都有日志输出：
```swift
print("🗑️ Deleted \(itemsToDelete.count) items")
print("✅ All items cleared")
```

### 2. 检查存储状态

```swift
// 查看当前存储的项目数
let storage = SharedStorageManager.shared
let items = storage.loadItems()
print("Current items count: \(items.count)")
```

### 3. 验证文件系统

```swift
if let filesDir = SharedStorageManager.shared.sharedFilesDirectory {
    let files = try? FileManager.default.contentsOfDirectory(atPath: filesDir.path)
    print("Files: \(files ?? [])")
}
```

## 性能考虑

### 批量删除

```swift
// ✅ 高效：一次性删除多个
for item in itemsToDelete {
    storage.deleteItem(id: item.id.uuidString)
}

// 每个项目单独处理，但文件删除是独立的
```

### 清空优化

```swift
// ✅ 直接删除目录比逐个删除文件更快
try? FileManager.default.removeItem(at: filesDir)
```

## 总结

删除功能现在完整实现：

- ✅ 单项删除：UI + 数据 + 文件
- ✅ 批量删除：支持多选
- ✅ 清空所有：彻底清理
- ✅ ID 映射：正确匹配
- ✅ 兼容性：处理新旧格式
- ✅ 日志输出：便于调试

所有删除操作都会真正删除存储的数据和文件！🎉
