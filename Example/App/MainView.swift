import SwiftUI

/// TransAny 主界面
struct MainView: View {
    @StateObject private var manager = SharedItemsManager.shared
    @State private var showingDeleteAlert = false
    @State private var selectedItem: SharedItem?
    @State private var showingAddMenu = false
    @State private var showingTextInput = false
    @State private var showingPhotoPicker = false
    @State private var showingDocumentPicker = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            Group {
                if manager.items.isEmpty {
                    // 空状态视图
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 分享内容列表
                    List {
                        ForEach(manager.items) { item in
                            SharedItemRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = item
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            manager.deleteItem(item)
                                        }
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                    // 为右上角菜单按钮预留空间
                    .safeAreaInset(edge: .top, spacing: 0) {
                        HStack {
                            Spacer()
                            if !manager.items.isEmpty {
                                Menu {
                                    Button(action: {
                                        showingSettings = true
                                    }) {
                                        Label("设置", systemImage: "gear")
                                    }
                                    
                                    Divider()
                                    
                                    Button(action: {
                                        showingDeleteAlert = true
                                    }) {
                                        Label("清空所有", systemImage: "trash")
                                    }
                                    
                                    Button(action: {
                                        addTestItem()
                                    }) {
                                        Label("添加测试", systemImage: "plus.circle")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(Color(.systemBackground))
                                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                                        )
                                }
                                .padding(.trailing, 16)
                                .padding(.top, 8)
                            }
                        }
                        .frame(height: manager.items.isEmpty ? 0 : 50)
                        .background(Color(.systemBackground))
                    }
                }
            }
            // .navigationTitle("TransAny")
            // .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(true)  // 隐藏导航栏，移除占用空间
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
            .alert("清空所有内容", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    withAnimation {
                        manager.clearAll()
                    }
                }
            } message: {
                Text("确定要删除所有分享内容吗？此操作无法撤销。")
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
            // 底部居中的"+"按钮
            .overlay(alignment: .bottom) {
                addButton
            }
            // 添加内容菜单
            .confirmationDialog("添加内容", isPresented: $showingAddMenu) {
                Button("拍照或选择照片") {
                    showingPhotoPicker = true
                }
                Button("选择文件") {
                    showingDocumentPicker = true
                }
                Button("输入文本") {
                    showingTextInput = true
                }
                Button("取消", role: .cancel) { }
            }
            // 文本输入视图
            .sheet(isPresented: $showingTextInput) {
                TextInputView { title, content in
                    saveText(title: title, content: content)
                }
            }
            // 照片选择器
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView { images in
                    savePhotos(images)
                }
            }
            // 文件选择器
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView { urls in
                    saveDocuments(urls)
                }
            }
            // 设置视图
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // 视图出现时刷新数据
            manager.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 应用从后台回到前台时刷新数据
            manager.refresh()
        }
    }
    
    // 底部"+"按钮
    private var addButton: some View {
        Button(action: {
            showingAddMenu = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
        }
        .padding(.bottom, 10)
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("暂无分享内容")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("从其他应用分享内容到 TransAny\n内容将显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                addTestItem()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加测试内容")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.top, 10)
        }
    }
    
    // 添加测试数据
    private func addTestItem() {
        let testItems: [SharedItem] = [
            SharedItem(
                title: "GitHub - SwiftUI",
                contentType: .url,
                content: "https://github.com/topics/swiftui"
            ),
            SharedItem(
                title: "新的想法和创意",
                contentType: .text,
                content: "记录一些灵感：使用 SwiftUI 构建更好的用户体验，关注动画和交互细节。"
            ),
            SharedItem(
                title: "项目文档.pdf",
                contentType: .pdf,
                content: "https://example.com/project-doc.pdf"
            )
        ]
        
        let randomItem = testItems.randomElement()!
        withAnimation {
            manager.addItem(randomItem)
        }
    }
    
    // 保存文本
    private func saveText(title: String, content: String) {
        guard !content.isEmpty else { return }
        
        var metadata: [String: String] = [
            "source": "app_input",
            "length": "\(content.count)"
        ]
        
        // 检测是否为 URL
        let isURL = content.starts(with: "http://") || content.starts(with: "https://")
        
        if isURL {
            // 检查是否有启用的 URL 处理规则
            let settingsManager = FileHandlerSettingsManager.shared
            if let rule = settingsManager.getURLRule() {
                print("🌐 Found URL handler rule: [\(rule.typeName)] \(rule.remoteURL)")
                
                // 发送 URL 到远程处理器
                Task {
                    await sendURLToRemoteHandler(
                        rule: rule,
                        urlString: content
                    )
                }
                
                // 添加处理标记到元数据
                metadata["handler_url"] = rule.remoteURL
                metadata["handler_type"] = rule.typeName
                metadata["handler_status"] = "pending"
                metadata["is_url"] = "true"
            }
        }
        
        let item = SharedItemModel.createTextItem(
            title: title.isEmpty ? String(content.prefix(30)) : title,
            text: content,
            metadata: metadata
        )
        
        SharedStorageManager.shared.saveItem(item)
        
        withAnimation {
            manager.refresh()
        }
        
        print("✅ Saved text: \(content.prefix(50))...")
    }
    
    // 保存照片
    private func savePhotos(_ images: [UIImage]) {
        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            
            let metadata: [String: String] = [
                "source": "app_picker",
                "width": "\(Int(image.size.width))",
                "height": "\(Int(image.size.height))",
                "format": "jpeg"
            ]
            
            if let item = SharedItemModel.createPhotoItem(
                title: "照片 \(Date().formatted(date: .numeric, time: .shortened))",
                imageData: imageData,
                metadata: metadata
            ) {
                SharedStorageManager.shared.saveItem(item)
                print("✅ Saved photo: \(item.title)")
            }
        }
        
        withAnimation {
            manager.refresh()
        }
    }
    
    // 保存文档
    private func saveDocuments(_ urls: [URL]) {
        var successCount = 0
        var failCount = 0
        
        print("📄 Processing \(urls.count) file(s)...")
        
        for url in urls {
            let filename = url.lastPathComponent
            print("📄 Processing file: \(filename)")
            print("📍 File URL: \(url.path)")
            
            // DocumentPickerViewController with asCopy:true 会将文件复制到临时目录
            // 这些文件不需要安全范围资源访问
            // 只在必要时尝试访问安全范围资源
            let needsSecurityScope = !url.path.contains("tmp") && !url.path.contains("Inbox")
            var didStartAccessing = false
            
            if needsSecurityScope {
                didStartAccessing = url.startAccessingSecurityScopedResource()
                if didStartAccessing {
                    print("🔐 Started accessing security-scoped resource")
                } else {
                    print("⚠️ Security-scoped access not available (may not be needed)")
                }
            } else {
                print("ℹ️ File is in temp/inbox, no security scoping needed")
            }
            
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                    print("🔓 Stopped accessing security-scoped resource")
                }
            }
            
            // 读取文件数据
            guard let data = try? Data(contentsOf: url) else {
                print("❌ Failed to read file data: \(filename)")
                failCount += 1
                continue
            }
            
            let fileExtension = url.pathExtension.lowercased()
            
            // 使用不带扩展名的文件名作为标题
            let fileNameWithoutExt = url.deletingPathExtension().lastPathComponent
            let displayTitle = fileNameWithoutExt.isEmpty ? filename : fileNameWithoutExt
            
            var metadata: [String: String] = [
                "source": "app_picker",
                "filename": filename,
                "size": "\(data.count)",
                "extension": fileExtension
            ]
            
            // 检查是否有配置的处理规则
            let settingsManager = FileHandlerSettingsManager.shared
            if let rule = settingsManager.getRule(for: fileExtension) {
                print("🌐 Found handler rule for .\(fileExtension): [\(rule.typeName)] \(rule.remoteURL)")
                
                // 发送到远程服务器处理
                Task {
                    await sendToRemoteHandler(
                        rule: rule,
                        filename: filename,
                        fileData: data,
                        fileExtension: fileExtension
                    )
                }
                
                // 添加处理标记到元数据
                metadata["handler_url"] = rule.remoteURL
                metadata["handler_type"] = rule.typeName
                metadata["handler_status"] = "pending"
            }
            
            var item: SharedItemModel?
            
            switch fileExtension {
            case "pdf":
                item = SharedItemModel.createPDFItem(
                    title: displayTitle,
                    pdfData: data,
                    metadata: metadata
                )
            case "xlsx", "xls":
                item = SharedItemModel.createExcelItem(
                    title: displayTitle,
                    excelData: data,
                    metadata: metadata
                )
            case "mp4", "mov":
                item = SharedItemModel.createVideoItem(
                    title: displayTitle,
                    videoData: data,
                    metadata: metadata
                )
            case "jpg", "jpeg", "png":
                if let image = UIImage(data: data) {
                    item = SharedItemModel.createPhotoItem(
                        title: displayTitle,
                        imageData: data,
                        metadata: metadata
                    )
                }
            default:
                // 其他类型保存为通用文件
                let fileManager = SharedStorageManager.shared
                if let filePath = fileManager.saveFile(data: data, filename: filename) {
                    item = SharedItemModel(
                        title: displayTitle,
                        contentType: "file",
                        filePath: filePath,
                        textContent: nil,
                        metadata: metadata
                    )
                }
            }
            
            if let item = item {
                SharedStorageManager.shared.saveItem(item)
                print("✅ Saved document: \(filename) (\(data.count) bytes)")
                successCount += 1
            } else {
                print("❌ Failed to create item for: \(filename)")
                failCount += 1
            }
        }
        
        print("📊 Summary: \(successCount) succeeded, \(failCount) failed")
        
        // 刷新界面
        withAnimation {
            manager.refresh()
        }
    }
    
    // 发送文件到远程处理器
    private func sendToRemoteHandler(rule: FileHandlerRule, filename: String, fileData: Data, fileExtension: String) async {
        print("🚀 Sending \(filename) to remote handler: [\(rule.typeName)] \(rule.remoteURL)")
        
        guard let requestURL = URL(string: rule.remoteURL) else {
            print("❌ Invalid handler URL: \(rule.remoteURL)")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        
        // 创建 multipart/form-data 请求
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加文件数据（使用规则中的文件参数名）
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(rule.fileParameterName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 添加扩展名参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"extension\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(fileExtension)\r\n".data(using: .utf8)!)
        
        // 添加自定义参数
        for (key, value) in rule.customParameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
            print("📤 Custom parameter: \(key) = \(value)")
        }
        
        // 结束标记
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Successfully sent \(filename) to remote handler")
                    print("📥 Response: \(String(data: data, encoding: .utf8) ?? "No response body")")
                } else {
                    print("⚠️ Remote handler returned status code: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Failed to send to remote handler: \(error.localizedDescription)")
        }
    }
    
    // 发送 URL 到远程处理器（不上传文件）
    private func sendURLToRemoteHandler(rule: FileHandlerRule, urlString: String) async {
        print("🚀 Sending URL to remote handler: [\(rule.typeName)] \(rule.remoteURL)")
        print("🔗 URL to process: \(urlString)")
        
        guard let requestURL = URL(string: rule.remoteURL) else {
            print("❌ Invalid handler URL: \(rule.remoteURL)")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        
        // 创建 application/x-www-form-urlencoded 请求
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var parameters: [String] = []
        
        // 添加 URL 参数
        if let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            parameters.append("url=\(encodedURL)")
        }
        
        // 添加自定义参数
        for (key, value) in rule.customParameters {
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                parameters.append("\(encodedKey)=\(encodedValue)")
                print("📤 Custom parameter: \(key) = \(value)")
            }
        }
        
        let bodyString = parameters.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Successfully sent URL to remote handler")
                    print("📥 Response: \(String(data: data, encoding: .utf8) ?? "No response body")")
                } else {
                    print("⚠️ Remote handler returned status code: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Failed to send to remote handler: \(error.localizedDescription)")
        }
    }
}

/// 详情视图
struct ItemDetailView: View {
    let item: SharedItem
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = SharedItemsManager.shared
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    @State private var showingShareSheet = false
    
    init(item: SharedItem) {
        self.item = item
        _editedTitle = State(initialValue: item.title)
        _editedContent = State(initialValue: item.content)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 类型和时间
                    HStack {
                        Label(item.contentType.rawValue, systemImage: item.contentType.icon)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(item.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // 标题
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("标题")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        
                            Spacer()
                            
                            if isEditing {
                                Button("保存") {
                                    saveChanges()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .disabled(!isContentValid)
                            }
                        }
                        
                        if isEditing {
                            TextField("标题", text: $editedTitle)
                                .font(.title3.weight(.semibold))
                                .textFieldStyle(.roundedBorder)
                                .focused($isTitleFocused)
                        } else {
                            Text(item.title)
                                .font(.title3.weight(.semibold))
                        }
                    }
                    
                    Divider()
                    
                    // 内容区域
                    if hasFile {
                        // 文件类型：显示文件卡片
                        fileContentView
                    } else {
                        // 文本/URL类型：显示文本内容（支持编辑）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("内容")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if isEditing {
                                TextEditor(text: $editedContent)
                                    .font(.body)
                                    .frame(minHeight: 200)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .focused($isContentFocused)
                            } else {
                                Text(item.content)
                                    .font(.body)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("取消") {
                            cancelEditing()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("完成") {
                            if saveChanges() {
                                dismiss()
                            }
                        }
                        .font(.body.weight(.semibold))
                        .disabled(!isContentValid)
                    } else {
                        HStack(spacing: 16) {
                            // 只有文本类型才显示编辑按钮
                            if !hasFile {
                                Button(action: {
                                    startEditing()
                                }) {
                                    Image(systemName: "pencil")
                                }
                            }
                            
                            Button("完成") {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = fileURL {
                    ShareSheet(items: [fileURL])
                }
            }
        }
    }
    
    // 判断是否有文件
    private var hasFile: Bool {
        // 只对真正的文件类型返回 true，排除纯文本和URL
        let fileTypes: [SharedContentType] = [.image, .pdf, .document, .video]
        return fileTypes.contains(item.contentType) && fileURL != nil
    }
    
    // 获取文件URL
    private var fileURL: URL? {
        // 通过SharedStorageManager获取文件
        let storage = SharedStorageManager.shared
        let items = storage.loadItems()
        
        guard let storedItem = items.first(where: { $0.id == item.id.uuidString }),
              let filePath = storedItem.filePath else {
            return nil
        }
        
        return storage.getFileURL(relativePath: filePath)
    }
    
    // 文件信息
    private var fileInfo: (size: String, name: String)? {
        guard let url = fileURL else { return nil }
        
        let fileName = url.lastPathComponent
        let fileSize: String
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        } else {
            fileSize = "未知大小"
        }
        
        return (size: fileSize, name: fileName)
    }
    
    // 文件内容视图
    private var fileContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("文件")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 图片预览（如果是图片类型）
            if item.contentType == .image, let url = fileURL, let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            }
            
            // 文件信息卡片
            VStack(spacing: 0) {
                // 文件图标和信息
                HStack(spacing: 16) {
                    // 文件类型图标
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: item.contentType.icon)
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    
                    // 文件详细信息
                    VStack(alignment: .leading, spacing: 4) {
                        if let info = fileInfo {
                            Text(info.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            Text(info.size)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(item.contentType.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                
                // 操作按钮
                Divider()
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享或打开")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .foregroundColor(.blue)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // 验证内容是否有效
    private var isContentValid: Bool {
        if hasFile {
            // 文件类型只需要标题不为空
            return !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            // 文本类型需要内容不为空
            return !editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func startEditing() {
        isEditing = true
        editedTitle = item.title
        editedContent = item.content
        // 自动聚焦到内容输入框（如果不是文件类型）
        if !hasFile {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isContentFocused = true
            }
        } else {
            isTitleFocused = true
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        editedTitle = item.title
        editedContent = item.content
        isTitleFocused = false
        isContentFocused = false
    }
    
    @discardableResult
    private func saveChanges() -> Bool {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespaces)
        let trimmedContent = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if hasFile {
            // 文件类型只保存标题
            guard !trimmedTitle.isEmpty else {
                return false
            }
            
            if trimmedTitle == item.title {
                isEditing = false
                isTitleFocused = false
                return true
            }
            
            SharedStorageManager.shared.updateItemTitle(id: item.id.uuidString, newTitle: trimmedTitle)
        } else {
            // 文本类型保存标题和内容
            guard !trimmedContent.isEmpty else {
                return false
            }
            
            // 如果标题和内容都没有变化，直接退出编辑
            if trimmedTitle == item.title && trimmedContent == item.content {
                isEditing = false
                isTitleFocused = false
                isContentFocused = false
                return true
            }
            
            // 如果标题为空，使用内容的前30个字符作为标题
            let finalTitle = trimmedTitle.isEmpty ? String(trimmedContent.prefix(30)) : trimmedTitle
            SharedStorageManager.shared.updateItemContent(id: item.id.uuidString, newTitle: finalTitle, newContent: trimmedContent)
        }
        
        // 刷新界面
        manager.refresh()
        
        isEditing = false
        isTitleFocused = false
        isContentFocused = false
        
        print("✅ Updated item: \(trimmedTitle)")
        return true
    }
}

/// 文本输入视图
struct TextInputView: View {
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @FocusState private var contentFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("输入标题（可选）", text: $title)
                            .font(.title3.weight(.semibold))
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Divider()
                    
                    // 内容输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .font(.body)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($contentFocused)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("添加文本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(title, content)
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // 视图出现时自动聚焦到内容输入框
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    contentFocused = true
                }
            }
        }
    }
}

/// 分享面板（UIActivityViewController 包装）
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 不需要更新
    }
}

#Preview {
    MainView()
}
