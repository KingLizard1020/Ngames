import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    // Use the rootViewController from the AppDelegate's window
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
       let rootVC = appDelegate.window?.rootViewController {
      window.rootViewController = rootVC
    }
    self.window = window
    window.makeKeyAndVisible()
  }
}
