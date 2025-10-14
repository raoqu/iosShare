import Foundation
import UIKit

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
    
    private let userDefaultsKey = "SharedItems"
    
    static let shared = SharedItemsManager()
    
    private init() {
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
        items.remove(atOffsets: offsets)
        saveItems()
    }
    
    func deleteItem(_ item: SharedItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadItems() async {
        // Try to load encoded SharedItem array first
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([SharedItem].self, from: data) {
            items = decoded
            return
        }
        
        // Try to load dictionary array from ShareViewController
        if let dictArray = UserDefaults.standard.array(forKey: userDefaultsKey) as? [[String: Any]] {
            items = dictArray.compactMap { dict in
                guard let title = dict["title"] as? String,
                      let content = dict["content"] as? String,
                      let typeString = dict["type"] as? String else {
                    return nil
                }
                
                let contentType: SharedContentType
                switch typeString {
                case "url": contentType = .url
                case "image": contentType = .image
                case "text": contentType = .text
                case "pdf": contentType = .pdf
                case "document": contentType = .document
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
            
            // Save in the new format
            saveItems()
            return
        }
        
        // If no data, don't create sample data on first launch
        // Keep empty list for better performance
        items = []
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
