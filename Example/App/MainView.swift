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
    @State private var inputText = ""
    
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
            // 文本输入对话框
            .alert("输入文本", isPresented: $showingTextInput) {
                TextField("请输入内容", text: $inputText)
                Button("取消", role: .cancel) {
                    inputText = ""
                }
                Button("保存") {
                    saveText(inputText)
                    inputText = ""
                }
            } message: {
                Text("输入要保存的文本内容")
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
    private func saveText(_ text: String) {
        guard !text.isEmpty else { return }
        
        let item = SharedItemModel.createTextItem(
            title: String(text.prefix(30)),
            text: text,
            metadata: ["source": "app_input", "length": "\(text.count)"]
        )
        
        SharedStorageManager.shared.saveItem(item)
        
        withAnimation {
            manager.refresh()
        }
        
        print("✅ Saved text: \(text.prefix(50))...")
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
                    title: filename,
                    pdfData: data,
                    metadata: metadata
                )
            case "xlsx", "xls":
                item = SharedItemModel.createExcelItem(
                    title: filename,
                    excelData: data,
                    metadata: metadata
                )
            case "mp4", "mov":
                item = SharedItemModel.createVideoItem(
                    title: filename,
                    videoData: data,
                    metadata: metadata
                )
            case "jpg", "jpeg", "png":
                if let image = UIImage(data: data) {
                    item = SharedItemModel.createPhotoItem(
                        title: filename,
                        imageData: data,
                        metadata: metadata
                    )
                }
            default:
                // 其他类型保存为通用文件
                let fileManager = SharedStorageManager.shared
                if let filePath = fileManager.saveFile(data: data, filename: filename) {
                    item = SharedItemModel(
                        title: filename,
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
}

/// 详情视图
struct ItemDetailView: View {
    let item: SharedItem
    @Environment(\.dismiss) var dismiss
    
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
                        Text("标题")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    // 内容
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.content)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}
