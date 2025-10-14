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
                } else {
                    // 预览区域
                    previewSection
                    
                    // 输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("添加描述")
                            .font(.headline)
                        
                        TextField("输入描述（可选）", text: $viewModel.userComment)
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
                    Button("发布") {
                        viewModel.post(extensionContext: extensionContext)
                    }
                    .disabled(viewModel.isProcessing)
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
}

/// 分享项目模型
struct ShareItemModel: Identifiable {
    let id = UUID()
    var type: String
    var content: String
    var title: String
    
    var typeIcon: String {
        switch type {
        case "image": return "photo.fill"
        case "url": return "link.circle.fill"
        case "text": return "doc.text.fill"
        default: return "doc.fill"
        }
    }
    
    var typeLabel: String {
        switch type {
        case "image": return "图片"
        case "url": return "网页链接"
        case "text": return "文本"
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
    @Published var userComment: String = ""
    @Published var isProcessing: Bool = false
    
    private let appGroupIdentifier = "group.cc.raoqu.transany"
    private let sharedItemsKey = "SharedItems"
    
    /// 加载分享的内容
    func loadSharedContent(from extensionContext: NSExtensionContext?) async {
        guard let extensionContext = extensionContext else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        for extensionItem in extensionContext.inputItems as? [NSExtensionItem] ?? [] {
            // 创建临时项目
            var tempItem = ShareItemModel(type: "text", content: "", title: "")
            
            // 处理附件
            for provider in extensionItem.attachments ?? [] {
                // 图片
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let image = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) as? UIImage {
                        tempItem.type = "image"
                        tempItem.content = "图片 \(Int(image.size.width))×\(Int(image.size.height))"
                        tempItem.title = "图片"
                    }
                }
                // URL
                else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) as? URL {
                        tempItem.type = "url"
                        tempItem.content = url.absoluteString
                        tempItem.title = url.host ?? url.absoluteString
                    }
                }
                // 纯文本
                else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) as? String {
                        tempItem.type = "text"
                        tempItem.content = text
                        tempItem.title = "文本"
                    }
                }
            }
            
            items.append(tempItem)
        }
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
    
    /// 保存分享项目到 App Group
    private func saveSharedItems() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("⚠️ Failed to create UserDefaults with App Group suite")
            return
        }
        
        // 加载现有项目列表
        var existingItems = defaults.array(forKey: sharedItemsKey) as? [[String: Any]] ?? []
        let originalCount = existingItems.count
        
        print("📋 Loading existing items: \(originalCount) items")
        
        // 添加新项目到列表开头（最新的在最前面）
        for item in items {
            var itemDict: [String: Any] = [
                "type": item.type,
                "content": item.content,
                "timestamp": Date()
            ]
            
            // 使用用户输入的描述，否则使用默认标题
            if !userComment.isEmpty {
                itemDict["title"] = userComment
            } else if !item.title.isEmpty {
                itemDict["title"] = item.title
            } else {
                itemDict["title"] = "未命名"
            }
            
            existingItems.insert(itemDict, at: 0)
            print("➕ Added: [\(item.type)] \(itemDict["title"] ?? "未命名")")
        }
        
        // 限制列表大小，保留最新的 100 条
        let maxItems = 100
        if existingItems.count > maxItems {
            existingItems = Array(existingItems.prefix(maxItems))
            print("✂️ Trimmed to \(maxItems) items")
        }
        
        // 保存回 UserDefaults
        defaults.set(existingItems, forKey: sharedItemsKey)
        defaults.synchronize()
        
        print("✅ Saved successfully! Total items: \(existingItems.count) (was: \(originalCount))")
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
