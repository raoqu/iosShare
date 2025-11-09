import Foundation

/// 处理规则类型
public enum HandlerRuleType: String, Codable {
    case file       // 需要上传文件
    case url        // 只发送 URL，不上传文件
}

/// 文件处理规则
public struct FileHandlerRule: Identifiable, Codable {
    public let id: UUID
    public var typeName: String            // 类型名称，如 "EXCEL", "PDF", "URL"
    public var ruleType: HandlerRuleType   // 规则类型：文件上传或URL处理
    public var fileExtensions: [String]    // 文件扩展名列表，如 ["xls", "xlsx"]（URL类型时可为空）
    public var remoteURL: String           // 远程处理 URL
    public var fileParameterName: String   // 文件参数名称，默认 "file"（仅文件类型使用）
    public var customParameters: [String: String]  // 自定义参数键值对
    public var isEnabled: Bool             // 是否启用
    
    public init(
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
        self.fileExtensions = fileExtensions
        self.remoteURL = remoteURL
        self.fileParameterName = fileParameterName
        self.customParameters = customParameters
        self.isEnabled = isEnabled
    }
}

/// 文件处理规则管理器（使用单例模式）
@MainActor
public class FileHandlerSettingsManager: ObservableObject {
    public static let shared = FileHandlerSettingsManager()
    
    private let appGroupIdentifier = "group.cc.raoqu.transany"
    private let rulesKey = "FileHandlerRules"
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    @Published public var rules: [FileHandlerRule] = []
    
    private init() {
        // 加载已保存的规则
        let loaded = loadRules()
        if loaded.isEmpty {
            // 如果没有保存的规则，创建并保存默认规则
            let defaults = createDefaultRules()
            self.rules = defaults
            saveRules(defaults)
        } else {
            self.rules = loaded
        }
    }
    
    /// 加载规则
    private func loadRules() -> [FileHandlerRule] {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: rulesKey),
              let decoded = try? JSONDecoder().decode([FileHandlerRule].self, from: data) else {
            return []
        }
        return decoded
    }
    
    /// 保存规则
    private func saveRules(_ rules: [FileHandlerRule]) {
        guard let defaults = userDefaults,
              let encoded = try? JSONEncoder().encode(rules) else {
            print("❌ Failed to save rules")
            return
        }
        defaults.set(encoded, forKey: rulesKey)
        print("✅ Saved \(rules.count) rules")
    }
    
    /// 添加规则
    public func addRule(_ rule: FileHandlerRule) {
        rules.append(rule)
        saveRules(rules)
    }
    
    /// 更新规则
    public func updateRule(_ rule: FileHandlerRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            saveRules(rules)
        }
    }
    
    /// 删除规则（通过 UUID）
    public func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        saveRules(rules)
    }
    
    /// 删除规则（通过 IndexSet，用于 List 的 onDelete）
    public func deleteRule(at offsets: IndexSet) {
        rules.remove(atOffsets: offsets)
        saveRules(rules)
    }
    
    /// 重置为默认设置
    public func resetToDefaults() {
        rules = createDefaultRules()
        saveRules(rules)
    }
    
    /// 根据文件扩展名获取规则
    public func getRule(for fileExtension: String) -> FileHandlerRule? {
        return rules.first { rule in
            rule.ruleType == .file && 
            rule.isEnabled && 
            rule.fileExtensions.contains(fileExtension.lowercased())
        }
    }
    
    /// 获取URL处理规则
    public func getURLRule() -> FileHandlerRule? {
        return rules.first { $0.ruleType == .url && $0.isEnabled }
    }
    
    /// 创建默认规则
    private func createDefaultRules() -> [FileHandlerRule] {
        return [
            FileHandlerRule(
                typeName: "EXCEL",
                ruleType: .file,
                fileExtensions: ["xls", "xlsx"],
                remoteURL: "https://your-api.com/upload/excel",
                fileParameterName: "file",
                customParameters: ["api_key": "your_key"]
            ),
            FileHandlerRule(
                typeName: "PDF",
                ruleType: .file,
                fileExtensions: ["pdf"],
                remoteURL: "https://your-api.com/upload/pdf",
                fileParameterName: "file"
            ),
            FileHandlerRule(
                typeName: "URL",
                ruleType: .url,
                fileExtensions: [],
                remoteURL: "https://your-api.com/process/url",
                fileParameterName: ""
            )
        ]
    }
}
