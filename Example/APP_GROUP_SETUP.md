# App Group 配置指南

为了让主应用和 Share Extension 能够共享数据，需要在 Xcode 中配置 App Groups。

## 配置步骤

### 1. 配置主应用（App target）

1. 在 Xcode 中选择项目，然后选择 **App** target
2. 点击 **Signing & Capabilities** 标签
3. 点击 **+ Capability** 按钮
4. 添加 **App Groups**
5. 勾选或添加：`group.com.transany.shared`

### 2. 配置 Extension（Extension target）

1. 选择 **Extension** target（Share Extension）
2. 点击 **Signing & Capabilities** 标签
3. 点击 **+ Capability** 按钮
4. 添加 **App Groups**
5. 勾选或添加：`group.com.transany.shared`（与主应用相同）

### 3. 重新编译并安装

配置完成后，需要：
1. Clean Build Folder（Shift + Cmd + K）
2. 重新运行应用（Cmd + R）
3. 完全卸载并重新安装应用

## 验证

配置成功后：
1. 打开照片应用
2. 选择一张照片
3. 点击分享按钮
4. 应该能看到"发送到TransAny"选项
5. 分享后，数据会出现在 TransAny 主应用中

## 常见问题

### Q: 看不到"发送到TransAny"选项
**A:** 
- 确保两个 target 都添加了相同的 App Group
- 确保应用已完全卸载并重新安装
- 检查 Extension target 的 Deployment Info 中 iOS 版本设置

### Q: 分享后主应用看不到数据
**A:**
- 检查两个 target 使用的 App Group identifier 是否完全一致
- 查看 Xcode Console 日志，确认数据已保存
- 确保主应用重新加载了数据

### Q: App Group identifier 需要修改吗？
**A:**
- 如果 `group.com.transany.shared` 已被占用，可以修改为 `group.YOUR_TEAM_ID.transany`
- 修改后需要同步更新：
  - `AppGroupConfig.swift` 中的 `identifier`
  - `ShareViewController.m` 中的 suiteName
