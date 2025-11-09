import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI 分享视图
struct ShareView: View {
    @StateObject private var viewModel = ShareViewModel()
    @Environment(\.extensionContext) private var extensionContext
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isProcessing {
                    // 处理中状态
                    ProgressView("正在处理...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if viewModel.hasUnsupportedItems {
                    // 有不支持的文件
                    unsupportedView
                } else {
                    // 预览区域
                    previewSection
                    
                    // 规则选择（如果有多个匹配）
                    if viewModel.hasMultipleRuleMatches {
                        ruleSelectionSection
                    }
                    
                    // 输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("添加标题")
                            .font(.headline)
                        
                        TextField("输入标题（可选）", text: $viewModel.userTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.done)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .padding(.top)
            .navigationTitle("分享到 TransAny")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.cancel(extensionContext: extensionContext)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.hasUnsupportedItems {
                        Button("发布") {
                            viewModel.post(extensionContext: extensionContext)
                        }
                        .disabled(viewModel.isProcessing || !viewModel.canPost)
                    }
                }
            }
            .task {
                await viewModel.loadSharedContent(from: extensionContext)
            }
        }
    }
    
    @ViewBuilder
    private var previewSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.items) { item in
                HStack(spacing: 12) {
                    // 类型图标
                    Image(systemName: item.typeIcon)
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    // 内容信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.typeLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(item.preview)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var unsupportedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("不支持的文件类型")
                .font(.headline)
            
            Text("当前文件类型未在设置中配置处理规则，无法分享。\n\n请在应用设置中添加对应的文件处理规则。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    private var ruleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择处理规则")
                .font(.headline)
            
            Text("检测到多个匹配的处理规则，请选择一个：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(viewModel.matchedRules, id: \.id) { rule in
                Button(action: {
                    viewModel.selectRule(rule)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.typeName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(rule.remoteURL)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if viewModel.selectedRule?.id == rule.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.selectedRule?.id == rule.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

/// 分享项目模型
struct ShareItemModel: Identifiable {
    let id = UUID()
    var type: String  // photo, pdf, excel, text, url, video
    var content: String
    var title: String
    var imageData: Data?  // 图片数据
    var fileData: Data?  // 文件数据（PDF、Excel等）
    var metadata: [String: String] = [:]  // 扩展参数
    
    var typeIcon: String {
        switch type {
        case "photo": return "photo.fill"
        case "pdf": return "doc.fill"
        case "excel": return "tablecells.fill"
        case "url": return "link.circle.fill"
        case "text": return "doc.text.fill"
        case "video": return "video.fill"
        default: return "doc.fill"
        }
    }
    
    var typeLabel: String {
        switch type {
        case "photo": return "图片"
        case "pdf": return "PDF"
        case "excel": return "Excel"
        case "url": return "网页链接"
        case "text": return "文本"
        case "video": return "视频"
        default: return "文件"
        }
    }
    
    var preview: String {
        if content.isEmpty {
            return title.isEmpty ? "正在加载..." : title
        }
        return content.count > 100 ? String(content.prefix(100)) + "..." : content
    }
}

/// 分享视图模型
@MainActor
class ShareViewModel: ObservableObject {
    @Published var items: [ShareItemModel] = []
    @Published var userTitle: String = ""
    @Published var isProcessing: Bool = false
    @Published var hasUnsupportedItems: Bool = false
    @Published var matchedRules: [FileHandlerRule] = []
    @Published var selectedRule: FileHandlerRule?
    
    private let appGroupIdentifier = "group.cc.raoqu.transany"
    private let sharedItemsKey = "SharedItems"
    private let settingsManager = FileHandlerSettingsManager.shared
    
    var hasMultipleRuleMatches: Bool {
        return matchedRules.count > 1
    }
    
    var canPost: Bool {
        if hasUnsupportedItems {
            return false
        }
        if hasMultipleRuleMatches && selectedRule == nil {
            return false
        }
        return true
    }
    
    func selectRule(_ rule: FileHandlerRule) {
        selectedRule = rule
    }
    
    /// 加载分享的内容
    func loadSharedContent(from extensionContext: NSExtensionContext?) async {
        guard let extensionContext = extensionContext else { return }
        
        isProcessing = true
        hasUnsupportedItems = false
        matchedRules = []
        selectedRule = nil
        defer { isProcessing = false }
        
        for extensionItem in extensionContext.inputItems as? [NSExtensionItem] ?? [] {
            for provider in extensionItem.attachments ?? [] {
                // 尝试作为文件处理
                if let fileURL = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) as? URL {
                    await handleFile(fileURL: fileURL)
                }
                // 尝试作为URL处理
                else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                        let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) as? URL,
                        (url.scheme == "http" || url.scheme == "https") {
                    await handleURL(url: url)
                }
                // 尝试作为文本处理
                else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                        let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) as? String {
                    await handleText(text: text)
                }
            }
        }
        
        // 特殊处理：当同时存在1项文本和1个URL时，合并为一个URL项
        mergeTextAndURLIfNeeded()
        
        // 设置默认标题（使用第一个项目的标题）
        if let firstItem = items.first, userTitle.isEmpty {
            userTitle = firstItem.title
        }
    }
    
    /// 处理文件
    private func handleFile(fileURL: URL) async {
        let fileExtension = fileURL.pathExtension.lowercased()
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        
        // 查找匹配的规则
        let allRules = settingsManager.rules.filter { $0.ruleType == .file && $0.isEnabled }
        let matched = allRules.filter { $0.fileExtensions.contains(fileExtension) }
        
        if matched.isEmpty {
            // 没有匹配的规则
            hasUnsupportedItems = true
            print("❌ 不支持的文件类型: .\(fileExtension)")
            return
        }
        
        // 保存匹配的规则
        if matchedRules.isEmpty {
            matchedRules = matched
            selectedRule = matched.first // 默认选择第一个
        }
        
        // 读取文件数据
        guard let data = try? Data(contentsOf: fileURL) else {
            hasUnsupportedItems = true
            print("❌ 无法读取文件: \(fileURL.path)")
            return
        }
        
        // 创建项目
        var tempItem = ShareItemModel(type: "file", content: fileName, title: fileName)
        tempItem.fileData = data
        tempItem.metadata = [
            "extension": fileExtension,
            "size": "\(data.count)",
            "original_filename": fileURL.lastPathComponent
        ]
        
        items.append(tempItem)
        print("✅ 检测到文件: \(fileName).\(fileExtension), 匹配 \(matched.count) 个规则")
    }
    
    /// 处理URL
    private func handleURL(url: URL) async {
        // 查找URL处理规则
        let urlRule = settingsManager.rules.first(where: { $0.ruleType == .url && $0.isEnabled })
        
        if urlRule == nil {
            hasUnsupportedItems = true
            print("❌ 未配置URL处理规则")
            return
        }
        
        if matchedRules.isEmpty {
            matchedRules = [urlRule!]
            selectedRule = urlRule
        }
        
        var tempItem = ShareItemModel(type: "url", content: url.absoluteString, title: url.host ?? url.absoluteString)
        tempItem.metadata = [
            "host": url.host ?? "",
            "scheme": url.scheme ?? ""
        ]
        
        items.append(tempItem)
        print("✅ 检测到URL: \(url.absoluteString)")
    }
    
    /// 处理纯文本
    private func handleText(text: String) async {
        // 检测是否为URL
        if text.starts(with: "http://") || text.starts(with: "https://"),
           let url = URL(string: text) {
            await handleURL(url: url)
            return
        }
        
        // 纯文本暂不需要规则匹配，直接保存
        var tempItem = ShareItemModel(type: "text", content: text, title: "文本")
        tempItem.metadata = [
            "length": "\(text.count)"
        ]
        
        items.append(tempItem)
        print("✅ 检测到文本: \(text.prefix(50))...")
    }
    
    /// 特殊处理：合并文本和URL
    private func mergeTextAndURLIfNeeded() {
        // 只处理恰好有2项的情况
        guard items.count == 2 else { return }
        
        // 查找文本和URL项
        let textItem = items.first { $0.type == "text" }
        let urlItem = items.first { $0.type == "url" }
        
        // 确保恰好有1个文本和1个URL
        guard let text = textItem, let url = urlItem else { return }
        
        print("🔄 检测到文本+URL组合，合并为URL项")
        print("   - 文本: \(text.content.prefix(30))...")
        print("   - URL: \(url.content)")
        
        // 创建新的URL项，使用文本作为标题
        var mergedItem = ShareItemModel(
            type: "url",
            content: url.content,
            title: text.content
        )
        mergedItem.metadata = url.metadata
        mergedItem.metadata["merged_from_text"] = "true"
        
        // 替换原来的两项
        items = [mergedItem]
        
        print("✅ 已合并为URL项，标题: \(text.content.prefix(30))...")
    }
    
    /// 发布分享
    func post(extensionContext: NSExtensionContext?) {
        guard let extensionContext = extensionContext else { return }
        
        // 保存数据
        saveSharedItems()
        
        // 打开主应用
        if let url = URL(string: "transany://") {
            extensionContext.open(url) { success in
                print(success ? "✅ Opened main app" : "⚠️ Failed to open main app")
            }
        }
        
        // 完成扩展
        extensionContext.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    /// 取消分享
    func cancel(extensionContext: NSExtensionContext?) {
        guard let extensionContext = extensionContext else { return }
        extensionContext.cancelRequest(withError: NSError(domain: "TransAnyShareExtension", code: -1, userInfo: nil))
    }
    
    /// 保存分享项目到 App Group（使用新标准格式）
    private func saveSharedItems() {
        let storage = SharedStorageManager.shared
        
        print("📋 Saving items using rule-based format...")
        print("📋 Selected rule: \(selectedRule?.typeName ?? "none")")
        
        for item in items {
            // 确定标题
            let finalTitle = !userTitle.isEmpty ? userTitle : (item.title.isEmpty ? "未命名" : item.title)
            
            var savedItem: SharedItemModel?
            var metadata = item.metadata
            
            // 添加规则信息到元数据
            if let rule = selectedRule {
                metadata["handler_rule_id"] = rule.id.uuidString
                metadata["handler_rule_type"] = rule.typeName
                metadata["handler_url"] = rule.remoteURL
            }
            
            // 根据类型保存
            switch item.type {
            case "file":
                // 通用文件保存
                if let fileData = item.fileData,
                   let ext = metadata["extension"],
                   let filename = metadata["original_filename"] {
                    let savedFilename = "\(UUID().uuidString).\(ext)"
                    if let filePath = storage.saveFile(data: fileData, filename: savedFilename) {
                        // 使用通用contentType或根据扩展名判断
                        let contentType: String
                        switch ext {
                        case "pdf": contentType = "pdf"
                        case "jpg", "jpeg", "png", "gif": contentType = "photo"
                        case "xls", "xlsx": contentType = "excel"
                        case "mp4", "mov": contentType = "video"
                        default: contentType = "file"
                        }
                        
                        savedItem = SharedItemModel(
                            title: finalTitle,
                            contentType: contentType,
                            filePath: filePath,
                            textContent: nil,
                            metadata: metadata
                        )
                    }
                }
                
            case "text":
                savedItem = SharedItemModel.createTextItem(
                    title: finalTitle,
                    text: item.content,
                    metadata: metadata
                )
                
            case "url":
                savedItem = SharedItemModel.createURLItem(
                    title: finalTitle,
                    url: item.content,
                    metadata: metadata
                )
                
            default:
                savedItem = SharedItemModel.createTextItem(
                    title: finalTitle,
                    text: item.content,
                    metadata: item.metadata
                )
            }
            
            if let savedItem = savedItem {
                storage.saveItem(savedItem)
                print("✅ Saved: [\(savedItem.contentType)] \(savedItem.title)")
            } else {
                print("⚠️ Failed to save item: [\(item.type)] \(finalTitle)")
            }
        }
        
        print("🎉 All items saved successfully!")
    }
}

/// Extension Context Environment Key
private struct ExtensionContextKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: NSExtensionContext? = nil
}

extension EnvironmentValues {
    var extensionContext: NSExtensionContext? {
        get { self[ExtensionContextKey.self] }
        set { self[ExtensionContextKey.self] = newValue }
    }
}
