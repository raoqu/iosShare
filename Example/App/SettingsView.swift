import SwiftUI

/// 设置视图
struct SettingsView: View {
    @StateObject private var settingsManager = FileHandlerSettingsManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAddRule = false
    @State private var editingRule: FileHandlerRule?
    
    var body: some View {
        NavigationView {
            List {
                // 文件处理规则部分
                Section {
                    ForEach(settingsManager.rules) { rule in
                        FileHandlerRuleRow(rule: rule) {
                            editingRule = rule
                        }
                    }
                    .onDelete(perform: settingsManager.deleteRule(at:))
                    
                    Button(action: {
                        showingAddRule = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("添加规则")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("文件处理规则")
                } footer: {
                    Text("为不同的文件扩展名配置远程处理 URL。启用后，该类型的文件将发送到指定的远程服务器处理。")
                        .font(.caption)
                }
                
                // 操作部分
                Section {
                    Button(role: .destructive, action: {
                        settingsManager.resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置为默认设置")
                        }
                    }
                } header: {
                    Text("操作")
                }
                
                // 关于部分
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("规则数量")
                        Spacer()
                        Text("\(settingsManager.rules.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddRule) {
                FileHandlerRuleEditView(rule: nil) { newRule in
                    settingsManager.addRule(newRule)
                }
            }
            .sheet(item: $editingRule) { rule in
                FileHandlerRuleEditView(rule: rule) { updatedRule in
                    settingsManager.updateRule(updatedRule)
                }
            }
        }
    }
}

/// 文件处理规则行
struct FileHandlerRuleRow: View {
    let rule: FileHandlerRule
    let onEdit: () -> Void
    @StateObject private var settingsManager = FileHandlerSettingsManager.shared
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // 类型图标
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(rule.isEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(String(rule.typeName.prefix(3)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(rule.isEnabled ? .blue : .gray)
                }
                
                // 规则信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(rule.typeName)
                            .font(.headline)
                            .foregroundColor(rule.isEnabled ? .primary : .secondary)
                        
                        // 显示规则类型徽章
                        Text(rule.ruleType == .url ? "URL" : "文件")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(rule.ruleType == .url ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                            .foregroundColor(rule.ruleType == .url ? .orange : .blue)
                            .cornerRadius(4)
                    }
                    
                    if rule.ruleType == .file && !rule.fileExtensions.isEmpty {
                        Text(rule.fileExtensions.map { ".\($0)" }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if rule.ruleType == .url {
                        Text("适用于所有 URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(rule.remoteURL)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                // 启用开关
                Toggle("", isOn: Binding(
                    get: { rule.isEnabled },
                    set: { newValue in
                        var updatedRule = rule
                        updatedRule.isEnabled = newValue
                        settingsManager.updateRule(updatedRule)
                    }
                ))
                .labelsHidden()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 文件处理规则编辑视图
struct FileHandlerRuleEditView: View {
    let rule: FileHandlerRule?
    let onSave: (FileHandlerRule) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var typeName: String
    @State private var ruleType: HandlerRuleType
    @State private var extensionsText: String  // 逗号分隔的扩展名
    @State private var remoteURL: String
    @State private var fileParameterName: String
    @State private var customParameters: [(key: String, value: String)]
    @State private var isEnabled: Bool
    
    @State private var showingAddParameter = false
    @State private var newParamKey = ""
    @State private var newParamValue = ""
    
    init(rule: FileHandlerRule?, onSave: @escaping (FileHandlerRule) -> Void) {
        self.rule = rule
        self.onSave = onSave
        
        _typeName = State(initialValue: rule?.typeName ?? "")
        _ruleType = State(initialValue: rule?.ruleType ?? .file)
        _extensionsText = State(initialValue: rule?.fileExtensions.joined(separator: ",") ?? "")
        _remoteURL = State(initialValue: rule?.remoteURL ?? "")
        _fileParameterName = State(initialValue: rule?.fileParameterName ?? "file")
        _customParameters = State(initialValue: rule?.customParameters.map { (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key } ?? [])
        _isEnabled = State(initialValue: rule?.isEnabled ?? true)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 类型
                Section {
                    TextField("类型名称", text: $typeName)
                        .autocapitalization(.allCharacters)
                    
                    Picker("规则类型", selection: $ruleType) {
                        Text("文件上传").tag(HandlerRuleType.file)
                        Text("URL 处理").tag(HandlerRuleType.url)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("类型")
                } footer: {
                    if ruleType == .file {
                        Text("文件上传：根据文件扩展名处理，上传文件到远程服务器")
                    } else {
                        Text("URL 处理：处理所有 URL 类型内容，只发送 URL 字符串，不上传文件")
                    }
                }
                
                // 扩展名（仅文件类型）
                if ruleType == .file {
                    Section {
                        TextField("扩展名", text: $extensionsText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: extensionsText) { newValue in
                                // 自动移除点号和空格，转小写
                                extensionsText = newValue
                                    .replacingOccurrences(of: ".", with: "")
                                    .replacingOccurrences(of: " ", with: "")
                                    .lowercased()
                            }
                    } header: {
                        Text("扩展名")
                    } footer: {
                        Text("逗号分隔，不包含点号。例如：xls,xlsx")
                    }
                }
                
                // 处理 URL
                Section {
                    TextField("远程 URL", text: $remoteURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                } header: {
                    Text("处理 URL")
                } footer: {
                    Text("输入完整的远程处理 URL，包括协议（http:// 或 https://）")
                }
                
                // 参数配置
                Section {
                    // 文件参数名（仅文件类型）
                    if ruleType == .file {
                        HStack {
                            Text("文件参数名")
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("参数名", text: $fileParameterName)
                                .multilineTextAlignment(.trailing)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                    
                    // 自定义参数列表
                    ForEach(customParameters.indices, id: \.self) { index in
                        HStack {
                            TextField("Key", text: Binding(
                                get: { customParameters[index].key },
                                set: { customParameters[index].key = $0 }
                            ))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            
                            Text(":")
                                .foregroundColor(.secondary)
                            
                            TextField("Value", text: Binding(
                                get: { customParameters[index].value },
                                set: { customParameters[index].value = $0 }
                            ))
                            .autocapitalization(.none)
                            
                            Button(action: {
                                customParameters.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // 添加参数按钮
                    Button(action: {
                        showingAddParameter = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("添加参数")
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("参数")
                } footer: {
                    if ruleType == .file {
                        Text("文件参数名用于上传文件，自定义参数会一同发送到服务器")
                    } else {
                        Text("自定义参数会随 URL 一起发送到服务器")
                    }
                }
                
                // 启用规则
                Section {
                    Toggle("启用此规则", isOn: $isEnabled)
                } footer: {
                    Text("禁用后，该扩展名的文件将不会发送到远程服务器")
                }
            }
            .navigationTitle(rule == nil ? "添加规则" : "编辑规则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRule()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("添加参数", isPresented: $showingAddParameter) {
                TextField("Key", text: $newParamKey)
                TextField("Value", text: $newParamValue)
                Button("取消", role: .cancel) {
                    newParamKey = ""
                    newParamValue = ""
                }
                Button("添加") {
                    if !newParamKey.isEmpty {
                        customParameters.append((key: newParamKey, value: newParamValue))
                        newParamKey = ""
                        newParamValue = ""
                    }
                }
            }
        }
    }
    
    private var isValid: Bool {
        if ruleType == .file {
            return !typeName.isEmpty && !extensionsText.isEmpty && !remoteURL.isEmpty && remoteURL.hasPrefix("http")
        } else {
            return !typeName.isEmpty && !remoteURL.isEmpty && remoteURL.hasPrefix("http")
        }
    }
    
    private func saveRule() {
        // 解析扩展名（仅文件类型）
        let extensions: [String]
        if ruleType == .file {
            extensions = extensionsText
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        } else {
            extensions = []
        }
        
        // 转换参数为字典
        let params = Dictionary(uniqueKeysWithValues: customParameters.map { ($0.key, $0.value) })
        
        let newRule = FileHandlerRule(
            id: rule?.id ?? UUID(),
            typeName: typeName,
            ruleType: ruleType,
            fileExtensions: extensions,
            remoteURL: remoteURL,
            fileParameterName: ruleType == .file ? fileParameterName : "",
            customParameters: params,
            isEnabled: isEnabled
        )
        onSave(newRule)
        dismiss()
    }
}

#Preview {
    SettingsView()
}
