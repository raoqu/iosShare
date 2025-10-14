import SwiftUI
import UIKit

/// SceneDelegate 帮助类 - 桥接 SwiftUI 到 Objective-C
@objc class SceneDelegateHelper: NSObject {
    
    /// 创建 SwiftUI 主视图的 UIViewController
    @objc static func createMainViewController() -> UIViewController {
        let mainView = MainView()
        let hostingController = UIHostingController(rootView: mainView)
        return hostingController
    }
}
