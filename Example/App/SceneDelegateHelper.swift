import SwiftUI
import UIKit

/// SceneDelegate 帮助类 - 桥接 SwiftUI 到 Objective-C
@objc class SceneDelegateHelper: NSObject {
    
    /// 创建 SwiftUI 主视图的 UIViewController
    @objc static func createMainViewController() -> UIViewController {
        let mainView = MainView()
        let hostingController = UIHostingController(rootView: mainView)
        
        // 设置背景色为白色，避免黑色边框
        hostingController.view.backgroundColor = .white
        
        // 禁用安全区域插入，让 SwiftUI 视图完全控制布局
        hostingController.additionalSafeAreaInsets = .zero
        
        return hostingController
    }
}
