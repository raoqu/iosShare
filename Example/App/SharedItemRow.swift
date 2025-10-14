import SwiftUI

/// 分享内容列表行视图
struct SharedItemRow: View {
    let item: SharedItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: item.contentType.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(item.content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(item.contentType.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(iconColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(iconColor.opacity(0.15))
                        .cornerRadius(4)
                    
                    Text(item.formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
    
    private var iconColor: Color {
        switch item.contentType.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "pink": return .pink
        default: return .gray
        }
    }
}

#Preview {
    List {
        SharedItemRow(item: SharedItem(
            title: "Apple iPad Air 2",
            contentType: .url,
            content: "http://apple.com/ipad-air-2/"
        ))
        
        SharedItemRow(item: SharedItem(
            title: "示例图片",
            contentType: .image,
            content: "image.jpg"
        ))
        
        SharedItemRow(item: SharedItem(
            title: "文档文件.pdf",
            contentType: .pdf,
            content: "document.pdf"
        ))
    }
}
