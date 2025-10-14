# Share Extension 使用和测试指南

## 已修复的问题

### 1. ✅ 用户输入的文本保存
- 使用 `self.contentText` 获取用户在分享界面输入的文本
- 文本会作为 item 的 `title` 保存

### 2. ✅ 异步附件处理
- 图片、URL、文本等附件现在正确异步加载
- 使用 `dispatch_group` 确保所有附件处理完成后再保存
- 避免了之前同步保存导致数据丢失的问题

### 3. ✅ 图片信息保存
- 检测到图片后会保存图片尺寸信息
- 类型正确标记为 `image`

### 4. ✅ App 自动刷新
- 主应用在启动时自动刷新数据
- 从后台返回前台时自动刷新
- 通过 URL Scheme 唤起时触发刷新

## 工作流程

### 分享流程
1. 用户在照片/Safari/其他应用中点击"分享"
2. 选择"发送到TransAny"
3. 在文本框中输入描述（可选）
4. 点击"发布"按钮
5. Extension 处理附件：
   - 图片 → 保存尺寸信息
   - URL → 保存链接地址
   - 文本 → 保存文本内容
6. 数据保存到 App Group 共享的 UserDefaults
7. 自动打开主应用
8. 主应用刷新并显示新数据

### 数据流
```
Share Extension (用户输入 + 附件)
    ↓
处理异步附件加载
    ↓
保存到 App Group UserDefaults
    ↓
打开主应用 (transany://)
    ↓
主应用接收 URL Scheme
    ↓
触发刷新通知
    ↓
MainView 自动刷新显示
```

## 测试步骤

### 1. 配置 App Groups（必须）
确保在 Xcode 中为两个 target 都添加了 `group.cc.raoqu.transany`

### 2. 测试图片分享
1. 打开系统照片应用
2. 选择一张照片
3. 点击分享图标
4. 选择"发送到TransAny"
5. 输入描述文字（例如："美丽的风景"）
6. 点击"发布"
7. ✅ 应该自动打开 TransAny 并显示新项目

### 3. 测试网页分享
1. 打开 Safari
2. 访问任意网页
3. 点击分享图标
4. 选择"发送到TransAny"
5. 输入备注
6. 点击"发布"
7. ✅ 应该保存 URL 并显示在列表中

### 4. 测试文本分享
1. 在备忘录中选择一段文字
2. 点击分享
3. 选择"发送到TransAny"
4. 可以添加额外的描述
5. 点击"发布"
6. ✅ 文本应该正确保存

## 调试技巧

### 查看日志
在 Xcode Console 中可以看到详细的调试日志：

```
📷 Loaded image: {750, 1334}
🔗 Loaded URL: https://example.com
📝 Loaded text: Some text content
✅ All attachments processed
✅ Saved 1 items to UserDefaults (App Group: group.cc.raoqu.transany)
📱 App opened with URL: transany://
```

### 常见问题排查

**Q: 点击"发布"后没有反应**
- 检查是否配置了正确的 App Groups
- 确认两个 target 使用相同的 group identifier

**Q: 主应用看不到分享的数据**
- 检查 Console 日志中是否有保存成功的消息
- 确认主应用正确加载了 App Group 的 UserDefaults
- 尝试重启应用

**Q: 图片没有保存**
- 图片本身不会保存到 UserDefaults（体积太大）
- 目前只保存图片的尺寸信息作为元数据
- 如需保存图片，需要使用共享容器目录

## 代码关键点

### Extension 端（ShareViewController.m）
```objc
// 获取用户输入
NSString *userComment = self.contentText;

// 异步处理附件
[self processAttachmentsWithCompletion:^{
    [self saveSharedItems];
    [self openMainApp];
}];
```

### 主应用端（MainView.swift）
```swift
.onAppear {
    manager.refresh()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    manager.refresh()
}
```

### SceneDelegate（SceneDelegate.m）
```objc
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    // 处理 URL Scheme，触发刷新
}
```

## 未来改进建议

1. **图片保存**：将图片保存到共享容器，UserDefaults 只存路径
2. **缩略图**：生成并保存缩略图提升 UI 体验
3. **进度提示**：在 Extension 中显示处理进度
4. **错误处理**：更完善的错误提示和重试机制
5. **数据加密**：敏感数据加密存储
