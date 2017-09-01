import UIKit
import SandboxBrowser

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.4) {
            self.enableSwipe()
        }
        return true
    }
    
    public func enableSwipe() {
        let pan = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDetected))
        pan.numberOfTouchesRequired = 1
        pan.direction = .left
        UIApplication.shared.keyWindow?.addGestureRecognizer(pan)
    }
    
    func onSwipeDetected(){
        let vc = SandboxBrowser()
        vc.didSelectFile = { file, vc in
            if file.type == .sqlite {
                let tablesVC = TablesViewController()
                tablesVC.url = URL(fileURLWithPath: file.path)
                vc.navigationController?.pushViewController(tablesVC, animated: true)
            }
        }
        window?.rootViewController?.present(vc, animated: true, completion: nil)
    }
    

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let tablesVC = TablesViewController()
        tablesVC.url = url
        window?.rootViewController = UINavigationController(rootViewController: tablesVC)
        return true
    }
}
