import Foundation
import SwiftUI

/// 处理规则类型
enum HandlerRuleType: String, Codable {
    case file       // 需要上传文件
    case url        // 只发送 URL，不上传文件
}

/// 文件处理规则
struct FileHandlerRule: Identifiable, Codable {
    let id: UUID
    var typeName: String            // 类型名称，如 "EXCEL", "PDF", "URL"
    var ruleType: HandlerRuleType   // 规则类型：文件上传或URL处理
    var fileExtensions: [String]    // 文件扩展名列表，如 ["xls", "xlsx"]（URL类型时可为空）
    var remoteURL: String           // 远程处理 URL
    var fileParameterName: String   // 文件参数名称，默认 "file"（仅文件类型使用）
    var customParameters: [String: String]  // 自定义参数键值对
    var isEnabled: Bool             // 是否启用
    
    init(
        id: UUID = UUID(),
        typeName: String,
        ruleType: HandlerRuleType = .file,
        fileExtensions: [String] = [],
        remoteURL: String,
        fileParameterName: String = "file",
        customParameters: [String: String] = [:],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.typeName = typeName
        self.ruleType = ruleType
        self.fileExtensions = fileExtensions.map { $0.lowercased() }
        self.remoteURL = remoteURL
        self.fileParameterName = fileParameterName
        self.customParameters = customParameters
        self.isEnabled = isEnabled
    }
    
    // 兼容旧版本的便捷初始化方法
    init(id: UUID = UUID(), fileExtension: String, remoteURL: String, isEnabled: Bool = true) {
        self.id = id
        self.typeName = fileExtension.uppercased()
        self.ruleType = .file
        self.fileExtensions = [fileExtension.lowercased()]
        self.remoteURL = remoteURL
        self.fileParameterName = "file"
        self.customParameters = [:]
        self.isEnabled = isEnabled
    }
}

/// 文件处理设置管理器
@MainActor
class FileHandlerSettingsManager: ObservableObject {
    @Published var rules: [FileHandlerRule] = []
    
    private let userDefaultsKey = "FileHandlerRules"
    private let defaults: UserDefaults
    
    static let shared = FileHandlerSettingsManager()
    
    private init() {
        // 使用 App Group 共享的 UserDefaults
        self.defaults = AppGroupConfig.sharedDefaults ?? .standard
        loadRules()
    }
    
    /// 加载规则
    func loadRules() {
        if let data = defaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([FileHandlerRule].self, from: data) {
            rules = decoded
            print("✅ Loaded \(rules.count) file handler rules")
        } else {
            // 使用默认规则
            rules = createDefaultRules()
            saveRules()
            print("ℹ️ Created default file handler rules")
        }
    }
    
    /// 保存规则
    func saveRules() {
        if let encoded = try? JSONEncoder().encode(rules) {
            defaults.set(encoded, forKey: userDefaultsKey)
            defaults.synchronize()
            print("✅ Saved \(rules.count) file handler rules")
        }
    }
    
    /// 添加规则
    func addRule(_ rule: FileHandlerRule) {
        rules.append(rule)
        saveRules()
    }
    
    /// 更新规则
    func updateRule(_ rule: FileHandlerRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            saveRules()
        }
    }
    
    /// 删除规则
    func deleteRule(at offsets: IndexSet) {
        rules.remove(atOffsets: offsets)
        saveRules()
    }
    
    /// 删除单个规则
    func deleteRule(_ rule: FileHandlerRule) {
        rules.removeAll { $0.id == rule.id }
        saveRules()
    }
    
    /// 根据文件扩展名获取处理规则
    func getRule(for fileExtension: String) -> FileHandlerRule? {
        let ext = fileExtension.lowercased()
        return rules.first(where: { $0.fileExtensions.contains(ext) && $0.isEnabled })
    }
    
    /// 根据文件扩展名获取处理 URL（向后兼容）
    func getHandlerURL(for fileExtension: String) -> String? {
        return getRule(for: fileExtension)?.remoteURL
    }
    
    /// 检查是否有规则处理该扩展名
    func hasRule(for fileExtension: String) -> Bool {
        let ext = fileExtension.lowercased()
        return rules.contains(where: { $0.fileExtensions.contains(ext) && $0.isEnabled })
    }
    
    /// 获取 URL 处理规则（如果启用）
    func getURLRule() -> FileHandlerRule? {
        return rules.first(where: { $0.ruleType == .url && $0.isEnabled })
    }
    
    /// 创建默认规则
    private func createDefaultRules() -> [FileHandlerRule] {
        return [
            FileHandlerRule(
                typeName: "URL",
                ruleType: .url,
                fileExtensions: [],
                remoteURL: "https://api.example.com/process/url",
                fileParameterName: "",  // URL 类型不需要文件参数
                customParameters: ["action": "shorten"],
                isEnabled: false
            ),
            FileHandlerRule(
                typeName: "PDF",
                ruleType: .file,
                fileExtensions: ["pdf"],
                remoteURL: "https://api.example.com/convert/pdf",
                fileParameterName: "file",
                customParameters: ["format": "pdf"],
                isEnabled: false
            ),
            FileHandlerRule(
                typeName: "WORD",
                ruleType: .file,
                fileExtensions: ["doc", "docx"],
                remoteURL: "https://api.example.com/convert/word",
                fileParameterName: "file",
                customParameters: ["target": "pdf"],
                isEnabled: false
            ),
            FileHandlerRule(
                typeName: "EXCEL",
                ruleType: .file,
                fileExtensions: ["xls", "xlsx"],
                remoteURL: "https://api.example.com/convert/excel",
                fileParameterName: "file",
                customParameters: ["sheet": "0"],
                isEnabled: false
            )
        ]
    }
    
    /// 重置为默认规则
    func resetToDefaults() {
        rules = createDefaultRules()
        saveRules()
    }
}

/// App Group 配置（复用）
private enum AppGroupConfig {
    static let identifier = "group.cc.raoqu.transany"
    nonisolated(unsafe) static let sharedDefaults: UserDefaults? = UserDefaults(suiteName: identifier)
}
