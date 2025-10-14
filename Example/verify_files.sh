#!/bin/bash

echo "🔍 验证文件状态..."
echo ""

# 检查文件是否存在
echo "📋 检查文件存在性："
for file in "App/PhotoPickerView.swift" "App/DocumentPickerView.swift"; do
    if [ -f "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 不存在"
    fi
done
echo ""

# 检查文件内容
echo "📄 检查文件内容："
if [ -f "App/PhotoPickerView.swift" ]; then
    lines=$(wc -l < "App/PhotoPickerView.swift")
    echo "✅ PhotoPickerView.swift: $lines 行"
else
    echo "❌ PhotoPickerView.swift 缺失"
fi

if [ -f "App/DocumentPickerView.swift" ]; then
    lines=$(wc -l < "App/DocumentPickerView.swift")
    echo "✅ DocumentPickerView.swift: $lines 行"
else
    echo "❌ DocumentPickerView.swift 缺失"
fi
echo ""

# 检查 Xcode 项目配置
echo "🔧 检查 Xcode 项目配置："
if [ -f "XExtensionItemExample.xcodeproj/project.pbxproj" ]; then
    if grep -q "PhotoPickerView.swift" "XExtensionItemExample.xcodeproj/project.pbxproj"; then
        echo "✅ PhotoPickerView.swift 在项目配置中"
    else
        echo "⚠️  PhotoPickerView.swift 未添加到项目"
        echo "   → 需要在 Xcode 中添加到 App target"
    fi
    
    if grep -q "DocumentPickerView.swift" "XExtensionItemExample.xcodeproj/project.pbxproj"; then
        echo "✅ DocumentPickerView.swift 在项目配置中"
    else
        echo "⚠️  DocumentPickerView.swift 未添加到项目"
        echo "   → 需要在 Xcode 中添加到 App target"
    fi
else
    echo "❌ 找不到 Xcode 项目文件"
fi
echo ""

# 提供修复建议
echo "💡 修复步骤："
echo "1. 在 Xcode 中右键点击 App 文件夹"
echo "2. 选择 'Add Files to...'"
echo "3. 选中 PhotoPickerView.swift 和 DocumentPickerView.swift"
echo "4. 确保勾选 App target"
echo "5. 点击 Add"
echo ""
echo "或查看详细指南: FIX_PICKER_VIEWS.md"
