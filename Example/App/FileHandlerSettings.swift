import Foundation
import SwiftUI

// FileHandlerRule 和 FileHandlerSettingsManager 已移至 Shared/FileHandlerRule.swift
// 这个文件现在只包含设置界面的 SwiftUI 视图代码

/// App Group 配置
private enum AppGroupConfig {
    static let identifier = "group.cc.raoqu.transany"
    nonisolated(unsafe) static let sharedDefaults: UserDefaults? = UserDefaults(suiteName: identifier)
}
