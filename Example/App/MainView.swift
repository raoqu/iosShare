import SwiftUI

/// TransAny 主界面
struct MainView: View {
    @StateObject private var manager = SharedItemsManager.shared
    @State private var showingDeleteAlert = false
    @State private var selectedItem: SharedItem?
    
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
                }
            }
            .navigationTitle("TransAny")
            .navigationBarTitleDisplayMode(.large)
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("清空所有", systemImage: "trash")
                        }
                        .disabled(manager.items.isEmpty)
                        
                        Button(action: {
                            // 添加测试数据
                            addTestItem()
                        }) {
                            Label("添加测试", systemImage: "plus.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
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
