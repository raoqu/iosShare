import Foundation
import UIKit

/// App Group 配置
private enum AppGroupConfig {
    static let identifier = "group.cc.raoqu.transany"
    static let sharedItemsKey = "SharedItems"
    
    static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: identifier)
    }
}

/// 分享内容项模型
struct SharedItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let contentType: SharedContentType
    let content: String // 可以是 URL 字符串、文本内容等
    let timestamp: Date
    let thumbnailData: Data? // 可选的缩略图
    
    init(id: UUID = UUID(), title: String, contentType: SharedContentType, content: String, timestamp: Date = Date(), thumbnailData: Data? = nil) {
        self.id = id
        self.title = title
        self.contentType = contentType
        self.content = content
        self.timestamp = timestamp
        self.thumbnailData = thumbnailData
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

/// 分享内容类型
enum SharedContentType: String, Codable {
    case url = "URL"
    case image = "图片"
    case text = "文本"
    case pdf = "PDF"
    case document = "文档"
    case video = "视频"
    
    var icon: String {
        switch self {
        case .url: return "link.circle.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        case .pdf: return "doc.fill"
        case .document: return "folder.fill"
        case .video: return "video.fill"
        }
    }
    
    var color: String {
        switch self {
        case .url: return "blue"
        case .image: return "green"
        case .text: return "purple"
        case .pdf: return "red"
        case .document: return "orange"
        case .video: return "pink"
        }
    }
}

/// 分享内容存储管理器
@MainActor
class SharedItemsManager: ObservableObject {
    @Published var items: [SharedItem] = []
    
    private let userDefaultsKey = AppGroupConfig.sharedItemsKey
    private let defaults: UserDefaults
    
    static let shared = SharedItemsManager()
    
    private init() {
        // 使用 App Group 共享的 UserDefaults
        self.defaults = AppGroupConfig.sharedDefaults ?? .standard
        
        // 异步加载数据，避免阻塞主线程
        Task {
            await loadItems()
        }
    }
    
    func addItem(_ item: SharedItem) {
        items.insert(item, at: 0) // 新项目在最前面
        saveItems()
    }
    
    func deleteItem(at offsets: IndexSet) {
        // 获取要删除的项目
        let itemsToDelete = offsets.map { items[$0] }
        
        // 从 UI 列表中移除
        items.remove(atOffsets: offsets)
        
        // 从新格式存储中删除（包括文件）
        let storage = SharedStorageManager.shared
        for item in itemsToDelete {
            // 尝试使用 item.id 删除（如果是新格式）
            storage.deleteItem(id: item.id.uuidString)
        }
        
        // 保存更新后的列表到旧格式
        saveItems()
        
        print("🗑️ Deleted \(itemsToDelete.count) items")
    }
    
    func deleteItem(_ item: SharedItem) {
        // 从 UI 列表中移除
        items.removeAll { $0.id == item.id }
        
        // 从新格式存储中删除（包括文件）
        SharedStorageManager.shared.deleteItem(id: item.id.uuidString)
        
        // 保存更新后的列表到旧格式
        saveItems()
        
        print("🗑️ Deleted item: \(item.title)")
    }
    
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
    
    /// 刷新数据（从 UserDefaults 重新加载）
    func refresh() {
        Task {
            await loadItems()
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            defaults.set(encoded, forKey: userDefaultsKey)
            defaults.synchronize()
        }
    }
    
    private func loadItems() async {
        print("🔄 Loading shared items from UserDefaults...")
        
        // 首先尝试加载新格式（SharedItemModel）
        let storage = SharedStorageManager.shared
        let newFormatItems = storage.loadItems()
        
        if !newFormatItems.isEmpty {
            print("✅ Loaded \(newFormatItems.count) items (New Standard Format)")
            
            items = newFormatItems.compactMap { model -> SharedItem? in
                let contentType: SharedContentType
                switch model.contentType {
                case "photo": contentType = .image
                case "url": contentType = .url
                case "text": contentType = .text
                case "pdf": contentType = .pdf
                case "excel": contentType = .document
                case "video": contentType = .video
                default: contentType = .text
                }
                
                // 如果有文件路径，显示文件路径；否则显示文本内容
                let content = model.textContent ?? model.filePath ?? ""
                
                // 使用 SharedItemModel 的 id 创建 UUID（如果可能）
                let itemId: UUID
                if let uuid = UUID(uuidString: model.id) {
                    itemId = uuid
                } else {
                    // 如果 id 不是有效的 UUID，创建一个新的
                    itemId = UUID()
                    print("⚠️ Invalid UUID in model.id: \(model.id), creating new UUID")
                }
                
                return SharedItem(
                    id: itemId,
                    title: model.title,
                    contentType: contentType,
                    content: content,
                    timestamp: model.timestamp
                )
            }
            return
        }
        
        // 兼容旧格式：Try to load encoded SharedItem array
        if let data = defaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([SharedItem].self, from: data) {
            items = decoded
            print("✅ Loaded \(items.count) items (Legacy JSON format)")
            return
        }
        
        // 兼容旧格式：Try to load dictionary array from ShareViewController
        if let dictArray = defaults.array(forKey: userDefaultsKey) as? [[String: Any]] {
            print("📋 Found \(dictArray.count) items (Legacy Dictionary format)")
            
            items = dictArray.compactMap { dict -> SharedItem? in
                guard let title = dict["title"] as? String,
                      let content = dict["content"] as? String,
                      let typeString = dict["type"] as? String else {
                    return nil
                }
                
                let contentType: SharedContentType
                switch typeString {
                case "url": contentType = .url
                case "image", "photo": contentType = .image
                case "text": contentType = .text
                case "pdf": contentType = .pdf
                case "document", "excel": contentType = .document
                case "video": contentType = .video
                default: contentType = .text
                }
                
                let timestamp = dict["timestamp"] as? Date ?? Date()
                
                return SharedItem(
                    title: title,
                    contentType: contentType,
                    content: content,
                    timestamp: timestamp
                )
            }
            
            print("✅ Converted to \(items.count) SharedItem objects")
            return
        }
        
        // If no data, keep empty list
        items = []
        print("ℹ️ No items found, starting with empty list")
    }
    
    private func createSampleData() -> [SharedItem] {
        return [
            SharedItem(
                title: "Apple iPad Air 2",
                contentType: .url,
                content: "http://apple.com/ipad-air-2/",
                timestamp: Date()
            ),
            SharedItem(
                title: "欢迎使用 TransAny",
                contentType: .text,
                content: "这是一个示例文本，展示如何分享文本内容到 TransAny。",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            SharedItem(
                title: "产品文档.pdf",
                contentType: .pdf,
                content: "https://example.com/document.pdf",
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
    }
}
