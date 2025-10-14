import Foundation

/// 分享内容统一存储格式
struct SharedItemModel: Codable, Identifiable {
    let id: String  // UUID 字符串
    let title: String  // 用户输入的描述
    let contentType: String  // photo, pdf, excel, text, url, video, etc.
    let filePath: String?  // 文件相对路径（存储在共享容器中）
    let textContent: String?  // 文本内容（如果是文本类型）
    let metadata: [String: String]  // 扩展参数（JSON 兼容）
    let timestamp: Date  // 创建时间
    
    /// 初始化方法
    init(
        id: String = UUID().uuidString,
        title: String,
        contentType: String,
        filePath: String? = nil,
        textContent: String? = nil,
        metadata: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.contentType = contentType
        self.filePath = filePath
        self.textContent = textContent
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

/// 共享存储管理器
final class SharedStorageManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = SharedStorageManager()
    
    private let appGroupIdentifier = "group.cc.raoqu.transany"
    private let sharedItemsKey = "SharedItemsV2"  // 新版本
    private let filesDirectoryName = "SharedFiles"
    
    private init() {}
    
    // MARK: - 文件管理
    
    /// 获取共享文件容器目录
    var sharedFilesDirectory: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("⚠️ Failed to get container URL for App Group")
            return nil
        }
        
        let filesDir = containerURL.appendingPathComponent(filesDirectoryName)
        
        // 确保目录存在
        if !FileManager.default.fileExists(atPath: filesDir.path) {
            try? FileManager.default.createDirectory(
                at: filesDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        return filesDir
    }
    
    /// 保存文件到共享容器
    /// - Parameters:
    ///   - data: 文件数据
    ///   - filename: 文件名
    /// - Returns: 相对路径（用于存储）
    func saveFile(data: Data, filename: String) -> String? {
        guard let filesDir = sharedFilesDirectory else { return nil }
        
        let fileURL = filesDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Saved file: \(filename)")
            return filename  // 返回相对路径
        } catch {
            print("❌ Failed to save file: \(error)")
            return nil
        }
    }
    
    /// 获取文件完整 URL
    func getFileURL(relativePath: String) -> URL? {
        guard let filesDir = sharedFilesDirectory else { return nil }
        return filesDir.appendingPathComponent(relativePath)
    }
    
    /// 删除文件
    func deleteFile(relativePath: String) {
        guard let fileURL = getFileURL(relativePath: relativePath) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - 数据存储
    
    /// 获取共享的 UserDefaults
    var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// 保存单个项目
    func saveItem(_ item: SharedItemModel) {
        var items = loadItems()
        items.insert(item, at: 0)  // 最新的在最前面
        saveItems(items)
    }
    
    /// 保存多个项目
    func saveItems(_ items: [SharedItemModel]) {
        guard let defaults = sharedDefaults else {
            print("⚠️ Failed to get shared UserDefaults")
            return
        }
        
        // 限制最多 100 条
        let limitedItems = Array(items.prefix(100))
        
        if let encoded = try? JSONEncoder().encode(limitedItems) {
            defaults.set(encoded, forKey: sharedItemsKey)
            defaults.synchronize()
            print("✅ Saved \(limitedItems.count) items")
        }
    }
    
    /// 加载所有项目
    func loadItems() -> [SharedItemModel] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: sharedItemsKey),
              let items = try? JSONDecoder().decode([SharedItemModel].self, from: data) else {
            return []
        }
        return items
    }
    
    /// 删除项目
    func deleteItem(id: String) {
        var items = loadItems()
        
        // 删除关联的文件
        if let item = items.first(where: { $0.id == id }),
           let filePath = item.filePath {
            deleteFile(relativePath: filePath)
        }
        
        items.removeAll { $0.id == id }
        saveItems(items)
    }
    
    /// 清空所有项目
    func clearAll() {
        // 删除所有文件
        if let filesDir = sharedFilesDirectory {
            try? FileManager.default.removeItem(at: filesDir)
        }
        
        // 清空数据
        sharedDefaults?.removeObject(forKey: sharedItemsKey)
        sharedDefaults?.synchronize()
    }
}

// MARK: - 扩展方法：创建不同类型的存储项

extension SharedItemModel {
    
    /// 创建图片项目
    static func createPhotoItem(
        title: String,
        imageData: Data,
        metadata: [String: String] = [:]
    ) -> SharedItemModel? {
        let filename = "\(UUID().uuidString).jpg"
        guard let filePath = SharedStorageManager.shared.saveFile(data: imageData, filename: filename) else {
            return nil
        }
        
        return SharedItemModel(
            title: title,
            contentType: "photo",
            filePath: filePath,
            textContent: nil,
            metadata: metadata
        )
    }
    
    /// 创建 PDF 项目
    static func createPDFItem(
        title: String,
        pdfData: Data,
        metadata: [String: String] = [:]
    ) -> SharedItemModel? {
        let filename = "\(UUID().uuidString).pdf"
        guard let filePath = SharedStorageManager.shared.saveFile(data: pdfData, filename: filename) else {
            return nil
        }
        
        return SharedItemModel(
            title: title,
            contentType: "pdf",
            filePath: filePath,
            textContent: nil,
            metadata: metadata
        )
    }
    
    /// 创建 Excel 项目
    static func createExcelItem(
        title: String,
        excelData: Data,
        metadata: [String: String] = [:]
    ) -> SharedItemModel? {
        let filename = "\(UUID().uuidString).xlsx"
        guard let filePath = SharedStorageManager.shared.saveFile(data: excelData, filename: filename) else {
            return nil
        }
        
        return SharedItemModel(
            title: title,
            contentType: "excel",
            filePath: filePath,
            textContent: nil,
            metadata: metadata
        )
    }
    
    /// 创建文本项目
    static func createTextItem(
        title: String,
        text: String,
        metadata: [String: String] = [:]
    ) -> SharedItemModel {
        return SharedItemModel(
            title: title,
            contentType: "text",
            filePath: nil,
            textContent: text,
            metadata: metadata
        )
    }
    
    /// 创建 URL 项目
    static func createURLItem(
        title: String,
        url: String,
        metadata: [String: String] = [:]
    ) -> SharedItemModel {
        return SharedItemModel(
            title: title,
            contentType: "url",
            filePath: nil,
            textContent: url,
            metadata: metadata
        )
    }
    
    /// 创建视频项目
    static func createVideoItem(
        title: String,
        videoData: Data,
        metadata: [String: String] = [:]
    ) -> SharedItemModel? {
        let filename = "\(UUID().uuidString).mp4"
        guard let filePath = SharedStorageManager.shared.saveFile(data: videoData, filename: filename) else {
            return nil
        }
        
        return SharedItemModel(
            title: title,
            contentType: "video",
            filePath: filePath,
            textContent: nil,
            metadata: metadata
        )
    }
}

// MARK: - 辅助方法

extension SharedItemModel {
    
    /// 获取文件的完整 URL（如果有）
    var fileURL: URL? {
        guard let filePath = filePath else { return nil }
        return SharedStorageManager.shared.getFileURL(relativePath: filePath)
    }
    
    /// 获取显示用的图标名称
    var iconName: String {
        switch contentType {
        case "photo": return "photo.fill"
        case "pdf": return "doc.fill"
        case "excel": return "tablecells.fill"
        case "text": return "doc.text.fill"
        case "url": return "link.circle.fill"
        case "video": return "video.fill"
        default: return "doc.fill"
        }
    }
    
    /// 获取显示用的类型标签
    var typeLabel: String {
        switch contentType {
        case "photo": return "图片"
        case "pdf": return "PDF"
        case "excel": return "Excel"
        case "text": return "文本"
        case "url": return "链接"
        case "video": return "视频"
        default: return "文件"
        }
    }
    
    /// 获取预览文本
    var previewText: String {
        if let text = textContent, !text.isEmpty {
            return text.count > 100 ? String(text.prefix(100)) + "..." : text
        }
        
        if let filePath = filePath {
            return filePath
        }
        
        return title
    }
}
