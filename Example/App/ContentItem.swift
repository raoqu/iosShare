import Foundation
import UIKit

/// Content item type enumeration
enum ContentItemType {
    case image
    case pdf
    case excel
    case word
    case url
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.text.fill"
        case .excel: return "tablecells"
        case .word: return "doc.text"
        case .url: return "link"
        }
    }
    
    var color: UIColor {
        switch self {
        case .image: return .systemBlue
        case .pdf: return .systemRed
        case .excel: return .systemGreen
        case .word: return .systemIndigo
        case .url: return .systemOrange
        }
    }
    
    var typeIdentifier: String {
        switch self {
        case .image: return "public.image"
        case .pdf: return "com.adobe.pdf"
        case .excel: return "org.openxmlformats.spreadsheetml.sheet"
        case .word: return "org.openxmlformats.wordprocessingml.document"
        case .url: return "public.url"
        }
    }
}

/// Content item model
struct ContentItem {
    let type: ContentItemType
    let title: String
    let subtitle: String
    let content: Any
    
    init(type: ContentItemType, title: String, subtitle: String, content: Any) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }
}
